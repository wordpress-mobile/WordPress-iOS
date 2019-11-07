source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'
workspace 'WordPress.xcworkspace'

## Pods shared between all the targets
## ===================================
##
def wordpress_shared
    ## for production:
    pod 'WordPressShared', '~> 1.8.8'

    ## for development:
    # pod 'WordPressShared', :path => '../WordPress-iOS-Shared'

    ## while PR is in review:
    # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared', :branch => 'feature/change-username-events'
    # pod 'WordPressShared', :git => 'https://github.com/wordpress-mobile/WordPress-iOS-Shared.git', :commit	=> ''
end

def aztec
    ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
    ## When using a commit number (during development) you should provide the same commit number for both pods.
    ##
    ## pod 'WordPress-Aztec-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '81e1e1bb1cb209004d66bba75338595cc9aab147'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :commit => '81e1e1bb1cb209004d66bba75338595cc9aab147'
    ## pod 'WordPress-Editor-iOS', :git => 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', :tag => '1.5.0.beta.1'
    ## pod 'WordPress-Editor-iOS', :path => '../AztecEditor-iOS'
    pod 'WordPress-Editor-iOS', '~> 1.11.0'
end

def wordpress_ui
    ## for production:
    pod 'WordPressUI', '~> 1.5.0'

    ## for development:
    #pod 'WordPressUI', :path => '../WordPressUI-iOS'
    ## while PR is in review:
    #pod 'WordPressUI', :git => 'https://github.com/wordpress-mobile/WordPressUI-iOS', :branch => ''
end

def wordpress_kit
    pod 'WordPressKit', '~> 4.5.3-beta.2'
    #pod 'WordPressKit', :git => 'https://github.com/guarani/WordPressKit-iOS.git', :branch => 'issue/12141-restore-revision-dialog'
    #pod 'WordPressKit', :git => 'https://github.com/wordpress-mobile/WordPressKit-iOS.git', :commit => ''
    #pod 'WordPressKit', :path => '../WordPressKit-iOS'
end

