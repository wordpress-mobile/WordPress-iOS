source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'
workspace 'WordPress.xcworkspace'

plugin 'cocoapods-repo-update'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['WordPress-Aztec-iOS', 'WordPress-Editor-iOS'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end


## Pods shared between all the targets
## ===================================
##
def wordpress_shared
    ## for production:
    pod 'WordPressShared', '~> 1.6.0'

    ## for development:
    ##pod 'WordPressShared', :path => '../WordPress-iOS-Shared'

    ## while PR is in review:
    ##pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :commit => 'd664be9e496112b8f2d98f41607db41cbcc6fd0b'
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    ## pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'e0fc55abb4809b3b23b6d8b56791798af864025d'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'e0fc55abb4809b3b23b6d8b56791798af864025d'
    pod 'WordPress-Editor-iOS', '1.4.1'
end

def wordpress_ui
    ## for production:
    pod 'WordPressUI', '~> 1.1'
    ## for development:
    ## pod 'WordPressUI', :path => '../WordPressUI-iOS'
    ## while PR is in review:
    ## pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :commit => 'aae4524cd95ae24b725b1cad8c54918a3d5b2e59'
end

def wordpress_kit
    pod 'WordPressKit', '~> 1.7.0-beta'
    ##pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :commit => 'b2d5ec226b65634071948dc00290dd88d51f6434'
    ##pod 'WordPressKit', :path => '~/Developer/a8c/WordPressKit-iOS'
end

def shared_with_all_pods
    wordpress_shared
    pod 'CocoaLumberjack', '3.4.2'
    pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
    pod 'NSObject-SafeExpectations', '0.0.3'
    pod 'UIDeviceIdentifier', '~> 0.4'
end

def shared_with_networking_pods
    pod 'AFNetworking', '3.2.1'
    pod 'Alamofire', '4.7.3'
    pod 'wpxmlrpc', '0.8.3'

	wordpress_kit
end

def shared_test_pods
    pod 'OHHTTPStubs', '6.1.0'
    pod 'OHHTTPStubs/Swift', '6.1.0'
    pod 'OCMock', '~> 3.4'
end

def gutenberg_pod(name)
    gutenberg_branch='develop'
    pod name, :podspec => "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{gutenberg_branch}/react-native-gutenberg-bridge/third-party-podspecs/#{name}.podspec.json"
end

## WordPress iOS
## =============
##
target 'WordPress' do
    project 'WordPress/WordPress.xcodeproj'

    shared_with_all_pods
    shared_with_networking_pods

    ## React Native
    ## =====================
    ##
    pod 'Gutenberg', :git => 'http://github.com/wordpress-mobile/gutenberg-mobile/', :commit => '704d003adc1f1b76ee0978aa54e05a36fb16371d'
    gutenberg_pod 'React'
    gutenberg_pod 'yoga'
    gutenberg_pod 'Folly'
    gutenberg_pod 'react-native-safe-area'
    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '8.0.9-gb.0'
    pod 'RNTAztecView', :git => 'https://github.com/wordpress-mobile/react-native-aztec.git', :tag => 'v0.1.3'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.2'

    ## Third party libraries
    ## =====================
    ##
    pod '1PasswordExtension', '1.8.5'
    pod 'HockeySDK', '5.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MRProgress', '0.8.3'
    pod 'Reachability',    '3.2'
    pod 'SVProgressHUD', '2.2.5'
    pod 'Crashlytics', '3.11.0'
    pod 'BuddyBuildSDK', '1.0.17', :configurations => ['Release-Alpha']
    pod 'Gifu', '3.2.0'
    pod 'GiphyCoreSDK', '~> 1.4.0'
    pod 'MGSwipeTableCell', '1.6.7'
    pod 'lottie-ios', '2.5.0'
    pod 'Starscream', '3.0.6'
    pod 'ZendeskSDK', '2.2.0'


    ## Automattic libraries
    ## ====================
    ##
    pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.2.3'
    pod 'Gridicons', '0.16'
    pod 'NSURL+IDN', '0.3'
    pod 'WPMediaPicker', '1.3.1'
    ## while PR is in review:
    ## pod 'WPMediaPicker', :git => 'https://github.com/wordpress-mobile/MediaPicker-iOS.git', :commit => '82f798c0dc18b17a11dfafa37f1fd39eb508b29b'

    #pod 'WordPressAuthenticator', '~> 1.1.7'
    #pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'
    pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git' , :commit => 'c2bd805de40a00730bc522db8a965b4d4669374e'

    aztec
    wordpress_ui

    target 'WordPressTest' do
        inherit! :search_paths

        shared_test_pods
        pod 'Nimble', '~> 7.1.1'
    end


    ## Share Extension
    ## ===============
    ##
    target 'WordPressShareExtension' do
        inherit! :search_paths

        shared_with_all_pods
        shared_with_networking_pods
        aztec
        wordpress_ui
        pod 'Gridicons', '0.16'
    end


    ## DraftAction Extension
    ## =====================
    ##
    target 'WordPressDraftActionExtension' do
        inherit! :search_paths

        shared_with_all_pods
        shared_with_networking_pods
        aztec
        wordpress_ui
        pod 'Gridicons', '0.16'
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



## Notification Content Extension
## ==============================
##
target 'WordPressNotificationContentExtension' do
    project 'WordPress/WordPress.xcodeproj'

    inherit! :search_paths

	wordpress_kit
    wordpress_shared
    wordpress_ui
end



## Notification Service Extension
## ==============================
##
target 'WordPressNotificationServiceExtension' do
    project 'WordPress/WordPress.xcodeproj'

    inherit! :search_paths

    pod 'Gridicons', '0.16'

    wordpress_kit
    wordpress_shared
    wordpress_ui
end



## WordPress.com Stats
## ===================
##
target 'WordPressComStatsiOS' do
    project 'WordPressComStatsiOS/WordPressComStatsiOS.xcodeproj'

    shared_with_all_pods
    shared_with_networking_pods

    ## Automattic libraries
    ## ====================
    ##
    wordpress_ui

    target 'WordPressComStatsiOSTests' do
        inherit! :search_paths

        shared_test_pods
    end
end

## Screenshot Generation
## ===================
##
target 'WordPressScreenshotGeneration' do
    project 'WordPress/WordPress.xcodeproj'

    inherit! :search_paths

    pod 'SimulatorStatusMagic'
end
