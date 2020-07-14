#!/usr/bin/env bash

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

declare -a YW_DIRS=(
    $BASE_DIR/../app/config/
    $BASE_DIR/../bin/
    $BASE_DIR/../var/
    $BASE_DIR/../web/pimcore/
    $BASE_DIR/../web/var/
    $BASE_DIR/../vendor/youwe/b2b-generic-import-flow-bundle/bin/process-incoming-import-data.sh
    $BASE_DIR/../vendor/youwe/b2b-generic-import-flow-bundle/bin/process-queued-import-data.sh

)
for YW_DIR in "${YW_DIRS[@]}"; do
  [ ! -f "$YW_DIR" ] && mkdir -p "$YW_DIR"
  chmod -Rv 777 "$YW_DIR"
done
