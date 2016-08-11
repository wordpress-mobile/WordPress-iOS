#!/usr/bin/env bash

echo "warning: Detected Prebuild Step"
cp ${BUDDYBUILD_SECURE_FILES}/wpcom_app_credentials ~/.wpcom_app_credentials
cp ${BUDDYBUILD_SECURE_FILES}/wpcom_internal_app_credentials ~/.wpcom_internal_app_credentials
cp ${BUDDYBUILD_SECURE_FILES}/wpcom_alpha_app_credentials ~/.wpcom_alpha_app_credentials
cp ${BUDDYBUILD_SECURE_FILES}/wpcom_test_credentials ~/.wpcom_test_credentials
echo "warning: Copied files over"
