#!/bin/bash

# fail the build on any failed command
set -e

# if build has already been approved, skip tests
if [ ${CI_BUILD_APPROVED} ]; then
  echo ${CI_BUILD_APPROVED}
  echo "build already approved, skipping tests"
  exit 0
fi

# lint the codebase and run tests
yarn test
TEST_EXIT_CODE=$?

# todo: uncomment when coverage is setup
# report coverage
# yarn report

# return the exit code of the test command
exit ${TEST_EXIT_CODE}
