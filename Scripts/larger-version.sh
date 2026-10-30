#!/bin/bash
# Prints the larger of two build numbers.
# Usage: larger-version.sh <a> <b>
if [[ "$1" > "$2" ]]; then
  echo "$1"
else
  echo "$2"
fi
