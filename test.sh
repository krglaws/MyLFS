#!/usr/bin/bash
EXPECTED='[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]'
OUTPUT="     $EXPECTED  "

if [[ "$OUTPUT" == *"${EXPECTED}"* ]]
then
    echo all good
else
    echo shit
fi
