#!/bin/sh

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy.txt
touch "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "rsync -rp ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -rp "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource 'SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle'
<<<<<<< HEAD
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_disabled.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_disabled@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_normal.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_normal@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_pressed.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_button_pressed@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_disabled.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_disabled@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_normal.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_normal@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_pressed.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_dark_icon_pressed@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_disabled.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_disabled@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_normal.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_normal@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_pressed.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_button_pressed@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_disabled.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_disabled@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_normal.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_normal@2x.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_pressed.png'
install_resource 'google-plus-ios-sdk/google-plus-ios-sdk-1.2.1/Resources/gpp_sign_in_light_icon_pressed@2x.png'
=======
>>>>>>> reader

rsync -avr --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rm "$RESOURCES_TO_COPY"
