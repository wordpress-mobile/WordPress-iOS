xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod 'AFNetworking',	'1.2.0'
pod 'Reachability',	'3.0.0'
pod 'NSURL+IDN', :podspec => 'https://raw.github.com/koke/NSURL-IDN/master/Podfile'
pod 'DTCoreText',   '1.6.9'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', '~> 1.0'
pod 'wpxmlrpc', '~> 0.4.1'
pod 'WordPressApi', :git => 'https://github.com/koke/WordPressApi.git'
pod 'NSObject-SafeExpectations', :podspec => 'https://raw.github.com/koke/NSObject-SafeExpectations/master/NSObject-SafeExpectations.podspec'
pod 'Mixpanel', '2.3.1'
pod 'CocoaLumberjack', '~>1.8.1'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '1.5.0'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git'
pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'
pod 'CrashlyticsLumberjack', '~>1.0.0'
pod 'HockeySDK', '~>3.5.0'

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
end
