Pod::Spec.new do |s|
  s.name         = "WordPressCom-Stats-iOS"
  s.version      = "0.0.3"
  s.summary      = "Reusable component for displaying WordPress.com site stats in an iOS application."

  s.description  = <<-DESC
                   Reusable component for displaying WordPress.com site stats in an iOS application

                   * Requires an OAuth2 Token for WordPress.com generated currently by WordPress-Mobile/WordPress-iOS
                   DESC

  s.homepage     = "http://make.wordpress.org/mobile"
  s.license      = "GPLv2"
  s.author             = { "Aaron Douglas" => "astralbodies@gmail.com" }
  # s.authors            = { "Aaron Douglas" => "astralbodies@gmail.com" }
  s.social_media_url   = "http://twitter.com/WordPressiOS"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/wordpress-mobile/WordPressCom-Stats-iOS.git", :tag => "0.0.3" }
  s.source_files  = "WordPressCom-Stats-iOS", "WordPressCom-Stats-iOS/**/*.{h,m}"
  s.exclude_files = "WordPressCom-Stats-iOS/Exclude"
  s.prefix_header_file = "WordPressCom-Stats-iOS/WordPressCom-Stats-iOS-Prefix.pch"
  s.requires_arc = true

  s.dependency 'AFNetworking',	'~> 2.3.1'
  s.dependency 'CocoaLumberjack', '~> 1.8.1'
  s.dependency 'WordPress-iOS-Shared', '~> 0.0.1'
  s.dependency 'NSObject-SafeExpectations', '0.0.2'
end
