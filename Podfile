source 'https://github.com/CocoaPods/Specs.git'

xcodeproj 'WordPress/WordPress.xcodeproj'

inhibit_all_warnings!

platform :ios, '7.0'
pod '1PasswordExtension'
pod 'AFNetworking',	'~> 2.3.1'
pod 'Reachability',	'3.1.1'
pod 'NSURL+IDN', '0.3'
pod 'DTCoreText',   '1.6.13'
pod 'UIDeviceIdentifier', '~> 0.1'
pod 'SVProgressHUD', :git => 'https://github.com/TransitApp/SVProgressHUD.git', :commit => '2ac46ae2f2dd37db153ce1daea73b1273ac2bba3'
pod 'AMPopTip', '~> 0.7'
pod 'wpxmlrpc', '~> 0.7'
pod 'WordPressApi', '~> 0.2.2'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'Mixpanel', '2.5.4'
pod 'CocoaLumberjack', '~>1.9'
pod 'NSLogger-CocoaLumberjack-connector', '~>1.3'
pod 'google-plus-ios-sdk', '~>1.5'
pod 'MGImageUtilities', :git => 'git://github.com/wordpress-mobile/MGImageUtilities.git', :branch => 'gifsupport'
pod 'EmailChecker', :podspec => 'https://raw.github.com/wordpress-mobile/EmailChecker/master/ios/EmailChecker.podspec'
pod 'CrashlyticsLumberjack', '~>1.0.0'
pod 'HockeySDK', '~>3.6.0'
pod 'Helpshift', '~>4.8.0'
pod 'CTAssetsPickerController', '~> 2.7.0'
pod 'WordPress-iOS-Shared', '0.1.8'
pod 'WordPress-iOS-Editor', '0.4'
pod 'WordPressCom-Stats-iOS', '0.1.6'
pod 'WordPressCom-Analytics-iOS', '0.0.25'
pod 'NSObject-SafeExpectations', '0.0.2'
pod 'SocketRocket', :git => 'https://github.com/jleandroperez/SocketRocket.git', :commit => '3ff6038ad95fb94fd9bd4021f5ecf07fc53a6927'
pod 'Simperium', '0.7.8'
pod 'Lookback', '0.9.2', :configurations => ['Release-Internal']
pod "WordPress-AppbotX", :git => "https://github.com/wordpress-mobile/appbotx.git", :commit => "303b8068530389ea87afde38b77466d685fe3210"
pod 'MRProgress', '~>0.7.0'

target 'WordPressTodayWidget', :exclusive => true do
    pod 'WordPressCom-Stats-iOS', '0.1.6'
end

target :WordPressTest, :exclusive => true do
  pod 'OHHTTPStubs', '1.1.1'
  pod 'OCMock'
end

target 'UITests', :exclusive => true do
    pod 'KIF/IdentifierTests', '~>3.1'
end
