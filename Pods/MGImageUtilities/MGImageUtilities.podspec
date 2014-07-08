Pod::Spec.new do |s|
  s.name         = "MGImageUtilities"
  s.version      = "0.0.1"
  s.summary      = "Useful UIImage categories for iPhone/iPad developers."
  s.homepage     = "http://mattgemmell.com/2010/07/05/mgimageutilities/"
  s.license      = 'BSD'
  s.author       = { "Matt Gemmell" => "matt@mattgemmell.com" }
  s.source       = { :git => "https://github.com/wordpress-mobile/MGImageUtilities.git", :branch => 'gifsupport' }
  s.platform     = :ios
  s.source_files = 'Classes/UIImage*.{h,m}'
end