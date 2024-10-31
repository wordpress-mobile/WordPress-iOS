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

  # Fix a code signing issue in Xcode 14 beta.
  # This solution is suggested here: https://github.com/CocoaPods/CocoaPods/issues/11402#issuecomment-1189861270
  # ====================================
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end

  yellow_marker = "\033[33m"
  reset_marker = "\033[0m"
  puts "#{yellow_marker}The abstract target warning below is expected. Feel free to ignore it.#{reset_marker}"
end

post_integrate do
  gutenberg_post_integrate
end
