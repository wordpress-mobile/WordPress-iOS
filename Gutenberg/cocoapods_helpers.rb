# frozen_string_literal: true

# Helpers and configurations for integrating Gutenberg in Jetpack and WordPress via CocoaPods.

require 'archive/tar/minitar'
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
    # Also notice the path is relative from Dir.pwd, that is, the location where the script running this code is invoked.
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

def gutenberg_pre_install_hook
  # At this time, we only support XCFramework-commit builds
  commit = GUTENBERG_CONFIG[:commit]
  if commit.nil?
    puts 'Skipping Gutenberg XCFramework download because no commit was given.'
    return
  end

  url = archive_url(commit: commit)
  archive_download_path = File.join(GUTENBERG_DOWNLOADS_DIRECTORY, File.basename(url))

  if File.exist?(archive_download_path)
    puts "Skipping download for #{url} because archive already exists at #{archive_download_path}."
  else
    download(archive_url: url, destination: archive_download_path)
  end

  extract(
    archive: archive_download_path,
    destination: GUTENBERG_ARCHIVE_DIRECTORY
  )
end

private

# rubocop:disable Metrics/AbcSize
def download(archive_url:, destination:)
  puts "Attempting to download #{archive_url} to #{destination}..."

  FileUtils.mkdir_p(File.dirname(destination))

  # Perform HTTP HEAD request to retrieve file size
  uri = URI.parse(archive_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.head(uri.path)

  # Check if the response is successful and contains Content-Length header
  content_length_key = 'Content-Length'
  raise "Failed to retrieve file information: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess) && response.key?(content_length_key)

  file_size = response[content_length_key].to_i

  # Check file size
  raise 'File size is 0. Aborting download.' if file_size.zero?

  puts "File size: #{(file_size / (1024.0 * 1024.0)).round(2)} MB"

  progress_bar = ProgressBar.create(title: 'Downloading Gutenberg XCFrameworks archive', total: file_size, format: '%t |%B| %p%%')

  http.request_get(uri.path) do |archive_response|
    File.open(destination, 'wb') do |file|
      archive_response.read_body do |chunk|
        file.write(chunk)
        progress_bar.progress += chunk.length
      end
    end
  end

  progress_bar.finish

  puts 'Finished downloading.'
end
# rubocop:enable Metrics/AbcSize

def extract(archive:, destination:)
  FileUtils.rm_rf(destination)
  FileUtils.mkdir_p(destination)

  puts "Extracting #{archive} to #{destination}..."

  Zlib::GzipReader.open(archive) do |gzip_file|
    Archive::Tar::Minitar.unpack(gzip_file, destination)
  end

  puts 'Finished extracting.'
end
