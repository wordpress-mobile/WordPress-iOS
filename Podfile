# frozen_string_literal: true

require_relative 'Gutenberg/cocoapods_helpers'
require 'xcodeproj'

# For security reasons, please always keep the wordpress-mobile source first and the CDN second.
# For more info, see https://github.com/wordpress-mobile/cocoapods-specs#source-order-and-security-considerations
install! 'cocoapods', warn_for_multiple_pod_sources: false
source 'https://github.com/wordpress-mobile/cocoapods-specs.git'
source 'https://cdn.cocoapods.org/'

raise 'Please run CocoaPods via `bundle exec`' unless %w[BUNDLE_BIN_PATH BUNDLE_GEMFILE].any? { |k| ENV.key?(k) }

VERSION_XCCONFIG_PATH = File.join(File.expand_path(__dir__), 'config', 'Common.xcconfig')
APP_IOS_DEPLOYMENT_TARGET = Gem::Version.new(Xcodeproj::Config.new(VERSION_XCCONFIG_PATH).to_hash['IPHONEOS_DEPLOYMENT_TARGET'])

platform :ios, APP_IOS_DEPLOYMENT_TARGET.version
inhibit_all_warnings!
use_frameworks!
workspace 'WordPress.xcworkspace'

def aztec
  ## When using a tagged version, feel free to comment out the WordPress-Aztec-iOS line below.
  ## When using a commit number (during development) you should provide the same commit number for both pods.
  ##
  # pod 'WordPress-Aztec-iOS', git: 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', commit: ''
  # pod 'WordPress-Editor-iOS', git: 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', commit: ''
  # pod 'WordPress-Editor-iOS', git: 'https://github.com/wordpress-mobile/AztecEditor-iOS.git', tag: ''
  pod 'WordPress-Editor-iOS', '~> 1.19.11'
end

abstract_target 'Apps' do
  project 'WordPress/WordPress.xcodeproj'

  ## Gutenberg (React Native)
  ## =====================
  ##
  gutenberg_pod

  ## Automattic libraries
  ## ====================
  ##
  aztec

  ## WordPress App iOS
  ## =================
  ##
  target 'WordPress' do
    target 'WordPressTest' do
      inherit! :search_paths

      gutenberg_pod
    end
  end

  ## Jetpack App iOS
  ## ===============
  ##
  target 'Jetpack'
end

## Share Extension
## ===============
##
target 'WordPressShareExtension' do
  project 'WordPress/WordPress.xcodeproj'

  aztec
end

target 'JetpackShareExtension' do
  project 'WordPress/WordPress.xcodeproj'

  aztec
end

## DraftAction Extension
## =====================
##
target 'WordPressDraftActionExtension' do
  project 'WordPress/WordPress.xcodeproj'

  aztec
end

target 'JetpackDraftActionExtension' do
  project 'WordPress/WordPress.xcodeproj'

  aztec
end

## Tools
## ===================
##

def swiftlint_version
  require 'yaml'

  YAML.load_file('.swiftlint.yml')['swiftlint_version']
end

abstract_target 'Tools' do
  pod 'SwiftLint', swiftlint_version
end

post_install do |installer|
  gutenberg_post_install(installer: installer)

  project_root = File.dirname(__FILE__)

  ## Convert the 3rd-party license acknowledgements markdown into html for use in the app
  require 'commonmarker'

  acknowledgements = 'Acknowledgments'
  markdown = File.read("#{project_root}/Pods/Target Support Files/Pods-Apps-WordPress/Pods-Apps-WordPress-acknowledgements.markdown")
  rendered_html = Commonmarker.to_html(markdown)
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
  styled_html = styled_html.sub('<h1>Acknowledgements</h1>', '')

  ## The glog library's license contains a URL that does not wrap in the web view,
  ## leading to a large right-hand whitespace gutter.  Work around this by explicitly
  ## inserting a <br> in the HTML.  Use gsub juuust in case another one sneaks in later.
  styled_html = styled_html.gsub('p?hl=en#dR3YEbitojA/COPYING', 'p?hl=en#dR3YEbitojA/COPYING<br>')

  File.write("#{project_root}/Pods/Target Support Files/Pods-Apps-WordPress/acknowledgements.html", styled_html)

  # Let Pods targets inherit deployment target from the app
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/4859
  # =====================================
  #
  installer.pods_project.targets.each do |target|
    # Exclude RCT-Folly as it requires explicit deployment target https://git.io/JPb73
    next unless target.name != 'RCT-Folly'

    target.build_configurations.each do |configuration|
      pod_ios_deployment_target = Gem::Version.new(configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
      configuration.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET' if pod_ios_deployment_target <= APP_IOS_DEPLOYMENT_TARGET
    end
  end

  # Fix a code signing issue in Xcode 14 beta.
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/11402#issuecomment-1189861270
  # ====================================
  #
  # TODO: fix the linting issue if this workaround is still needed in Xcode 14 GM.
  # rubocop:disable Style/CombinableLoops
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
    end
  end
  # rubocop:enable Style/CombinableLoops

  yellow_marker = "\033[33m"
  reset_marker = "\033[0m"
  puts "#{yellow_marker}The abstract target warning below is expected. Feel free to ignore it.#{reset_marker}"
end

post_integrate do
  gutenberg_post_integrate
end
