#!/usr/bin/env bash

set -e # Exit immediately if a simple command exits with a nonzero exit value.
set -u # Makes Bash check whether you have initialised all your variables. If you haven't, Bash will throw an error about unbound variables.

YW_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source "$YW_BASE_DIR/_sharedFunctions.sh"

trap ___debug DEBUG

_installYouwePimcoreDeployer

mv "$YW_BASE_DIR/deployment.yml" "$YW_PROJECT_ROOT/app/config"
sed -i -r "s|imports:|imports:\n    - { resource: deployment.yml }|" "$YW_PROJECT_ROOT/app/config/config_prod.yml"
cp "$YW_PROJECT_ROOT/app/config/config_prod.yml" "$YW_PROJECT_ROOT/app/config/config_acceptance.yml"
cp "$YW_PROJECT_ROOT/app/config/config_prod.yml" "$YW_PROJECT_ROOT/app/config/config_testing.yml"

php "$YW_DEPLOYER_DIR/vendor/deployer/deployer/bin/dep" -vv --file="$YW_DEPLOYER_DIR/vendor/youwe/deployer-pimcore/recipe/build.php" build
