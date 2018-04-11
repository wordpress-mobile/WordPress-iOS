source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'
workspace 'WordPress.xcworkspace'



## Pods shared between all the targets
## ===================================
##
def shared_with_all_pods
  pod 'CocoaLumberjack', '3.4.1'
  pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
  pod 'NSObject-SafeExpectations', '0.0.2'
  pod 'UIDeviceIdentifier', '~> 0.4'
end

def shared_with_networking_pods
  pod 'AFNetworking', '3.1.0'
  pod 'wpxmlrpc', '0.8.3'
  pod 'Alamofire', '4.7.0'
end

def shared_test_pods
  pod 'OHHTTPStubs', '6.1.0'
  pod 'OHHTTPStubs/Swift', '6.1.0'
  pod 'OCMock', '~> 3.4'
end



## WordPress iOS
## =============
##
target 'WordPress' do
  project 'WordPress/WordPress.xcodeproj'

  shared_with_all_pods
  shared_with_networking_pods

  ## Third party libraries
  ## =====================
  ##
  pod '1PasswordExtension', '1.8.5'
  pod 'HockeySDK', '5.1.2', :configurations => ['Release-Internal', 'Release-Alpha']
  pod 'MRProgress', '0.8.3'
  pod 'Reachability',	'3.2'
  pod 'SVProgressHUD', '2.2.5'
  pod 'Crashlytics', '3.10.1'
  pod 'BuddyBuildSDK', '1.0.17', :configurations => ['Release-Alpha']
  pod 'FLAnimatedImage', '1.0.12'
  pod 'MGSwipeTableCell', '1.6.6'
  pod 'lottie-ios', '1.5.1'
  pod 'Starscream', '3.0.4'
  pod 'GoogleSignIn', '4.1.2'
  pod 'ZendeskSDK', '1.11.0.1'


  ## Automattic libraries
  ## ====================
  ##
  pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.2.3'
  pod 'Gridicons', '0.15'
  pod 'NSURL+IDN', '0.3'
  pod 'WPMediaPicker', '0.27'
  pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit =>'52849f1be62bc6a6316f3828d56e8fc32f5fa8e4'

  target 'WordPressTest' do
    inherit! :search_paths

    shared_test_pods
    pod 'Specta', '1.0.7'
    pod 'Expecta', '1.0.6'
    pod 'Nimble', '~> 7.0.3'
  end


  ## Share Extension
  ## ===============
  ##
  target 'WordPressShareExtension' do
    inherit! :search_paths

    shared_with_all_pods
    shared_with_networking_pods

    pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit =>'52849f1be62bc6a6316f3828d56e8fc32f5fa8e4'
    pod 'Gridicons', '0.15'
  end


  ## DraftAction Extension
  ## =====================
  ##
  target 'WordPressDraftActionExtension' do
    inherit! :search_paths

    shared_with_all_pods
    shared_with_networking_pods

    pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit =>'52849f1be62bc6a6316f3828d56e8fc32f5fa8e4'
    pod 'Gridicons', '0.15'
  end


  ## Today Widget
  ## ============
  ##
  target 'WordPressTodayWidget' do
    inherit! :search_paths

    shared_with_all_pods
    shared_with_networking_pods
  end
end



## WordPress Authenticator
## =======================
##
target 'WordPressAuthenticator' do
  project 'WordPressAuthenticator/WordPressAuthenticator.xcodeproj'

  pod 'CocoaLumberjack', '3.4.1'

  target 'WordPressAuthenticatorTests' do
    inherit! :search_paths
  end
end



## WordPress.com Stats
## ===================
##
target 'WordPressComStatsiOS' do
  project 'WordPressComStatsiOS/WordPressComStatsiOS.xcodeproj'

  shared_with_all_pods
  shared_with_networking_pods

  target 'WordPressComStatsiOSTests' do
    inherit! :search_paths

    shared_test_pods
  end
end



## WordPress Kit
## =============
##
target 'WordPressKit' do
  project 'WordPressKit/WordPressKit.xcodeproj'

  shared_with_networking_pods
  shared_with_all_pods

  target 'WordPressKitTests' do
    inherit! :search_paths

    shared_test_pods
  end
end



## WordPress Shared
## ================
##
target 'WordPressShared' do
  project 'WordPressShared/WordPressShared.xcodeproj'

  shared_with_all_pods

  target 'WordPressSharedTests' do
    inherit! :search_paths

    shared_test_pods
    pod 'Specta', '1.0.7'
    pod 'Expecta', '1.0.6'
  end
end
