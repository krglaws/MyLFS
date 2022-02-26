#!/usr/bin/bash
set -e

source ./config.sh

echo "Starting Stage 1..."
stage1/main.sh
echo "Completed Stage 1."

mkdir -p $LFS/sources

echo "Starting Stage 2..."
stage2/main.sh
echo "Completed Stage 2."

