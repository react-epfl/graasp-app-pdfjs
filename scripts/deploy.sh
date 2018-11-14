#!/bin/bash

# fail the build on any failed command
set -e

usage() {
  echo "usage: $0 [-e <path/to/file>] [-v <version string>] [-p] [-b <path/to/build>]" 1>&2
  exit 1
}

# default build directory
BUILD="build/"

# default version
VERSION="latest"

# validates versioning e.g. v0.1.0
validate_version() {
  # regex matching version numbers
  rx='^v([0-9]+\.){0,2}(\*|[0-9]+)$'
  if [[ $1 =~ $rx ]]; then
    echo "info: validated version $1"
    VERSION=$1
  else
    echo "error: unable to validate version '$1'" 1>&2
    echo "format is '${rx}'"
    exit 1
  fi
}


# validates that build directory exists
validate_build() {
  if [ -d $1 ]; then
    echo "info: validated build directory $1"
    BUILD=$1
  else
    echo "error: build directory '$1' does not exist" 1>&2
    exit 1
  fi
}

# validates that environment file exists
validate_env() {
  if [ -f $1 ]; then
    echo "info: validated environment file $1"
    source ${1}
  else
    echo "error: environment file '$1' does not exist" 1>&2
    exit 1
  fi
}

# parse command line arguments
while getopts "e:v:b:" opt; do
  case ${opt} in
    e)
      e=${OPTARG}
      validate_env ${e}
      ;;
    b)
      b=${OPTARG}
      validate_build ${b}
      ;;
    v)
      v=${OPTARG}
      validate_version ${v}
      ;;
    \?)
      echo "error: invalid option '-$OPTARG'" 1>&2
      exit 1
      ;;
  esac
done

# ensure the correct variables are defined
if \
  [ -z "${GRAASP_DEVELOPER_ID}" ] || \
  [ -z "${GRAASP_APP_ID}" ]; then
  echo "error: environment variables GRAASP_APP_ID and/or GRAASP_DEVELOPER_ID are not defined" 1>&2
  echo "error: you can specify them through a file specified with the -e flag" 1>&2
  exit 1
fi

# ensure the correct aws credentials are defined
if \
  [ -z "${BUCKET}" ] || \
  [ -z "${AWS_ACCESS_KEY_ID}" ] || \
  [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "error: environment variables BUCKET, AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY are not defined" 1>&2
  echo "error: make sure you setup your credentials file correctly using the scripts/setup.sh script" 1>&2
  echo "error: and contact your favourite Graasp engineer if you keep running into trouble" 1>&2
  exit 1
fi

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

echo "info: publishing app ${GRAASP_APP_ID} version ${VERSION}"

APP_DIR=${BUCKET}/${GRAASP_DEVELOPER_ID}/${GRAASP_APP_ID}/${VERSION}/

# make sure you do not use the word PATH as a variable because it overrides the PATH environment variable
APP_PATH=${GRAASP_DEVELOPER_ID}/${GRAASP_APP_ID}/${VERSION}

# sync s3 bucket
aws s3 sync ${BUILD} s3://${APP_DIR} --delete

# ensure the correct distribution variables are defined
if \
  [ -z "${DISTRIBUTION}" ]; then
  echo "error: environment variable DISTRIBUTION is not defined" 1>&2
  echo "error: contact your favourite Graasp engineer if you keep running into trouble" 1>&2
  exit 1
fi

# invalidate cloudfront distribution
aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION} --paths /${APP_PATH}/*
