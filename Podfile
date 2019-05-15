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
    pod 'WordPressShared', '~> 1.8.0-beta'

    ## for development:
    # pod 'WordPressShared', :path => '../WordPress-iOS-Shared'

    ## while PR is in review:
    # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :branch => 'task/support-swift-5'
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    ## pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '8a37b93fcc7d7ecb109aef1da2af0e2ec57f2633'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '8a37b93fcc7d7ecb109aef1da2af0e2ec57f2633'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :tag => '1.5.0.beta.1'
    pod 'WordPress-Editor-iOS', '~> 1.6.2'
end

def wordpress_ui
    ## for production:
    pod 'WordPressUI', '~> 1.3.0-beta'
    ## for development:
    ## pod 'WordPressUI', :path => '../WordPressUI-iOS'
    ## while PR is in review:
    ## pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS.git', :commit => '500fd609a7cbb541298bfea92d0ac842cf9b468d'
end

def wordpress_kit
    pod 'WordPressKit', '~> 4.1.1-beta'
    #pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :branch => ''
    #pod 'WordPressKit', :path => '../WordPressKit-iOS'
end

def shared_with_all_pods
    wordpress_shared
    pod 'CocoaLumberjack', '3.5.2'
    pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
    pod 'NSObject-SafeExpectations', '0.0.3'
    pod 'Sentry', '4.3.1'
end

def shared_with_networking_pods    
    pod 'Alamofire', '4.7.3'
    pod 'Reachability', '3.2'

    wordpress_kit
end

def shared_test_pods
    pod 'OHHTTPStubs', '6.1.0'
    pod 'OHHTTPStubs/Swift', '6.1.0'
    pod 'OCMock', '~> 3.4'
end

def shared_with_extension_pods
    pod 'Gridicons', '~> 0.16'
    pod 'ZIPFoundation', '~> 0.9.8'
    pod 'Down', '~> 0.6.6'
end

def gutenberg(options)
    options[:git] = 'http://github.com/wordpress-mobile/gutenberg-mobile/'
    local_gutenberg = ENV['LOCAL_GUTENBERG']
    if local_gutenberg
      options = { :path => local_gutenberg.include?('/') ? local_gutenberg : '../gutenberg-mobile' }
    end
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
        'react-native-video',
    ]
    if options[:path]
        podspec_prefix = options[:path]
    else
        tag_or_commit = options[:tag] || options[:commit]
        podspec_prefix = "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{tag_or_commit}"
    end

    for pod_name in dependencies do
        pod pod_name, :podspec => "#{podspec_prefix}/react-native-gutenberg-bridge/third-party-podspecs/#{pod_name}.podspec.json"
    end
end

## WordPress iOS
## =============
##
target 'WordPress' do
    project 'WordPress/WordPress.xcodeproj'

    shared_with_all_pods
    shared_with_networking_pods
    shared_with_extension_pods

    ## Gutenberg (React Native)
    ## =====================
    ##
    gutenberg :commit => '92be0c592eda8d02fd6a792baf17bcb0b8a606e8'

    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '9.3.3-gb'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.7'

    ## Third party libraries
    ## =====================
    ##
    pod '1PasswordExtension', '1.8.5'
    pod 'Charts', '~> 3.2.2'
    pod 'Gifu', '3.2.0'
    pod 'GiphyCoreSDK', '~> 1.4.0'
    pod 'HockeySDK', '5.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MGSwipeTableCell', '1.6.8'
    pod 'MRProgress', '0.8.3'
    pod 'Starscream', '3.0.6'
    pod 'SVProgressHUD', '2.2.5'
    pod 'ZendeskSDK', '2.3.1'
    pod 'AlamofireNetworkActivityIndicator', '~> 2.3'

    ## Automattic libraries
    ## ====================
    ##

    # Production
    pod 'Automattic-Tracks-iOS', '0.3.5'
    # While in PR
    # pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :commit => 'a15db91a24499913affae84243d45be0e353472a'

    pod 'NSURL+IDN', '0.3'

    pod 'WPMediaPicker', '1.4.1-beta.1'
    ## while PR is in review:
    ## pod 'WPMediaPicker', :git => 'https://github.com/wordpress-mobile/MediaPicker-iOS.git', :commit => 'e55438187d464763efd0b6bf11a0afa1964d9037'
    
    pod 'Gridicons', '~> 0.16'

    pod 'WordPressAuthenticator', '~> 1.5.0-beta'
    # pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'
    # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :commit => ''

    aztec
    wordpress_ui

    target 'WordPressTest' do
        inherit! :search_paths

        shared_test_pods
        pod 'Nimble', '~> 7.3.1'
    end
end


## Share Extension
## ===============
##
target 'WordPressShareExtension' do
    project 'WordPress/WordPress.xcodeproj'

    shared_with_extension_pods

    aztec
    shared_with_all_pods
    shared_with_networking_pods
    wordpress_ui
end


## DraftAction Extension
## =====================
##
target 'WordPressDraftActionExtension' do
    project 'WordPress/WordPress.xcodeproj'

    shared_with_extension_pods

    aztec
    shared_with_all_pods
    shared_with_networking_pods
    wordpress_ui
end


## Today Widget
## ============
##
target 'WordPressTodayWidget' do
    project 'WordPress/WordPress.xcodeproj'
  
    shared_with_all_pods
    shared_with_networking_pods
end



## Notification Content Extension
## ==============================
##
target 'WordPressNotificationContentExtension' do
    project 'WordPress/WordPress.xcodeproj'

    wordpress_kit
    wordpress_shared
    wordpress_ui
end



## Notification Service Extension
## ==============================
##
target 'WordPressNotificationServiceExtension' do
    project 'WordPress/WordPress.xcodeproj'

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
end

## WordPress.com Stats Tests
## =========================
##
target 'WordPressComStatsiOSTests' do
  project 'WordPressComStatsiOS/WordPressComStatsiOS.xcodeproj'

  shared_with_all_pods
  shared_with_networking_pods

  ## Automattic libraries
  ## ====================
  ##
  wordpress_ui

  shared_test_pods
end

## Screenshot Generation
## ===================
##
target 'WordPressScreenshotGeneration' do
    project 'WordPress/WordPress.xcodeproj'

    inherit! :search_paths

    pod 'SimulatorStatusMagic'
end

# Static Frameworks:
# ============
#
# Make all pods that are not shared across multiple targets into static frameworks by overriding the static_framework? function to return true
# Linking the shared frameworks statically would lead to duplicate symbols
# A future version of CocoaPods may make this easier to do. See https://github.com/CocoaPods/CocoaPods/issues/7428
shared_targets = ['WordPressFlux', 'WordPressComStatsiOS']
pre_install do |installer|
    static = []
    dynamic = []
    installer.pod_targets.each do |pod|
        # If this pod is a dependency of one of our shared targets, it must be linked dynamically
        if pod.target_definitions.any? { |t| shared_targets.include? t.name }
          dynamic << pod
          next
        end
        static << pod
        def pod.static_framework?;
          true
        end
    end
    puts "Installing #{static.count} pods as static frameworks"
    puts "Installing #{dynamic.count} pods as dynamic frameworks"
end
