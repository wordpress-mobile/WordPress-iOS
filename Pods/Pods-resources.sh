#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcassets)
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked.imageset/CTAssetsPickerChecked.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerChecked.imageset/CTAssetsPickerChecked@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerEmpty.imageset/CTAssetsPickerEmpty.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerEmpty.imageset/CTAssetsPickerEmpty@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerLocked.imageset/CTAssetsPickerLocked.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerLocked.imageset/CTAssetsPickerLocked@2x.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerVideo.imageset/CTAssetsPickerVideo.png"
install_resource "CTAssetsPickerController/CTAssetsPickerController/Images.xcassets/CTAssetsPickerVideo.imageset/CTAssetsPickerVideo@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-background-tile.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-background-tile@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-camera-button.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-camera-button@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-delete-button.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-delete-button@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-no-connection.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-no-connection@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-powered-by-logo.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-powered-by-logo@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-screenshot-error.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-screenshot-error@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-section-header.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HS-section-header@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSChatBubbleBlue.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSChatBubbleBlue@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSChatBubbleWhite.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSChatBubbleWhite@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSConfirmBox.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSConfirmBox@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSTutorial.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSTutorial@2x.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSTutorialiPad.png"
install_resource "Helpshift/helpshift-sdk-ios-v4.5.0/HSResources/HSTutorialiPad@2x.png"
install_resource "Mixpanel/Mixpanel/MPArrowLeft.png"
install_resource "Mixpanel/Mixpanel/MPArrowLeft@2x.png"
install_resource "Mixpanel/Mixpanel/MPArrowRight.png"
install_resource "Mixpanel/Mixpanel/MPArrowRight@2x.png"
install_resource "Mixpanel/Mixpanel/MPCheckmark.png"
install_resource "Mixpanel/Mixpanel/MPCheckmark@2x.png"
install_resource "Mixpanel/Mixpanel/MPCloseBtn.png"
install_resource "Mixpanel/Mixpanel/MPCloseBtn@2x.png"
install_resource "Mixpanel/Mixpanel/MPDismissKeyboard.png"
install_resource "Mixpanel/Mixpanel/MPDismissKeyboard@2x.png"
install_resource "Mixpanel/Mixpanel/MPLogo.png"
install_resource "Mixpanel/Mixpanel/MPLogo@2x.png"
install_resource "Mixpanel/Mixpanel/MPNotification.storyboard"
install_resource "Mixpanel/Mixpanel/MPSurvey.storyboard"
install_resource "SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-inspector-active.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-inspector-active@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-inspector.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-inspector@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-media-active.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-media-active@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-media.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-media@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-preview-active.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-preview-active@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-preview.png"
install_resource "WordPress-iOS-Editor/Assets/icon-posts-editor-preview@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_bold.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_bold@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_bold_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_bold_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_italic.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_italic@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_italic_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_italic_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_keyboard.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_keyboard@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_keyboard_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_keyboard_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_link.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_link@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_link_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_link_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_media.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_media@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_media_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_media_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_more.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_more@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_more_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_more_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_quote.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_quote@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_quote_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_quote_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_strikethrough.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_strikethrough@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_strikethrough_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_strikethrough_highlighted@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_underline.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_underline@2x.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_underline_highlighted.png"
install_resource "WordPress-iOS-Editor/Assets/icon_format_underline_highlighted@2x.png"
install_resource "google-plus-ios-sdk/google-plus-ios-sdk-1.5.1/GooglePlus.bundle"
install_resource "${BUILT_PRODUCTS_DIR}/HockeySDKResources.bundle"
install_resource "${BUILT_PRODUCTS_DIR}/WordPress-iOS-Shared.bundle"

rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ `xcrun --find actool` ] && [ `find . -name '*.xcassets' | wc -l` -ne 0 ]
then
  case "${TARGETED_DEVICE_FAMILY}" in 
    1,2)
      TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
      ;;
    1)
      TARGET_DEVICE_ARGS="--target-device iphone"
      ;;
    2)
      TARGET_DEVICE_ARGS="--target-device ipad"
      ;;
    *)
      TARGET_DEVICE_ARGS="--target-device mac"
      ;;  
  esac 
  find "${PWD}" -name "*.xcassets" -print0 | xargs -0 actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
