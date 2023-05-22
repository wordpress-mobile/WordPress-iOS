# frozen_string_literal: true

require 'pathname'
require_relative './version'

# A spec for a pod whose only job is delegating the XCFrameworks integration to CocoaPods.
#
# This is used to fetch Gutenberg builds that come from commits instead of tags.
# Builds from tags are "official" and stable, so we distribute them via GitHub we'll eventually publish them on CocoaPods.
# The artifacts for builds from commits are instead only stored on an Automattic's server.
Pod::Spec.new do |s|
  raise 'Could not find Gutenberg version configuration' if GUTENBERG_CONFIG.nil?

  gutenberg_version = GUTENBERG_CONFIG[:commit]

  raise "Trying to fetch Gutenberg XCFramework from Automattic's distribution server with invalid version '#{GUTENBERG_CONFIG}'" if gutenberg_version.nil?

  xcframework_storage_url = 'https://d2twmm2nzpx3bg.cloudfront.net'

  xcframework_archive_url = "#{xcframework_storage_url}/Gutenberg-#{gutenberg_version}.tar.gz"

  require 'net/http'

  raise "Could not find file at URL #{xcframework_archive_url}" unless Net::HTTP.get_response(URI(xcframework_archive_url)).code == '200'

  s.name = 'Gutenberg'
  s.version = '1.0.0' # The value here is irrelevant, but required
  s.summary = 'A spec to help integrating the Gutenberg XCFramework'
  s.homepage = 'https://apps.wordpress.com'
  s.license = { type: 'GPL', file: File.join(__dir__, '..', 'LICENSE') }
  s.authors = 'Automattic'

  s.ios.deployment_target = '13.0' # TODO: Read from common source
  s.swift_version = '5.0' # TODO: read from common source

  s.requires_arc = true # TODO: Can this be omitted?

  # Tell CocoaPods where to download the XCFramework(s) archive with `source` and what to use from its decompressed contents with `vendored_frameworks`.
  #
  # See https://github.com/CocoaPods/CocoaPods/issues/10288
  #
  # I can't get this to work out of the box, so instead of using a URL we take
  # care of downloading and unarchiving and use a local source.
  #
  # s.source = { http: xcframework_archive_url }
  s.source = { http: "file://#{GUTENBERG_DOWNLOADS_DIRECTORY}/Gutenberg-#{gutenberg_version}.tar.gz" }
  s.vendored_frameworks = [
    'Aztec.xcframework',
    'Gutenberg.xcframework',
    'React.xcframework',
    'RNTAztecView.xcframework',
    'yoga.xcframework'
  ].map do |f|
    # This needs to be a relative path to the local extraction location and account for the archive folder structure.
    Pathname.new("#{GUTENBERG_ARCHIVE_DIRECTORY}/Frameworks/#{f}")
            .relative_path_from(__dir__).to_s
  end
end
