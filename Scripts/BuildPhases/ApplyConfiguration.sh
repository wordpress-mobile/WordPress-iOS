#!/bin/sh

# The Secrets File Sources
PRODUCTION_SECRETS_FILE="${PROJECT_ROOT}/.configure-files/Secrets.swift"
INTERNAL_SECRETS_FILE="${PROJECT_ROOT}/.configure-files/Secrets-Internal.swift"
ALPHA_SECRETS_FILE="${PROJECT_ROOT}/.configure-files/Secrets-Alpha.swift"
LOCAL_SECRETS_FILE="${SRCROOT}/Credentials/Secrets.swift"
EXAMPLE_SECRETS_FILE="${SRCROOT}/Credentials/Secrets-example.swift"

# The Secrets file destination
SECRETS_DESTINATION_FILE="${CONFIGURATION_BUILD_DIR}/Secrets.swift"

# If the WordPress Production Secrets are available for WordPress, use them
if [ -f "$PRODUCTION_SECRETS_FILE" ] && [ "$BUILD_SCHEME" == "WordPress" ]; then
    echo "Applying Production Secrets"
    cp -v $PRODUCTION_SECRETS_FILE $SECRETS_DESTINATION_FILE
    exit 0
fi

# If the WordPress Internal Secrets are available, use them
if [ -f "$INTERNAL_SECRETS_FILE" ] && [ "${BUILD_SCHEME}" == "WordPress Internal" ]; then
    echo "Applying Internal Secrets"
    cp -v $INTERNAL_SECRETS_FILE $SECRETS_DESTINATION_FILE
    exit 0
fi

# If the WordPress Alpha Secrets are available, use them
if [ -f "$INTERNAL_SECRETS_FILE" ] && [ "${BUILD_SCHEME}" == "WordPress Alpha" ]; then
    echo "Applying Alpha Secrets"
    cp -v $ALPHA_SECRETS_FILE $SECRETS_DESTINATION_FILE
    exit 0
fi

# If the developer has a local secrets file, use it
if [ -f "$LOCAL_SECRETS_FILE" ]; then
    echo "Applying Local Secrets"
    cp -v $LOCAL_SECRETS_FILE $SECRETS_DESTINATION_FILE
    exit 0
fi

# Use the example secrets file as a last resort
echo "Applying Example Secrets"
cp -v $EXAMPLE_SECRETS_FILE $SECRETS_DESTINATION_FILE
