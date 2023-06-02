# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

require 'net/http'
require 'pathname'
require 'ruby-progressbar'
require 'uri'
require 'zlib'
require_relative './version'

DEFAULT_GUTENBERG_LOCATION = File.join(__dir__, '..', '..', 'gutenberg-mobile')

# Note that the pods in this array might seem unused if you look for
# `import` statements in this codebase. However, make sure to also check
# whether they are used in the gutenberg-mobile and Gutenberg projects.
#
# See https://github.com/wordpress-mobile/gutenberg-mobile/issues/5025
DEPENDENCIES = %w[
  FBLazyVector
  React
  ReactCommon
  RCTRequired
  RCTTypeSafety
  React-Core
  React-CoreModules
  React-RCTActionSheet
  React-RCTAnimation
  React-RCTBlob
  React-RCTImage
  React-RCTLinking
  React-RCTNetwork
  React-RCTSettings
  React-RCTText
  React-RCTVibration
  React-callinvoker
  React-cxxreact
  React-jsinspector
  React-jsi
  React-jsiexecutor
  React-logger
  React-perflogger
  React-runtimeexecutor
  boost
  Yoga
  RCT-Folly
  glog
  react-native-safe-area
  react-native-safe-area-context
  react-native-video
  react-native-webview
  RNSVG
  react-native-slider
  BVLinearGradient
  react-native-get-random-values
  react-native-blur
  RNScreens
  RNReanimated
  RNGestureHandler
  RNCMaskedView
  RNCClipboard
  RNFastImage
  React-Codegen
  React-bridging
].freeze

# rubocop:disable Metrics/AbcSize
def gutenberg_pod(config: GUTENBERG_CONFIG)
  options = config

  local_gutenberg_key = 'LOCAL_GUTENBERG'
  local_gutenberg = ENV.fetch(local_gutenberg_key, nil)
  if local_gutenberg
    options = { path: File.exist?(local_gutenberg) ? local_gutenberg : DEFAULT_GUTENBERG_LOCATION }

    raise "Could not find Gutenberg pod at #{options[:path]}. You can configure the path using the #{local_gutenberg_key} environment variable." unless File.exist?(options[:path])

    pod 'Gutenberg', options
    pod 'RNTAztecView', options

    gutenberg_dependencies(options: options)
  elsif options[:tag]
    options[:git] = "https://github.com/#{GITHUB_ORG}/#{REPO_NAME}.git"
    options[:submodules] = true

    # This duplication with the branch above will disappear once tags will use pre-built binaries.
    pod 'Gutenberg', options
    pod 'RNTAztecView', options

    gutenberg_dependencies(options: options)
  elsif options[:commit]
    # Notice the use of relative path, otherwise we'd get the full path of the user that run the `pod install` command tracked in Podfile.lock.
    # Also notice the path is relative from Dir.pwd, that is, the location where the script running this code is invoked to avoid absolute paths making the checksum non determinstic.
    pod 'Gutenberg', path: Pathname.new(File.join(__dir__, 'Gutenberg.podspec')).relative_path_from(Dir.pwd).to_s
  end
end
# rubocop:enable Metrics/AbcSize

def gutenberg_dependencies(options:)
  if options[:path]
    podspec_prefix = options[:path]
  elsif options[:tag]
    tag = options[:tag]
    podspec_prefix = "https://raw.githubusercontent.com/#{GITHUB_ORG}/#{REPO_NAME}/#{tag}"
  elsif options[:commit]
    return # when referencing via a commit, we donwload pre-built frameworks
  else
    raise "Unexpected Gutenberg dependencies configuration '#{options}'"
  end

  podspec_prefix += '/third-party-podspecs'
  podspec_extension = 'podspec.json'

  # FBReactNativeSpec needs special treatment because of react-native-codegen code generation
  pod 'FBReactNativeSpec', podspec: "#{podspec_prefix}/FBReactNativeSpec/FBReactNativeSpec.#{podspec_extension}"

  DEPENDENCIES.each do |pod_name|
    pod pod_name, podspec: "#{podspec_prefix}/#{pod_name}.#{podspec_extension}"
  end
end

def archive_url(commit:)
  xcframework_storage_url = 'https://d2twmm2nzpx3bg.cloudfront.net'
  "#{xcframework_storage_url}/Gutenberg-#{commit}.tar.gz"
end
