#!/bin/sh

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
      echo "rsync -rp ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -rp "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xcdatamodeld`.momd"
      ;;
    *)
      echo "rsync -av --exclude '*/.svn/*' ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      rsync -av --exclude '*/.svn/*' "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      ;;
  esac
}
install_resource 'SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle'
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
