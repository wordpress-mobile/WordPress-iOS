source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod '1PasswordExtension'
pod 'AFNetworking',	'~> 2.5.1'
pod 'Reachability',	'3.1.1'
pod 'NSURL+IDN', '0.3'
pod 'DTCoreText',   '1.6.13'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', :git => 'https://github.com/TransitApp/SVProgressHUD.git', :commit => '2ac46ae2f2dd37db153ce1daea73b1273ac2bba3'
pod 'AMPopTip', '~> 0.7'
pod 'wpxmlrpc', '~> 0.8'
pod 'Mixpanel', '2.5.4'
pod 'CocoaLumberjack', '~>1.9'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '~>1.5'
pod 'CrashlyticsLumberjack', '~>1.0.0'
pod 'HockeySDK', '~>3.6.0'
pod 'Helpshift', '~>4.8.0'
pod 'CTAssetsPickerController', '~> 2.7.0'
pod 'Lookback', '0.9.2', :configurations => ['Release-Internal']
pod 'MRProgress', '~>0.7.0'

pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'Simperium', '0.7.9'
pod 'WordPressApi', '~> 0.3.4'
pod 'WordPress-iOS-Shared', '0.3'
pod 'WordPress-iOS-Editor', :git => 'git://github.com/wordpress-mobile/WordPress-Editor-iOS', :commit => '983b2483bb68fa499cef5f2b1757550d07770d1b'
pod 'WordPressCom-Stats-iOS', '0.3.0'
pod 'WordPressCom-Analytics-iOS', '0.0.29'
pod 'WordPress-AppbotX', :git => 'https://github.com/wordpress-mobile/appbotx.git', :commit => '303b8068530389ea87afde38b77466d685fe3210'

target 'WordPressTodayWidget', :exclusive => true do
  pod 'WordPressCom-Stats-iOS', '0.3.0'
end

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
  pod 'OCMock'
end

target 'UITests', :exclusive => true do
    pod 'KIF/IdentifierTests', '~>3.1'
end
