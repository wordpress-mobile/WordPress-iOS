# frozen_string_literal: true

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
  s.license = { type: 'GPL', file: '../LICENSE' }
  s.authors = 'Automattic'

  s.ios.deployment_target = '13.0' # TODO: Read from common source
  s.swift_version = '5.0' # TODO: read from common source

  s.requires_arc = true # TODO: Can this be omitted?

  # Tell CocoaPods where to download the XCFramework(s) archive with `source` and what to use from its decompressed contents with `vendored_frameworks`.
  #
  # See https://github.com/CocoaPods/CocoaPods/issues/10288
  xcframework_archive_url = 'https://d2twmm2nzpx3bg.cloudfront.net/Gutenberg-8c5e0248b8c109eee664ac6b4ed7dd3ee7f3d380.tar.gz'
  s.source = { http: xcframework_archive_url }
  s.vendored_frameworks = [
    'Aztec.xcframework',
    'Gutenberg.xcframework',
    'React.xcframework',
    'RNTAztecView.xcframework',
    'yoga.xcframework'
  ].map do |f|
    # This needs to be a relative path to the local extraction location and account for the archive folder structure.
    # Pathname.new("#{GUTENBERG_ARCHIVE_DIRECTORY}/Frameworks/#{f}").relative_path_from(__dir__).to_s
    ".gutenberg/frameworks/Frameworks/#{f}"
  end

  # Download the archive after this spec has been downloaded
  #
  # Warning: If the pod is installed with the :path option this command will not be executed.
  s.prepare_command = <<-CMD
    echo '...'
    set +x
    pwd
    mkdir -p .gutenberg/downloads
    mkdir -p .gutenberg/frameworks
    curl --progress-bar #{xcframework_archive_url} -o .gutenberg/downloads/Gutenberg.xcframework.tar.gz
    tar -xzf .gutenberg/downloads/Gutenberg.xcframework.tar.gz --directory=.gutenberg/frameworks
    ls
  CMD
end
