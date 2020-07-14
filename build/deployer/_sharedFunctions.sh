#!/usr/bin/env bash

set -e # Exit immediately if a simple command exits with a nonzero exit value.
set -u # Makes Bash check whether you have initialised all your variables. If you haven't, Bash will throw an error about unbound variables.

YW_BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export YW_PROJECT_ROOT=$(cd "${YW_BASE_DIR}/../.." && pwd)
export YW_BUILD_DIR=$YW_PROJECT_ROOT/build
export YW_DEPLOYER_DIR=$YW_BUILD_DIR/deployer

function ___debug() {
    echo "[DEBUG]: Executing line $BASH_LINENO: |$BASH_COMMAND|"
}

function _installYouwePimcoreDeployer() {
    composer install --working-dir "$YW_DEPLOYER_DIR"
}
