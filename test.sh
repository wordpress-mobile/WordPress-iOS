#!/bin/sh

set -e

xctool build
xctool run-tests -freshInstall -simulator iphone
xctool run-tests -freshInstall -simulator ipad