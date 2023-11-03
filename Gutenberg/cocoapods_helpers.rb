# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

require 'json'
require 'yaml'

DEFAULT_GUTENBERG_LOCATION = File.join(__dir__, '..', '..', 'gutenberg-mobile')

GUTENBERG_CONFIG_PATH = File.join(__dir__, '..', 'Gutenberg', 'config.yml')

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
].freeze

def gutenberg_pod
  # We check local_gutenberg first because it should take precedence, being an override set by the user.
  return gutenberg_local_pod if should_use_local_gutenberg

  raise "Could not find config YAML at path #{GUTENBERG_CONFIG_PATH}" unless File.exist?(GUTENBERG_CONFIG_PATH)

  config = YAML.safe_load_file(GUTENBERG_CONFIG_PATH, symbolize_names: true)

  raise 'Gutenberg config does not contain expected key :ref' if config[:ref].nil?

  id = config[:ref][:tag] || config[:ref][:commit]

  # Notice there's no period at the end of the message as CocoaPods will add it.
  raise 'Neither tag nor commit to use for Gutenberg found' unless id

  pod 'Gutenberg', podspec: "https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-#{id}.podspec"
end

def gutenberg_local_pod
  options_gb = gutenberg_pod_options(name: 'Gutenberg', path: local_gutenberg_path)
  options_aztec = gutenberg_pod_options(name: 'RNTAztecView', path: "#{local_gutenberg_path}/gutenberg/packages/react-native-aztec")

  react_native_path = require_react_native_helpers!(gutenberg_path: local_gutenberg_path)

  use_react_native! path: react_native_path

  pod 'Gutenberg', options_gb
  pod 'RNTAztecView', options_aztec

  gutenberg_dependencies(options: options_gb)
end

def gutenberg_pod_options(name:, path:)
  raise "Could not find #{name} pod at #{path}. You can configure the path using the #{LOCAL_GUTENBERG_KEY} environment variable." unless File.exist?(path)

  puts "[Gutenberg] Installing pods using local #{name} version from #{path}"
  { path: }
end

def gutenberg_dependencies(options:)
  # When referencing via a tag or commit, we download pre-built frameworks.
  return if options.key?(:tag) || options.key?(:commit)

  podspec_prefix = options[:path]
  gutenberg_path = options[:path]

  raise "Unexpected Gutenberg dependencies configuration '#{options}'" if podspec_prefix.nil?

  podspec_prefix += '/third-party-podspecs'
  podspec_extension = 'podspec.json'

  computed_dependencies = DEPENDENCIES.dup

  react_native_version = react_native_version!(gutenberg_path:)
  # We need to apply a workaround for the RNReanimated library when using React Native 0.71+.
  apply_rnreanimated_workaround!(dependencies: computed_dependencies, gutenberg_path:) unless react_native_version[1] < 71

  computed_dependencies.each do |pod_name|
    pod pod_name, podspec: "#{podspec_prefix}/#{pod_name}.#{podspec_extension}"
  end
end

def apply_rnreanimated_workaround!(dependencies:, gutenberg_path:)
  # Use a custom RNReanimated version while we coordinate a fix upstream
  dependencies.delete('RNReanimated')

  # This is required to workaround an issue with RNReanimated after upgrading to version 2.17.0
  rn_node_modules = File.join(gutenberg_path, 'gutenberg', 'node_modules')
  raise "Could not find node modules at given path #{rn_node_modules}" unless File.exist? rn_node_modules

  ENV['REACT_NATIVE_NODE_MODULES_DIR'] = rn_node_modules
  puts "[Gutenberg] Set REACT_NATIVE_NODE_MODULES_DIR env var for RNReanimated to #{rn_node_modules}"

  pod 'RNReanimated', git: 'https://github.com/wordpress-mobile/react-native-reanimated', branch: 'wp-fork-2.17.0'
end

def gutenberg_post_install(installer:)
  return unless should_use_local_gutenberg

  raise "[Gutenberg] Could not find local Gutenberg at given path #{local_gutenberg_path}" unless File.exist?(local_gutenberg_path)

  react_native_path = require_react_native_helpers!(gutenberg_path: local_gutenberg_path)

  puts "[Gutenberg] Running Gutenberg post install hook (RN path: #{react_native_path})"

  # It seems like React Native prepends $PWD to the path internally in the post install hook.
  # To workaround, we make sure the path is relative to Dir.pwd
  react_native_path = Pathname.new(react_native_path).relative_path_from(Dir.pwd)

  react_native_post_install(installer, react_native_path)

  workaround_broken_search_paths
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
  react_native_path = react_native_path!(gutenberg_path:)

  require_relative File.join(react_native_path, 'scripts', 'react_native_pods')

  react_native_path
end

def react_native_path!(gutenberg_path:)
  react_native_path = File.join(gutenberg_path, 'gutenberg', 'node_modules', 'react-native')

  raise "[Gutenberg] Could not find React Native at given path #{react_native_path}" unless File.exist?(react_native_path)

  react_native_path
end

def react_native_version!(gutenberg_path:)
  react_native_path = react_native_path!(gutenberg_path:)
  package_json_path = File.join(react_native_path, 'package.json')
  package_json_content = File.read(package_json_path)
  package_json_version = JSON.parse(package_json_content)['version']

  raise "[Gutenberg] Could not find React native version at #{react_native_path}" unless package_json_version

  package_json_version.split('.').map(&:to_i)
end

# A workaround for the issue described at
# https://github.com/wordpress-mobile/WordPress-iOS/pull/21504#issuecomment-1789466523
#
# For some yet-to-discover reason, something in the process installing the pods
# using local sources messes up the LIBRARY_SEARCH_PATHS.
def workaround_broken_search_paths
  project = Xcodeproj::Project.open('WordPress/WordPress.xcodeproj')

  library_search_paths_key = 'LIBRARY_SEARCH_PATHS'
  broken_search_paths = '$(SDKROOT)/usr/lib/swift$(inherited)'

  project.targets.each do |target|
    target.build_configurations.each do |config|
      original_search_paths = config.build_settings[library_search_paths_key]

      if original_search_paths == broken_search_paths
        config.build_settings[library_search_paths_key] = ['$(SDKROOT)/usr/lib/swift', '$(inherited)']
        puts "[Gutenberg] Post-processed #{library_search_paths_key} for #{target.name} target to fix incorrect '#{broken_search_paths}' value."
      end
    end
  end
  project.save
end
