source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'
workspace 'WordPress.xcworkspace'

plugin 'cocoapods-repo-update'

## Pods shared between all the targets
## ===================================
##
def wordpress_shared
    ## for production:
    pod 'WordPressShared', '~> 1.7.3-beta.2'

    ## for development:
    # pod 'WordPressShared', :path => '../WordPress-iOS-Shared'

    ## while PR is in review:
    # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :commit => '994dd2b'
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    #pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'a916afc713e5d650f47fd03772022c01ca0ac8a8'
    #pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'a916afc713e5d650f47fd03772022c01ca0ac8a8'
    ##pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :tag => '1.5.0.beta.1'
    pod 'WordPress-Editor-iOS', '1.5.0'
end

def wordpress_ui
    ## for production:
    pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :tag => '1.2.0'
    ## for development:
    ## pod 'WordPressUI', :path => '../WordPressUI-iOS'
    ## while PR is in review:
    ## pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :commit => '9972b8f597328a619a4c0110d89d62f09df3ff82'
end

def wordpress_kit
    pod 'WordPressKit', '~> 3.2.2beta-2'
    #pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :commit => 'c5ad18dbfd381649d3ff7fd42a84cbf2a559e03d'
    #pod 'WordPressKit', :path => '~/Developer/WordPressKit-iOS'
end

def shared_with_all_pods
    wordpress_shared
    pod 'CocoaLumberjack', '3.4.2'
    pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
    pod 'NSObject-SafeExpectations', '0.0.3'
end

def shared_with_networking_pods
    pod 'AFNetworking', '3.2.1'
    pod 'Alamofire', '4.7.3'
    pod 'Reachability', '3.2'

	wordpress_kit
end

def shared_test_pods
    pod 'OHHTTPStubs', '6.1.0'
    pod 'OHHTTPStubs/Swift', '6.1.0'
    pod 'OCMock', '~> 3.4'
end

def gutenberg(options)
    options[:git] = 'http://github.com/wordpress-mobile/gutenberg-mobile/'
    pod 'Gutenberg', options
    pod 'RNTAztecView', options

    gutenberg_dependencies options
end

def gutenberg_dependencies(options)
    dependencies = [
        'React',
        'yoga',
        'Folly',
        'react-native-safe-area',
    ]
    tag_or_commit = options[:tag] || options[:commit]

    for pod_name in dependencies do
        pod pod_name, :podspec => "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{tag_or_commit}/react-native-gutenberg-bridge/third-party-podspecs/#{pod_name}.podspec.json"
    end
end

## WordPress iOS
## =============
##
target 'WordPress' do
    project 'WordPress/WordPress.xcodeproj'

    shared_with_all_pods
    shared_with_networking_pods

    ## Gutenberg (React Native)
    ## =====================
    ##
    gutenberg :commit => 'a090aafc156cb272ccc607628839365dc62efbb4'

    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '9.3.3-gb'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.7'

    ## Third party libraries
    ## =====================
    ##
    pod '1PasswordExtension', '1.8.5'
    pod 'Charts', '~> 3.2.2'
    pod 'Crashlytics', '3.12.0'
    pod 'Gifu', '3.2.0'
    pod 'GiphyCoreSDK', '~> 1.4.0'
    pod 'HockeySDK', '5.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MGSwipeTableCell', '1.6.8'
    pod 'MRProgress', '0.8.3'
    pod 'Starscream', '3.0.6'
    pod 'SVProgressHUD', '2.2.5'
    pod 'ZendeskSDK', '2.2.0'


    ## Automattic libraries
    ## ====================
    ##
    pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.3.2'
    pod 'NSURL+IDN', '0.3'
    pod 'WPMediaPicker', '1.3.2'
    pod 'Gridicons', '~> 0.16'
    ## while PR is in review:
    ## pod 'WPMediaPicker', :git => 'https://github.com/wordpress-mobile/MediaPicker-iOS.git', :commit => 'e546205cd2a992838837b0a4de502507b89b6e63'

    pod 'WordPressAuthenticator', '~> 1.2.0'
    #pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'
    #pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git' , :commit => '867fa63'


    aztec
    wordpress_ui
    target 'WordPressTest' do
        inherit! :search_paths

        shared_test_pods
        pod 'Nimble', '~> 7.3.1'
    end


    ## Share Extension
    ## ===============
    ##
    target 'WordPressShareExtension' do
        inherit! :search_paths

        aztec
        shared_with_all_pods
        shared_with_networking_pods
        wordpress_ui
    end


    ## DraftAction Extension
    ## =====================
    ##
    target 'WordPressDraftActionExtension' do
        inherit! :search_paths

        aztec
        shared_with_all_pods
        shared_with_networking_pods
        wordpress_ui
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
