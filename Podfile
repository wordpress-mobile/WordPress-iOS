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
    pod 'WordPressShared', '1.7.1-beta.3'

    ## for development:
    ##pod 'WordPressShared', :path => '../WordPress-iOS-Shared'

    ## while PR is in review:
    ##pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :commit => 'eb39e53acb3806c4aa0b5871c79293b7ab6b3b64'
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    ## pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'e0fc55abb4809b3b23b6d8b56791798af864025d'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => 'e0fc55abb4809b3b23b6d8b56791798af864025d'
    pod 'WordPress-Editor-iOS', '1.4.2'
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
    pod 'WordPressKit', '~> 2.1.0-beta.1'
    #pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :commit => '3886f1d'
    #pod 'WordPressKit', :path => '~/Developer/a8c/WordPressKit-iOS'
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

	wordpress_kit
end

def shared_test_pods
    pod 'OHHTTPStubs', '6.1.0'
    pod 'OHHTTPStubs/Swift', '6.1.0'
    pod 'OCMock', '~> 3.4'
end

def gutenberg_pod(name, branch=nil)
    gutenberg_branch=branch || 'master'
    pod name, :podspec => "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{gutenberg_branch}/react-native-gutenberg-bridge/third-party-podspecs/#{name}.podspec.json"
end

def gutenberg(options)
    pod 'Gutenberg', options
    pod 'RNTAztecView', options
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
    gutenberg :git => 'http://github.com/wordpress-mobile/gutenberg-mobile/', :commit => '6ea31e4f1d2c79fcbcafe9085f7950cd4981f776'

    gutenberg_pod 'React'
    gutenberg_pod 'yoga'
    gutenberg_pod 'Folly'
    gutenberg_pod 'react-native-safe-area'
    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '8.0.9-gb.0'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.5'
    
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
    pod 'Reachability',    '3.2'
    pod 'Starscream', '3.0.6'
    pod 'SVProgressHUD', '2.2.5'
    pod 'ZendeskSDK', '2.2.0'


    ## Automattic libraries
    ## ====================
    ##
    pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :tag => '0.3.2-beta.1'
    pod 'NSURL+IDN', '0.3'
    pod 'WPMediaPicker', '1.3.2'
    pod 'Gridicons', '~> 0.16'
    ## while PR is in review:
    ## pod 'WPMediaPicker', :git => 'https://github.com/wordpress-mobile/MediaPicker-iOS.git', :commit => 'e546205cd2a992838837b0a4de502507b89b6e63'

    pod 'WordPressAuthenticator', '~> 1.1.9'
    #pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'
    #pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git' , :commit => '90a025caaf91cbecd43fa09f98d86b2402f81a09'


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

        shared_with_all_pods
        shared_with_networking_pods
        aztec
        wordpress_ui
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
