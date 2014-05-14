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
  s.dependency 'AFNetworking', '2.2.3'
  s.dependency 'wpxmlrpc', '~> 0.1'

  s.platform = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.frameworks = 'Foundation', 'UIKit', 'Security'

  s.documentation = {
    :appledoc => [ 'AppledocSettings.plist' ]
  }
end
