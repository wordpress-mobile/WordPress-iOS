#!/bin/sh

if [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

bundle exec fastlane run configure_validate
