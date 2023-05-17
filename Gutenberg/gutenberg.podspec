# frozen_string_literal: true

# FIXME: This spec generates lots of warnings because of what looks like garbage files being in the XCFrameworks
#
# Example:
#
# - NOTE  | [iOS] xcodebuild:  note: note: while processing while processing /Users/gio/Developer/a8c/gutenberg-mobile/Johannes/DerivedData/ModuleCache.noindex/29X134XZYNZEH/Foundation-TDMNIE45PJWJ.pcm/Users/gio/Developer/a8c/gutenberg-mobile/Johannes/DerivedData/ModuleCache.noindex/2HX40YJG1I01Y/Foundation-TDMNIE45PJWJ.pcm

require_relative './version'

raise 'Could not find Gutenberg version configuration' if GUTENBERG_CONFIG.nil?

version = GUTENBERG_CONFIG[:commit]

raise "Trying to fetch Gutenberg XCFramework from Automattic's distribution server with invalid version '#{GUTENBERG_CONFIG}'" if version.nil?

XCFRAMEWORK_STORAGE_URL = 'https://d2twmm2nzpx3bg.cloudfront.net/'

# A spec for a pod whose only job is delegating the XCFrameworks integration to CocoaPods.
#
# This is used to fetch Gutenberg builds that come from commits instead of tags.
# Builds from tags are "official" and stable, so we distribute them via GitHub we'll eventually publish them on CocoaPods.
# The artifacts for builds from commits are instead only stored on an Automattic's server.
Pod::Spec.new do |s|
  s.name = 'Gutenberg'
  s.version = '1.0.0' # The value here is irrelevant, but required
  s.summary = 'A spec to help integrating the Gutenberg XCFramework'
  s.homepage = 'https://apps.wordpress.com'
  s.license = File.join(__dir__, '..', 'LICENSE')
  s.authors = 'Automattic'

  s.ios.deployment_target = '13.0' # TODO: Read from common source
  s.swift_version = '5.0' # TODO: read from common source

  s.requires_arc = true # TODO: Can this be omitted?

  # Tell CocoaPods where to download the XCFramework(s) ZIP with `source` and what to use from the ZIP's content with `vendored_frameworks`.
  #
  # See https://github.com/CocoaPods/CocoaPods/issues/10288
  s.source = { http: "#{XCFRAMEWORK_STORAGE_URL}/Gutenberg-#{version}.zip", type: 'zip' }
  s.ios.vendored_frameworks = [
    'Aztec.xcframework',
    'Gutenberg.xcframework',
    'RNTAztecView.xcframework',
    'React.xcframework',
    'yoga.xcframework'
  ]
end
