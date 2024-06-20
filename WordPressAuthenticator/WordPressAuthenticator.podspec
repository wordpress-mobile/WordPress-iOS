# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name          = 'WordPressAuthenticator'
  s.version       = '9.0.8'

  s.summary       = 'WordPressAuthenticator implements an easy and elegant way to authenticate your WordPress Apps.'
  s.description   = <<-DESC
                    This framework encapsulates everything required to display the Authentication UI
                    and perform authentication against WordPress.com and WordPress.org sites.

                    Plus: WordPress.com *signup* is supported.
  DESC

  s.homepage      = 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS'
  s.license       = { type: 'GPLv2', file: '../LICENSE' }
  s.author        = { 'The WordPress Mobile Team' => 'mobile@wordpress.org' }

  s.platform      = :ios, '13.0'
  s.swift_version = '5.0'

  s.source        = { git: 'https://github.com/wordpress-mobile/WordPressAuthenticator-iOS.git',
                      tag: s.version.to_s }
  s.source_files  = 'Sources/**/*.{h,m,swift}'
  s.private_header_files = 'Sources/Private/*.h'
  s.resource_bundles = {
    WordPressAuthenticatorResources: [
      'Sources/Resources/Assets.xcassets',
      'Sources/Resources/SupportedEmailClients/*.plist',
      'Sources/Resources/Animations/*.json',
      'Sources/**/*.{storyboard,xib}'
    ]
  }
  s.header_dir = 'WordPressAuthenticator'

  s.dependency 'NSURL+IDN', '0.4'
  s.dependency 'SVProgressHUD', '~> 2.2.5'
  s.dependency 'Gridicons', '~> 1.0'

  # Use a loose restriction that allows both production and beta versions, up to the next major version.
  # If you want to update which of these is used, specify it in the host app.
  s.dependency 'WordPressUI', '~> 1.7-beta'
  s.dependency 'WordPressKit', '~> 17.0'
  s.dependency 'WordPressShared', '~> 2.1-beta'

  s.test_spec 'Tests' do |test_spec|
    test_spec.dependency 'OCMock', '~> 3.4'
    test_spec.dependency 'Expecta', '1.0.6'
    test_spec.dependency 'Specta', '1.0.7'

    test_spec.source_files = 'Tests/**/*.{h,m,swift}'
  end
end
