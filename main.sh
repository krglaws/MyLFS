#!/usr/bin/env bash
# main.sh
# ~~~~~~~
# This is the main entry point for this project.
set -e

if [ "$UID" != "0" ]
then
    echo "ERROR: $0 must be run as root."
    exit -1
fi

cd $(dirname $0)

source ./config/global.sh

function build_stage {
    local STAGE_NO=$1

    echo "Starting stage $STAGE_NO... "

    { ./stage$STAGE_NO/main.sh && echo "Completed stage $STAGE_NO."; } ||
    { echo "Stage $STAGE_NO failed." && exit -1; }
}

for ((STAGE = 1; STAGE <= 6; STAGE++))
do
    build_stage $STAGE
done

