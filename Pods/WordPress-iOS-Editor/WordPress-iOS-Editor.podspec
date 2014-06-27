Pod::Spec.new do |s|
  s.name             = "WordPress-iOS-Editor"
  s.version          = "0.1.4"
  s.summary      = "Reusable component rich text editor for WordPress.com in an iOS application."

  s.description  = <<-DESC
                   Reusable component for displaying the WordPress.com post editor in an iOS application
                   DESC

  s.homepage     = "http://make.wordpress.org/mobile"
  s.license      = 'GPLv2'
  s.author       = { "Matt Bumgardner" => "matt.bumgardner@automattic.com" }
  s.source       = { :git => "https://github.com/wordpress-mobile/WordPress-iOS-Editor.git", :tag => "0.1.4" }
  s.social_media_url = 'http://twitter.com/WordPressiOS'
  s.platform     = :ios, '7.0'
  s.source_files = 'Classes'  
  s.resources = ["Assets/*.png"]
  s.prefix_header_file = "Classes/WordPress-iOS-Editor-Prefix.pch"
  s.exclude_files = 'Classes/exclude'
  s.requires_arc = true
  s.dependency 'CocoaLumberjack', '~>1.8.1'  
  s.dependency 'UIAlertView+Blocks'
  s.dependency 'WordPress-iOS-Shared', '~>0.0.2'
end
