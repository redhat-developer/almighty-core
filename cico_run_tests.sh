#!/bin/bash

# Output command before executing
set -x

# Exit on error
set -e

# Source environment variables of the jenkins slave
# that might interest this worker.
if [ -e "jenkins-env" ]; then
  cat jenkins-env \
    | grep -E "(JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId)=" \
    | sed 's/^/export /g' \
    > ~/.jenkins-env
  source ~/.jenkins-env
fi

# We need to disable selinux for now, XXX
/usr/sbin/setenforce 0

# Get all the deps in
yum -y install \
  docker \
  make \
  git \
  curl
service docker start

# Let's test
make docker-start
make docker-deps
make docker-generate
make docker-build
make docker-test-unit

make integration-test-env-prepare

function cleanup {
  make integration-test-env-tear-down
}
trap cleanup EXIT

make docker-test-migration
make docker-test-integration

# Output coverage
make docker-coverage-all

# Upload coverage to codecov.io
cp tmp/coverage.mode* coverage.txt
bash <(curl -s https://codecov.io/bash) -X search -f coverage.txt -t ad12dad7-ebdc-47bc-a016-8c05fa7356bc #-X fix
