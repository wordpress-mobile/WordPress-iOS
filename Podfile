source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod 'AFNetworking',	'~> 2.3.1'
pod 'Reachability',	'3.1.1'
pod 'NSURL+IDN', '0.3'
pod 'DTCoreText',   '1.6.13'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', '~> 1.0'
pod 'wpxmlrpc', '~> 0.4.1'
pod 'WordPressApi', :git => 'https://github.com/wordpress-mobile/WordPressApi.git'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'Mixpanel', '2.5.3'
pod 'CocoaLumberjack', '~>1.8.1'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '~>1.5'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'
pod 'CrashlyticsLumberjack', '~>1.0.0'
pod 'HockeySDK', '~>3.5.0'
pod 'Helpshift', '~>4.8.0'
pod 'Taplytics', '~>1.3.10'
pod 'CTAssetsPickerController', '~> 2.2.2'
pod 'WordPress-iOS-Shared', '0.1.2'
pod 'WordPress-iOS-Editor', :git => 'git://github.com/wordpress-mobile/WordPress-iOS-Editor', :branch => 'release/0.2.2', :commit => '23ceee9ca3fa59971e869c3a1f459afe147633e5'
pod 'WordPressCom-Stats-iOS', '0.1.4'
pod 'WordPressCom-Analytics-iOS', '0.0.6'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'SocketRocket', :git => 'https://github.com/jleandroperez/SocketRocket.git', :branch => 'master'
pod 'Simperium', '0.7.1'
pod 'Lookback', '0.6.5'

target 'WordPressTodayWidget', :exclusive => true do
    pod 'WordPressCom-Stats-iOS', '0.1.4'
end

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
  pod 'OCMock'
end
