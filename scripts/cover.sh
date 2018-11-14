#!/bin/bash

# fail the build on any failed command
set -e

# lint the codebase and run tests
yarn test
TEST_EXIT_CODE=$?

# todo: uncomment when coverage is setup
# report coverage
# yarn report

# return the exit code of the test command
exit ${TEST_EXIT_CODE}
