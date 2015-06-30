source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod '1PasswordExtension', '1.1.2'
pod 'AFNetworking',	'~> 2.5.3'
pod 'Reachability',	'3.1.1'
pod 'NSURL+IDN', '0.3'
pod 'DTCoreText',   '1.6.13'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', '~>1.1.3'
pod 'AMPopTip', '~> 0.7'
pod 'wpxmlrpc', '~> 0.8'
pod 'Mixpanel', '2.5.4'
pod 'CocoaLumberjack', '~>2.0'
pod 'NSLogger-CocoaLumberjack-connector', :git => 'https://github.com/steipete/NSLogger-CocoaLumberjack-connector.git', :tag => '1.5'
pod 'google-plus-ios-sdk', '~>1.5'
pod 'CrashlyticsLumberjack', '2.0.1-beta'
pod 'HockeySDK', '~>3.6.0'
pod 'Helpshift', '~>4.10.0'
pod 'Lookback', '0.9.2', :configurations => ['Release-Internal']
pod 'MRProgress', '~>0.7.0'

pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.0.5'
pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/develop/ios/EmailChecker.podspec'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'Simperium', '0.7.9'
pod 'WordPressApi', '~> 0.3.4'
pod 'WordPress-iOS-Shared', '0.3.2'
pod 'WordPress-iOS-Editor', :git => 'https://github.com/wordpress-mobile/WordPress-Editor-iOS.git', :commit => '9812b6c9a699cd654ef5c0cffe9bed9f91c06782'
pod 'WordPressCom-Stats-iOS', '0.3.5'
pod 'WordPressCom-Analytics-iOS', '0.0.33'
pod 'SocketRocket', :git => 'https://github.com/jleandroperez/SocketRocket.git', :commit => '3ff6038ad95fb94fd9bd4021f5ecf07fc53a6927'
pod 'WordPress-AppbotX', :git => 'https://github.com/wordpress-mobile/appbotx.git', :commit => '303b8068530389ea87afde38b77466d685fe3210'
pod 'WPMediaPicker', '~>0.4.1'
pod 'ReactiveCocoa', '~> 2.4.7'
pod 'FormatterKit', '~> 1.8.0'

target 'WordPressTodayWidget', :exclusive => true do
  pod 'WordPressCom-Stats-iOS', '0.3.5'
end

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
  pod 'OCMock', '3.1.2'
  pod 'Specta', '0.5.0'
  pod 'Expecta', '0.3.2'
end

target 'UITests', :exclusive => true do
    pod 'KIF/IdentifierTests', '~>3.1'
end

# We need to add in AF_APP_EXTENSIONS=1 to AFNetworking used by the Today Extension otherwise the build will fail. See - https://github.com/AFNetworking/AFNetworking/pull/2589
post_install do |installer_representation|
  installer_representation.project.targets.each do |target|
    if ["Pods-WordPressTodayWidget-WordPressCom-Stats-iOS", "Pods-WordPressTodayWidget-AFNetworking"].include?(target.name)
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'AF_APP_EXTENSIONS=1']
      end
    end
  end

  # Directly set the Targeted Device Family
  # See https://github.com/CocoaPods/CocoaPods/issues/2292
  installer_representation.project.build_configurations.each do |config|
      config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  end
end
