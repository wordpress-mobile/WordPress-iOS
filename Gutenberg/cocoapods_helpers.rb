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

    react_native_path = require_react_native_helpers!(gutenberg_path: local_gutenberg_path)

    use_react_native! path: react_native_path

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

  computed_dependencies = DEPENDENCIES.dup

  # Use a custom RNReanimated version while we coordinate a fix upstream
  computed_dependencies.delete('RNReanimated')
  pod 'RNReanimated', git: 'https://github.com/wordpress-mobile/react-native-reanimated', branch: 'mokagio/fix-custom-node_modules-bypass-multiple-versions-check-2.17.0'

  computed_dependencies.each do |pod_name|
    pod pod_name, podspec: "#{podspec_prefix}/#{pod_name}.#{podspec_extension}"
  end
end

def gutenberg_pre_install
  return unless should_use_local_gutenberg

  raise "[Gutenberg] Could not find local Gutenberg at given path #{local_gutenberg_path}" unless File.exist?(local_gutenberg_path)

  # This is required to workaround an issue with RNReanimated after upgrading to version 2.17.0
  rn_node_modules = File.join(local_gutenberg_path, 'node_modules')

  raise "Could not find node modules at given path #{rn_node_modules}" unless File.exist? rn_node_modules

  ENV['REACT_NATIVE_NODE_MODULES_DIR'] = rn_node_modules

  puts "[Gutenberg] Set REACT_NATIVE_NODE_MODULES_DIR env var for RNReanimated to #{rn_node_modules}"
end

def gutenberg_post_install(installer:)
  return unless should_use_local_gutenberg

  raise "[Gutenberg] Could not find local Gutenberg at given path #{local_gutenberg_path}" unless File.exist?(local_gutenberg_path)

  react_native_path = require_react_native_helpers!(gutenberg_path: local_gutenberg_path)

  puts "[Gutenberg] Running Gunberg post install hook (RN path: #{react_native_path})"

  # It seems like React Native prepends $PWD to the path internally in the post install hook.
  # When using an absolute path, we get this error, notice the duplicated "/Users/gio/Developer/a8c/wpios":
  #
  #   [!] An error occurred while processing the post-install hook of the Podfile.
  #
  #   No such file or directory @ rb_sysopen - /Users/gio/Developer/a8c/wpios/Users/gio/Developer/a8c/wpios/Gutenberg/../../gutenberg-mobile/gutenberg/node_modules/react-native/package.json
  #
  # To workaround, we make sure the path is relative to Dir.pwd
  react_native_path = Pathname.new(react_native_path).relative_path_from(Dir.pwd)

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

def require_react_native_helpers!(gutenberg_path:)
  react_native_path = react_native_path!(gutenberg_path: gutenberg_path)

  require_relative File.join(react_native_path, 'scripts', 'react_native_pods')

  react_native_path
end

def react_native_path!(gutenberg_path:)
  react_native_path = File.join(gutenberg_path, 'gutenberg', 'node_modules', 'react-native')

  raise "[Gutenberg] Could not find React Native at given path #{react_native_path}" unless File.exist?(react_native_path)

  react_native_path
end
