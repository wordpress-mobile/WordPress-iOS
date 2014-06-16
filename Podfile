xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod 'AFNetworking',	'2.2.3'
pod 'Reachability',	'3.1.1'
pod 'NSURL+IDN', :podspec => 'https://raw.github.com/koke/NSURL-IDN/master/Podfile'
pod 'DTCoreText',   '1.6.9'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', '~> 1.0'
pod 'wpxmlrpc', '~> 0.4.1'
pod 'WordPressApi', :git => 'https://github.com/koke/WordPressApi.git', :branch => 'afnetworking2'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'Mixpanel', '2.3.1'
pod 'CocoaLumberjack', '~>1.8.1'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '~>1.5'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'
pod 'CrashlyticsLumberjack', '~>1.0.0'
pod 'HockeySDK', '~>3.5.0'
pod 'Helpshift', '4.3.1'
pod 'Taplytics', '~>1.2.50'
pod 'CTAssetsPickerController', '~> 2.2.2'
pod 'WordPress-iOS-Shared', '0.0.2'
pod 'WordPressCom-Stats-iOS', '0.0.2'
pod 'NSObject-SafeExpectations', '0.0.2'

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
  pod 'OCMock'
end
