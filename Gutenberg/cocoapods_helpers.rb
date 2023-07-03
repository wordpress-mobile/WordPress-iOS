# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

require_relative './version'

DEFAULT_GUTENBERG_LOCATION = File.join(__dir__, '..', '..', 'gutenberg-mobile')

LOCAL_GUTENBERG_KEY = 'LOCAL_GUTENBERG'

# Note that the pods in this array might seem unused if you look for
# `import` statements in this codebase. However, make sure to also check
# whether they are used in the gutenberg-mobile and Gutenberg projects.
#
# See https://github.com/wordpress-mobile/gutenberg-mobile/issues/5025
DEPENDENCIES = %w[
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
  React-jsc
].freeze

def gutenberg_pod(config: GUTENBERG_CONFIG)
  options = config

  # We check local_gutenberg first because it should take precedence, being an override set by the user.
  if should_use_local_gutenberg
    options = { path: local_gutenberg_path }

    raise "Could not find Gutenberg pod at #{options[:path]}. You can configure the path using the #{LOCAL_GUTENBERG_KEY} environment variable." unless File.exist?(options[:path])

    puts "[Gutenberg] Installing pods using local Gutenberg version from #{local_gutenberg_path}"

    pod 'Gutenberg', options
    pod 'RNTAztecView', options

    gutenberg_dependencies(options: options)
  else
    id = options[:tag] || options[:commit]

    # Notice there's no period at the end of the message as CocoaPods will add it.
    raise 'Neither tag nor commit to use for Gutenberg found' unless id

    pod 'Gutenberg', podspec: "https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-#{id}.podspec"
  end
end

def gutenberg_dependencies(options:)
  # When referencing via a tag or commit, we download pre-built frameworks.
  return if options.key?(:tag) || options.key?(:commit)

  podspec_prefix = options[:path]

  raise "Unexpected Gutenberg dependencies configuration '#{options}'" if podspec_prefix.nil?

  podspec_prefix += '/third-party-podspecs'
  podspec_extension = 'podspec.json'

  # FBReactNativeSpec needs special treatment because of react-native-codegen code generation
  pod 'FBReactNativeSpec', podspec: "#{podspec_prefix}/FBReactNativeSpec/FBReactNativeSpec.#{podspec_extension}"

  DEPENDENCIES.each do |pod_name|
    pod pod_name, podspec: "#{podspec_prefix}/#{pod_name}.#{podspec_extension}"
  end
end

def gutenberg_post_install(installer:)
  return unless should_use_local_gutenberg

  raise "[Gutenberg] Could not find local Gutenberg at given path #{local_gutenberg_path}" unless File.exist?(local_gutenberg_path)

  react_native_path = File.join(local_gutenberg_path, 'gutenberg', 'node_modules', 'react-native')

  raise "[Gutenberg] Could not find React Native at given path #{react_native_path}" unless File.exist?(react_native_path)

  require_relative File.join(react_native_path, 'scripts', 'react_native_pods')

  puts '[Gutenberg] Running Gunberg post install hook'

  react_native_post_install(installer, react_native_path)
end

private

def should_use_local_gutenberg
  value = ENV.fetch(LOCAL_GUTENBERG_KEY, nil)

  return false if value.nil?

  value
end

def local_gutenberg_path
  local_gutenberg = ENV.fetch(LOCAL_GUTENBERG_KEY, nil)

  return nil if local_gutenberg.nil?

  return local_gutenberg if File.exist?(local_gutenberg)

  DEFAULT_GUTENBERG_LOCATION
end
