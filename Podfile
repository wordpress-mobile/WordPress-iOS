source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'
workspace 'WordPress.xcworkspace'

## Pods shared between all the targets
def shared_with_all_pods
  pod 'CocoaLumberjack', '~> 2.2.0'
  pod 'NSObject-SafeExpectations', '0.0.2'
  pod 'WordPressCom-Analytics-iOS', '0.1.29'
end

def shared_with_networking_pods
  pod 'AFNetworking', '3.1.0'  
  pod 'wpxmlrpc', '0.8.3'
end

def shared_test_pods
  pod 'OHHTTPStubs'
  pod 'OHHTTPStubs/Swift'
  pod 'OCMock', '~> 3.0'
end

abstract_target 'WordPress_Base' do
  project 'WordPress/WordPress.xcodeproj'

  ## This pod is only being included to support the share extension ATM - https://github.com/wordpress-mobile/WordPress-iOS/issues/5081
  pod 'WordPressComKit', :git => 'https://github.com/Automattic/WordPressComKit.git', :tag => '0.0.6'
  shared_with_all_pods
  shared_with_networking_pods
  
  target 'WordPress' do
    # ---------------------
    # Third party libraries
    # ---------------------
    pod '1PasswordExtension', '1.8.4'
    pod 'FormatterKit', '~> 1.8.1'
    pod 'HockeySDK', '~> 4.1.5', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MRProgress', '~>0.7.0'
    pod 'Reachability',	'3.2'
    pod 'SVProgressHUD', '~>2.1.2'
    pod 'UIDeviceIdentifier', '~> 0.1'
    pod 'Crashlytics'
    pod 'BuddyBuildSDK', '~> 1.0.14', :configurations => ['Release-Alpha']
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'MGSwipeTableCell', '~> 1.5.6'
    # Temporary until this fix is merged and released
    # https://github.com/daltoniam/Starscream/pull/294
    pod 'Starscream', :git => 'https://github.com/wordpress-mobile/Starscream', :branch => 'wordpress-ios'
    # ----------------------------
    # Forked third party libraries
    # ----------------------------
    pod 'WordPress-AppbotX', :git => 'https://github.com/wordpress-mobile/appbotx.git', :commit => '479d05f7d6b963c9b44040e6ea9f190e8bd9a47a'

    # --------------------
    # WordPress components
    # --------------------
    pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.1.2'
    pod 'Gridicons', '0.5'
    pod 'NSURL+IDN', '0.3'
    pod 'WPMediaPicker', '0.17'
    pod 'WordPress-iOS-Editor', '1.9.1'
    pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '28e8cd4eba56efc0080b3fdef7d1a5693e53b1e7'

    target 'WordPressTest' do
      inherit! :search_paths
      
      shared_test_pods
      pod 'Specta', '1.0.5'
      pod 'Expecta', '1.0.5'
      pod 'Nimble', '~> 7.0.0'
    end
  end

  target 'WordPressShareExtension' do
  end

  target 'WordPressTodayWidget' do
  end
end

target 'WordPressComStatsiOS' do
  project 'WordPressComStatsiOS/WordPressComStatsiOS.xcodeproj'

  shared_with_all_pods
  shared_with_networking_pods

  target 'WordPressComStatsiOSTests' do
    inherit! :search_paths
    
    shared_test_pods
  end
end

target 'WordPressKit' do
  project 'WordPressKit/WordPressKit.xcodeproj'
  
  shared_with_networking_pods
  shared_with_all_pods
  
  target 'WordPressKitTests' do
    inherit! :search_paths
    
    shared_test_pods
  end
end

target 'WordPressShared' do
  project 'WordPressShared/WordPressShared.xcodeproj'

  shared_with_all_pods

  target 'WordPressSharedTests' do
    inherit! :search_paths
    
    shared_test_pods
  end
end
