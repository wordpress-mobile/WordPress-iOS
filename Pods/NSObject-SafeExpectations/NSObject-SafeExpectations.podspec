Pod::Spec.new do |s|
  s.name         = "NSObject-SafeExpectations"
  s.version      = "0.0.2"
  s.summary      = "No more crashes getting unexpected values from a NSDictionary."
  s.homepage     = "https://github.com/wordpress-mobile/NSObject-SafeExpectations"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "Jorge Bernal" => "jbernal@gmail.com", "Aaron Douglas" => "astralbodies@gmail.com" }
  s.source       = { :git => "https://github.com/wordpress-mobile/NSObject-SafeExpectations.git", :tag => "0.0.2" }
  s.source_files = '*.{h,m}'
  s.platform     = :ios, "7.0"
  s.requires_arc = true
end
