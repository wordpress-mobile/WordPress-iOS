source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

use_frameworks!

platform :ios, '9.0'

target 'WordPress', :exclusive => true do
  pod '1PasswordExtension', '1.6.4'
  pod 'AFNetworking',	'2.6.3'
  pod 'Reachability',	'3.2'
  pod 'NSURL+IDN', '0.3'
  pod 'DTCoreText',   '1.6.16'
  pod 'UIDeviceIdentifier', '~> 0.1'
  pod 'SVProgressHUD', '~>1.1.3'
  pod 'AMPopTip', '~> 0.7'
  pod 'wpxmlrpc', '~> 0.8'
  pod 'Mixpanel', '2.8.2'
  pod 'CocoaLumberjack', '~> 2.2.0'
  pod 'HockeySDK', '~>3.8.0'
  pod 'Helpshift', '~> 5.3.0-support'
  pod 'Lookback', '1.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
  pod 'MRProgress', '~>0.7.0'

  pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.0.13'
  pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/develop/ios/EmailChecker.podspec'
  pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
  pod 'NSObject-SafeExpectations', '0.0.2'
  pod 'Simperium', '0.8.10'
  pod 'WordPressApi', :git => "https://github.com/wordpress-mobile/WordPress-API-iOS.git"
  pod 'WordPress-iOS-Shared', '0.5.1'
  pod 'WordPress-iOS-Editor', '1.1.2'
  pod 'WordPressCom-Stats-iOS/UI', '0.6.1'
  pod 'WordPressCom-Analytics-iOS', '0.1.3'
  pod 'WordPress-AppbotX', :git => 'https://github.com/wordpress-mobile/appbotx.git', :commit => '87bae8c770cfc4e053119f2d00f76b2f653b26ce'
  pod 'WPMediaPicker', '~> 0.7.3'
  pod 'ReactiveCocoa', '~> 2.4.7'
  pod 'FormatterKit', '~> 1.8.0'
end

target 'WordPressTodayWidget', :exclusive => true do
  pod 'WordPress-iOS-Shared', '0.5.1'
  pod 'WordPressCom-Stats-iOS/Services', '0.6.1'
end

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '~> 4.6.0'
  pod 'OHHTTPStubs/Swift', '~> 4.6.0'
  pod 'OCMock', '3.1.2'
  pod 'Specta', '1.0.5'
  pod 'Expecta', '0.3.2'
  pod 'Nimble', '~> 3.0.0'
end

target 'UITests', :exclusive => true do
    pod 'KIF/IdentifierTests', '~>3.1'
end

post_install do |installer_representation|
  # We need to add in AF_APP_EXTENSIONS=1 to AFNetworking used by the Today Extension otherwise the build will fail. See - https://github.com/AFNetworking/AFNetworking/pull/2589
  installer_representation.pods_project.targets.each do |target|
    if ["Pods-WordPressTodayWidget-WordPressCom-Stats-iOS", "Pods-WordPressTodayWidget-AFNetworking"].include?(target.name)
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'AF_APP_EXTENSIONS=1']
      end
    end

    # See https://github.com/CocoaPods/CocoaPods/issues/3838
    if target.name.end_with?('WordPressCom-Stats-iOS')
      target.build_configurations.each do |config|
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= ['$(inherited)', '$PODS_FRAMEWORK_BUILD_PATH', '$PODS_FRAMEWORK_BUILD_PATH/..']
      end
    end
  end

  # Directly set the Targeted Device Family
  # See https://github.com/CocoaPods/CocoaPods/issues/2292
  installer_representation.pods_project.build_configurations.each do |config|
      config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  end
end
