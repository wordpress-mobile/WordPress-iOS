Pod::Spec.new do |s|
  s.name         = 'KanvasCamera'
  s.version      = '1.0.0'
  s.homepage     = 'http://google.com'
  s.source       = { :git => 'https://github.com/tumblr/kanvas-ios.git' }
  s.summary      = "Kanvas Library"
  s.authors      = ["Brandon"]


  # ...rest of attributes here

  s.vendored_frameworks = 'KanvasCamera.xcframework'
end