def shared_with_all_pods
    wordpress_shared
    pod 'CocoaLumberjack', '3.5.2'
    pod 'FormatterKit/TimeIntervalFormatter', '1.8.2'
    pod 'NSObject-SafeExpectations', '0.0.3'
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
        'React-Core',
        'React-DevSupport',
        'React-RCTActionSheet',
        'React-RCTAnimation',
        'React-RCTBlob',
        'React-RCTImage',
        'React-RCTLinking',
        'React-RCTNetwork',
        'React-RCTSettings',
        'React-RCTText',
        'React-RCTVibration',
        'React-RCTWebSocket',
        'React-cxxreact',
        'React-jsinspector',
        'React-jsi',
        'React-jsiexecutor',
        'yoga',
        'Folly',
        'glog',
        'react-native-keyboard-aware-scroll-view',
        'react-native-safe-area',
        'react-native-video',
        'RNSVG',
        'ReactNativeDarkMode',
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
    gutenberg :commit => 'bdbe882b1071cbfdd67fc3a5314e5d1de37cb04b'

    ## Third party libraries
    ## =====================
    ##
    pod '1PasswordExtension', '1.8.5'
    pod 'Charts', '~> 3.2.2'
    pod 'Gifu', '3.2.0'
    pod 'HockeySDK', '5.1.4', :configurations => ['Release-Internal', 'Release-Alpha']
    pod 'MRProgress', '0.8.3'
    pod 'Starscream', '3.0.6'
    pod 'SVProgressHUD', '2.2.5'
    pod 'ZendeskSDK', :git => 'https://github.com/zendesk/zendesk_sdk_ios', :tag => '3.0.2'
    pod 'AlamofireNetworkActivityIndicator', '~> 2.3'
    pod 'FSInteractiveMap', :git => 'https://github.com/wordpress-mobile/FSInteractiveMap.git', :tag => '0.2.0'
    pod 'JTAppleCalendar', '~> 8.0.2'

    ## Automattic libraries
    ## ====================
    ##

    # Production
    pod 'Automattic-Tracks-iOS', '~> 0.4.2'
    # While in PR
    # pod 'Automattic-Tracks-iOS', :git => 'https://github.com/Automattic/Automattic-Tracks-iOS.git', :commit => '0cc8960098791cfe1b02914b15a662af20b60389'

    pod 'NSURL+IDN', '0.3'

    pod 'WPMediaPicker', '~> 1.6.0'
    ## while PR is in review:
    ## pod 'WPMediaPicker', :git => 'https://github.com/wordpress-mobile/MediaPicker-iOS.git', :commit => '7c3cb8f00400b9316a803640b42bb88a66bbc648'

    pod 'Gridicons', '~> 0.16'

    pod 'WordPressAuthenticator', '~> 1.10.2'
    # pod 'WordPressAuthenticator', :path => '../WordPressAuthenticator-iOS'
    # pod 'WordPressAuthenticator', :git => 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git', :branch => ''

    aztec
    wordpress_ui

    target 'WordPressTest' do
        inherit! :search_paths

        shared_test_pods
        pod 'Nimble', '~> 7.3.1'
    end


    post_install do

        ## Convert the 3rd-party license acknowledgements markdown into html for use in the app
        require 'commonmarker'

        project_root = File.dirname(__FILE__)
        acknowledgements = 'Acknowledgments'
        markdown = File.read("#{project_root}/Pods/Target Support Files/Pods-WordPress/Pods-WordPress-acknowledgements.markdown")
        rendered_html = CommonMarker.render_html(markdown, :DEFAULT)
        styled_html = "<head>
                         <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
                         <style>
                           body {
                             font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
                             font-size: 16px;
                             color: #1a1a1a;
                             margin: 20px;
                           }
                          @media (prefers-color-scheme: dark) {
                           body {
                            background: #1a1a1a;
                            color: white;
                           }
                          }
                           pre {
                            white-space: pre-wrap;
                           }
                         </style>
                         <title>
                           #{acknowledgements}
                         </title>
                       </head>
                       <body>
                         #{rendered_html}
                       </body>"

          ## Remove the <h1>, since we've promoted it to <title>
          styled_html = styled_html.sub("<h1>Acknowledgements</h1>", '')

          ## The glog library's license contains a URL that does not wrap in the web view,
          ## leading to a large right-hand whitespace gutter.  Work around this by explicitly
          ## inserting a <br> in the HTML.  Use gsub juuust in case another one sneaks in later.
          styled_html = styled_html.gsub('p?hl=en#dR3YEbitojA/COPYING', 'p?hl=en#dR3YEbitojA/COPYING<br>')

        File.write("#{project_root}/Pods/Target Support Files/Pods-WordPress/acknowledgements.html", styled_html)
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
    
    wordpress_ui
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


## Mocks
## ===================
##
def wordpress_mocks
  pod 'WordPressMocks', '~> 0.0.6'
  # pod 'WordPressMocks', :git => 'https://github.com/wordpress-mobile/WordPressMocks.git', :commit => ''
  # pod 'WordPressMocks', :path => '../WordPressMocks'
end


## Screenshot Generation
## ===================
##
target 'WordPressScreenshotGeneration' do
    project 'WordPress/WordPress.xcodeproj'

    wordpress_mocks
    pod 'SimulatorStatusMagic'
end

## UI Tests
## ===================
##
target 'WordPressUITests' do
    project 'WordPress/WordPress.xcodeproj'

    wordpress_mocks
end

# Static Frameworks:
# ============
#
# Make all pods that are not shared across multiple targets into static frameworks by overriding the static_framework? function to return true
# Linking the shared frameworks statically would lead to duplicate symbols
# A future version of CocoaPods may make this easier to do. See https://github.com/CocoaPods/CocoaPods/issues/7428
shared_targets = ['WordPressFlux']
pre_install do |installer|
    static = []
    dynamic = []
    installer.pod_targets.each do |pod|

        # Statically linking Sentry results in a conflict with `NSDictionary.objectAtKeyPath`, but dynamically
        # linking it resolves this.
        if pod.name == "Sentry"
          dynamic << pod
          next
        end

        # If this pod is a dependency of one of our shared targets, it must be linked dynamically
        if pod.target_definitions.any? { |t| shared_targets.include? t.name }
          dynamic << pod
          next
        end
        static << pod
		pod.instance_variable_set(:@build_type, Pod::Target::BuildType.static_framework)
    end
    puts "Installing #{static.count} pods as static frameworks"
    puts "Installing #{dynamic.count} pods as dynamic frameworks"
end
