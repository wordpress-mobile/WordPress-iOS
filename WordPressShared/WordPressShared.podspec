Pod::Spec.new do |s|
  s.name          = "WordPressShared"
  s.version       = "1.0.0"
  s.summary       = "Shared components used in building the WordPress iOS apps and other library components."

  s.description   = <<-DESC
                    Shared components used in building the WordPress iOS apps and other library components.

                    This is the first step required to build WordPress-iOS with UI components.
                    DESC

  s.homepage      = "http://apps.wordpress.com"
  s.license       = "GPLv2"
  s.author        = { "Aaron Douglas" => "astralbodies@gmail.com" }
  s.platform      = :ios, "10.0"
  s.source        = { :git => "https://github.com/wordpress-mobile/WordPress-iOS-Shared.git", :tag => s.version.to_s }
  s.source_files  = 'WordPressShared/**/*.{h,m,swift}'
  s.resources     = [ 'WordPressShared/Resources/*.{ttf,otf}' ]
  s.exclude_files = 'WordPressShared/Exclude'
  s.requires_arc  = true
  s.header_dir    = 'WordPressShared'

  s.dependency 'CocoaLumberjack', '~> 3.4.1'
  s.dependency 'FormatterKit/TimeIntervalFormatter', '1.8.2'
  s.dependency 'NSObject-SafeExpectations', '0.0.2'
  s.dependency 'UIDeviceIdentifier', '~> 0.4'
end

