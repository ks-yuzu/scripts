#!/usr/bin/env bash
# set -euo pipefail


for i in $(find `pwd` -type f); do
    ln -s $i ~/bin
done
