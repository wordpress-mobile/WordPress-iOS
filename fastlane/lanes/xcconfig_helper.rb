# frozen_string_literal: true

require 'xcodeproj'

# Reads build settings out of `.xcconfig` files, so that values the Xcode project already declares don't
# need to be duplicated in fastlane's environment.
module XcconfigHelper
  module_function

  class Error < StandardError
  end

  # Returns the value of `key`, resolving `#include`s and raising unless it's a non-empty string.
  #
  # @param path [String] Path to the `.xcconfig` file to read.
  # @param key [String] Name of the build setting, e.g. `DEVELOPMENT_TEAM`.
  #
  def fetch(path:, key:)
    raise Error, "No such xcconfig file: #{path}" unless File.file?(path)

    # `to_hash` resolves `#include`d files, unlike `attributes`, which only sees the ones set in `path`.
    value = Xcodeproj::Config.new(path).to_hash[key]

    raise Error, "Build setting '#{key}' not found in #{path}" if value.nil?
    raise Error, "Build setting '#{key}' is empty in #{path}" if value.empty?

    value
  end
end
