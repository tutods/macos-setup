#!/bin/bash
DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/configs/hyper.js"

cp -f $SETTINGS_FILE ~/.hyper.js