# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

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
    pod 'Gutenberg', podspec: "https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-#{options[:tag]}.podspec"
  elsif options[:commit]
    pod 'Gutenberg', podspec: "https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-#{options[:commit]}.podspec"
  end
end

def gutenberg_dependencies(options:)
  if options[:path]
    podspec_prefix = options[:path]
  elsif options[:tag] || options[:commit]
    return # when referencing via a tag or commit, we download pre-built frameworks
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
