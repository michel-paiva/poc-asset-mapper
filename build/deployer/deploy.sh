#!/usr/bin/env bash

set -e # Exit immediately if a simple command exits with a nonzero exit value.
set -u # Makes Bash check whether you have initialised all your variables. If you haven't, Bash will throw an error about unbound variables.

YW_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source "$YW_BASE_DIR/_sharedFunctions.sh"

if [ ! ${1+x} ]; then
    echo Missing first parameter.
    echo The first parameter must be one of the following values: test, acceptance, production.
    exit 10
elif [[ "$1" != "test" && "$1" != "acceptance" && "$1" != "production" ]]; then
    echo The first parameter must be one of the following values: test, acceptance, production.
    exit 11
fi

YW_DEPLOY_ENV=$1

trap ___debug DEBUG

mkdir -p "./build-result"
tar -xvf build/artifacts/build_result.tar.gz -C "./build-result"

_installYouwePimcoreDeployer

php "$YW_DEPLOYER_DIR/vendor/deployer/deployer/bin/dep" -vv --file="$YW_DEPLOYER_DIR/vendor/youwe/deployer-pimcore/recipe/deploy.php" deploy $YW_DEPLOY_ENV
