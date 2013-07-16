# -*- encoding: utf-8 -*-
require File.expand_path('../motion/lib/motion-tidy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Francis Chong"]
  gem.email         = ["francis@ignition.hk"]
  gem.description   = "libtidy wrapper for rubymotion"
  gem.summary       = "libtidy wrapper for rubymotion"
  gem.homepage      = "https://github.com/siuying/CTidy"

  gem.files         = `git ls-files motion`.split($\)
  gem.name          = "motion-tidy"
  gem.require_paths = ["motion/lib"]
  gem.version       = Tidy::VERSION
  gem.add_dependency 'motion-cocoapods', '>= 1.1.0'
end
