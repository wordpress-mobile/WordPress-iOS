Pod::Spec.new do |s|

  s.name         = "iOSPasscodeLock"
  s.version      = "1.0"
  s.summary      = "A library to implement Passcode Lock protection to iOS apps."
  s.homepage     = "https://github.com/bakyelli/iOS-PasscodeLock"

  s.license      = { :type => 'GPL', :file => 'LICENSE' }

  s.authors       = { "Basar Akyelli" => "bakyelli@gmail.com" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/bakyelli/iOS-PasscodeLock.git", 
                     :tag => "1.0" }

  s.source_files  = 'iOSPasscodeLock/*.{h,m}'

  s.requires_arc = true
  
end
