source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'
workspace 'WordPress.xcworkspace'


post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['Gifu', 'Starscream', 'WordPress-Aztec-iOS', 'WordPress-Editor-iOS'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end


## Pods shared between all the targets
## ===================================
##
def shared_with_all_pods
    pod 'WordPressShared', '1.1.1-beta.5'
    pod 'CocoaLumberjack', '3.4.2'
    pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
    pod 'NSObject-SafeExpectations', '0.0.3'
    pod 'UIDeviceIdentifier', '~> 0.4'
end

def shared_with_networking_pods
    pod 'AFNetworking', '3.2.1'
    pod 'Alamofire', '4.7.3'
    pod 'wpxmlrpc', '0.8.3'
    pod 'WordPressKit', '1.4.1'
end

def shared_test_pods
    pod 'OHHTTPStubs', '6.1.0'
    pod 'OHHTTPStubs/Swift', '6.1.0'
    pod 'OCMock', '~> 3.4'
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    ## pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '14846f9550e24993d61d24df76cee84f3363ee91'
    pod 'WordPress-Editor-iOS', '1.0.2'
end

def wordpress_ui
    ## for production:
    pod 'WordPressUI', '1.0.8'
    ## for development:
    ## pod 'WordPressUI', :path => '../WordPressUI-iOS'
    ## while PR is in review:
    ## pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :commit => '5ec2be1533a86335710221ec20df5b4ba78b06e4'
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
    pod 'Gutenberg', :git => 'http://github.com/wordpress-mobile/gutenberg-mobile/'
    pod 'React', :podspec => 'Podspecs/React.podspec.json'
    pod 'yoga', :podspec => 'Podspecs/yoga.podspec.json'
    pod 'Folly', :podspec => 'Podspecs/Folly.podspec.json'
    pod 'RNSVG', :git => 'https://github.com/react-native-community/react-native-svg.git', :tag => '6.5.2'
    pod 'RNTAztecView', :git => 'https://github.com/wordpress-mobile/react-native-aztec.git'

    ## Third party libraries
    ## =====================
    ##
    pod '1PasswordExtension', '1.8.5'
    pod 'HockeySDK', '5.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MRProgress', '0.8.3'
    pod 'Reachability',    '3.2'
    pod 'SVProgressHUD', '2.2.5'
    pod 'Crashlytics', '3.10.8'
    pod 'BuddyBuildSDK', '1.0.17', :configurations => ['Release-Alpha']
    pod 'Gifu', '3.1.0'
    pod 'GiphyCoreSDK', '~> 1.4.0'
    pod 'MGSwipeTableCell', '1.6.7'
    pod 'lottie-ios', '2.5.0'
    pod 'Starscream', '3.0.4'
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
    pod 'WordPressAuthenticator', '1.1.1'

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

    pod 'WordPressKit', '1.4.1'
    pod 'WordPressShared', '1.1.1-beta.5'
    wordpress_ui
end



## Notification Service Extension
## ==============================
##
target 'WordPressNotificationServiceExtension' do
    project 'WordPress/WordPress.xcodeproj'

    inherit! :search_paths

    pod 'Gridicons', '0.16'
    pod 'WordPressKit', '1.4.1'
    pod 'WordPressShared', '1.1.1-beta.5'

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
