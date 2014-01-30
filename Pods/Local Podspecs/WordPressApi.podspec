Pod::Spec.new do |s|
  s.name         = "WordPressApi"
  s.version      = "0.0.1"
  s.summary      = "A simple Objective-C client to publish posts on the WordPress platform"
  s.homepage     = "https://github.com/koke/WordPressApi"
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = "WordPress"
  s.source       = { :git => "https://github.com/koke/WordPressApi.git" }
  s.source_files = 'WordPressApi'
  s.requires_arc = true
  s.dependency 'AFNetworking', '>= 1.0'
  s.dependency 'wpxmlrpc', '~> 0.1'

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.frameworks = 'Foundation', 'UIKit', 'Security'

  s.documentation = {
    :appledoc => [ 'AppledocSettings.plist' ]
  }
end
