# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

TAG_MODE = { tag: 'v1.94.0' }
LOCAL_MODE = { path: '../../gutenberg-mobile' }
COMMIT_MODE = { commit: '' }

MODE = TAG_MODE

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

def gutenberg_pod(mode: MODE)
  options = mode.dup

  local_gutenberg = ENV.fetch('LOCAL_GUTENBERG', nil)
  if local_gutenberg
    options = { path: local_gutenberg.include?('/') ? local_gutenberg : LOCAL_MODE[:path] }
  else
    options[:git] = 'https://github.com/wordpress-mobile/gutenberg-mobile.git'
    options[:submodules] = true
  end

  pod 'Gutenberg', options
  pod 'RNTAztecView', options

  gutenberg_dependencies(options: options)
end

def gutenberg_dependencies(options:)
  if options[:path]
    podspec_prefix = options[:path]
  else
    tag_or_commit = options[:tag] || options[:commit]
    podspec_prefix = "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{tag_or_commit}"
  end

  # FBReactNativeSpec needs special treatment because of react-native-codegen code generation
  pod 'FBReactNativeSpec', podspec: "#{podspec_prefix}/third-party-podspecs/FBReactNativeSpec/FBReactNativeSpec.podspec.json"

  DEPENDENCIES.each do |pod_name|
    pod pod_name, podspec: "#{podspec_prefix}/third-party-podspecs/#{pod_name}.podspec.json"
  end
end
