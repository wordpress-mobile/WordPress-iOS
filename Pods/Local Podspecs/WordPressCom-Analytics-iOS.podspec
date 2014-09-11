Pod::Spec.new do |s|
  s.name         = "WordPressCom-Analytics-iOS"
  s.version      = "0.0.5"
  s.summary      = "Library for handling Analytics tracking in WPiOS"
  s.homepage     = "http://apps.wordpress.org"
  s.license      = { :type => "GPLv2" }
  s.author             = { "Sendhil Panchadsaram" => "sendhil@automattic.com" }
  s.social_media_url   = "http://twitter.com/WordPressiOS"
  s.platform     = :ios, "7.0"
  s.source           = { :git => "https://github.com/wordpress-mobile/WordPressCom-Analytics-iOS.git", :tag => s.version.to_s }
  s.source_files  = "WordPressCom-Analytics-iOS", "WordPressCom-Analytics-iOS/**/*.{h,m}"
  s.prefix_header_file = "WordPressCom-Analytics-iOS/WordPressCom-Analytics-iOS-Prefix.pch"
  s.requires_arc = true
end
