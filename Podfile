source 'https://github.com/CocoaPods/Specs.git'

project 'WordPress/WordPress.xcodeproj'
install! 'cocoapods',
         :deterministic_uuids => false

inhibit_all_warnings!
use_frameworks!

platform :ios, '9.0'

abstract_target 'WordPress_Base' do
  pod 'WordPress-iOS-Shared', '0.5.9'
  ## This pod is only being included to support the share extension ATM - https://github.com/wordpress-mobile/WordPress-iOS/issues/5081
  pod 'WordPressComKit', :git => 'https://github.com/Automattic/WordPressComKit.git', :tag => '0.0.1'

  target 'WordPress' do
    # ---------------------
    # Third party libraries
    # ---------------------
    pod '1PasswordExtension', '1.8.1'
    pod 'AFNetworking',	'2.6.3'
    pod 'AMPopTip', '~> 0.7'
    pod 'CocoaLumberjack', '~> 2.2.0'
    pod 'DTCoreText',   '1.6.16'
    pod 'FormatterKit', '~> 1.8.1'
    pod 'Helpshift', '~> 5.5.1'
    pod 'HockeySDK', '~> 3.8.0', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'Lookback', '1.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MRProgress', '~>0.7.0'
    pod 'Mixpanel', '2.9.4'
    pod 'Optimizely-iOS-SDK', '~> 1.4.2'
    pod 'Reachability',	'3.2'
    pod 'ReactiveCocoa', '~> 2.4.7'
    pod 'RxCocoa', '~> 2.5.0'
    pod 'RxSwift', '~> 2.5.0'
    pod 'SVProgressHUD', '~>1.1.3'
    pod 'UIDeviceIdentifier', '~> 0.1'
    pod 'Crashlytics'
    # ----------------------------
    # Forked third party libraries
    # ----------------------------
    pod 'WordPress-AppbotX', :git => 'https://github.com/wordpress-mobile/appbotx.git', :commit => '479d05f7d6b963c9b44040e6ea9f190e8bd9a47a'

    # --------------------
    # WordPress components
    # --------------------
    pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.1.0'
    pod 'Gridicons', '0.2'
    pod 'NSObject-SafeExpectations', '0.0.2'
    pod 'NSURL+IDN', '0.3'
    pod 'Simperium', '0.8.15'
    pod 'WPMediaPicker', '~> 0.9.1'
    pod 'WordPress-iOS-Editor', '1.6.1'
    pod 'WordPressApi', '0.4.0'
    pod 'WordPressCom-Analytics-iOS', '0.1.13'
    pod 'WordPressCom-Stats-iOS', '0.7.0'
    pod 'wpxmlrpc', '~> 0.8'
    
    target :WordPressTest do
      inherit! :search_paths

      pod 'OHHTTPStubs', '~> 4.6.0'
      pod 'OHHTTPStubs/Swift', '~> 4.6.0'
      pod 'OCMock', '3.1.2'
      pod 'Specta', '1.0.5'
      pod 'Expecta', '1.0.5'
      pod 'Nimble', '~> 4.0.0'
      pod 'RxSwift', '~> 2.5.0'
      pod 'RxTests', '~> 2.5.0'
    end
  end

  target 'WordPressShareExtension' do
  end

  target 'WordPressTodayWidget' do
    pod 'WordPressCom-Stats-iOS/Services', '0.7.0'
  end

end

post_install do |installer_representation|
#   installer_representation.pods_project.targets.each do |target|
#     # See https://github.com/CocoaPods/CocoaPods/issues/3838
#     if target.name.end_with?('WordPressCom-Stats-iOS')
#       target.build_configurations.each do |config|
#         config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= ['$(inherited)', '$PODS_FRAMEWORK_BUILD_PATH', '$PODS_FRAMEWORK_BUILD_PATH/..']
#       end
#     end
#   end
#
#   # Directly set the Targeted Device Family
#   # See https://github.com/CocoaPods/CocoaPods/issues/2292
#   installer_representation.pods_project.build_configurations.each do |config|
#       config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
#   end

  # Does a quick hack to turn off Swift embedding of libraries for extensions
  # See: https://github.com/wordpress-mobile/WordPress-iOS/issues/5160
  system "sed -i '' -E 's/EMBEDDED_CONTENT_CONTAINS_SWIFT[[:space:]]=[[:space:]]YES/EMBEDDED_CONTENT_CONTAINS_SWIFT = NO/g' Pods/Target\\ Support\\ Files/Pods-WordPress_Base-WordPressShareExtension/*.xcconfig"
  system "sed -i '' -E 's/EMBEDDED_CONTENT_CONTAINS_SWIFT[[:space:]]=[[:space:]]YES/EMBEDDED_CONTENT_CONTAINS_SWIFT = NO/g' Pods/Target\\ Support\\ Files/Pods-WordPress_Base-WordPressTodayWidget/*.xcconfig"

end
