SWIFTLINT_VERSION="0.10.0"
XCODE_WORKSPACE="WordPress.xcworkspace"
XCODE_SCHEME="WordPress"
XCODE_CONFIGURATION="Debug"

require 'fileutils'
require 'tmpdir'
require 'rake/clean'
PROJECT_DIR = File.expand_path(File.dirname(__FILE__))

task default: %w[test]

desc "Install required dependencies"
task :dependencies => %w[dependencies:check]

namespace :dependencies do
  task :check => %w[bundler:check bundle:check pod:check lint:check]

  namespace :bundler do
    task :check do
      unless command?("bundler")
        Rake::Task["dependencies:bundler:install"].invoke
      end
    end

    task :install do
      puts "Bundler not found in PATH, installing to vendor"
      ENV['GEM_HOME'] = File.join(PROJECT_DIR, 'vendor', 'gems')
      ENV['PATH'] = File.join(PROJECT_DIR, 'vendor', 'gems', 'bin') + ":#{ENV['PATH']}"
      sh "gem install bundler" unless command?("bundler")
    end
    CLOBBER << "vendor/gems"
  end

  namespace :bundle do
    lockfile = 'Gemfile.lock'
    manifest = 'vendor/bundle/Manifest.lock'

    task :check do
      unless check_manifest(lockfile, manifest) and File.exist?('.bundle/config')
        Rake::Task["dependencies:bundle:install"].invoke
      end
    end

    task :install do
      fold("install.bundler") do
        sh "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}"
        FileUtils.cp(lockfile, manifest)
      end
    end
    CLOBBER << "vendor/bundle"
    CLOBBER << ".bundle"
  end

  namespace :pod do
    task :check do
      lockfile = 'Podfile.lock'
      manifest = 'Pods/Manifest.lock'
      unless check_manifest(lockfile, manifest)
        Rake::Task["dependencies:pod:install"].invoke
      end
    end

    task :install do
      fold("install.cocoapds") do
        pod %w[repo update --silent]
        pod %w[install]
      end
    end
    CLOBBER << "Pods"
  end

  namespace :lint do

    task :check do
      if swiftlint_needs_install
        Rake::Task["dependencies:lint:install"].invoke
      end
    end

    task :install do
      fold("install.swiftlint") do
        puts "Installing SwiftLint #{SWIFTLINT_VERSION} into #{swiftlint_path}"
        Dir.mktmpdir do |tmpdir|
          sh "git clone --quiet https://github.com/realm/SwiftLint.git #{tmpdir}"
          Dir.chdir(tmpdir) do
            sh "git checkout --quiet #{SWIFTLINT_VERSION}"
            sh "git submodule --quiet update --init --recursive"
            FileUtils.remove_entry_secure(swiftlint_path) if Dir.exist?(swiftlint_path)
            FileUtils.mkdir_p(swiftlint_path)
            sh "make prefix_install PREFIX='#{swiftlint_path}'"
          end
        end
      end
    end
    CLOBBER << "vendor/swiftlint"
  end

end

CLOBBER << "vendor"

desc "Build #{XCODE_SCHEME}"
task :build => [:dependencies] do
  xcodebuild(:build)
end

desc "Run test suite"
task :test => [:dependencies] do
  xcodebuild(:build, :test)
end

desc "Remove any temporary products"
task :clean do
  xcodebuild(:clean)
end

desc "Checks the source for style errors"
task :lint => %w[dependencies:lint:check] do
  swiftlint %w[lint --quiet]
end

namespace :lint do
  desc "Automatically corrects style errors where possible"
  task :autocorrect => %w[dependencies:lint:check] do
    swiftlint %w[autocorrect]
  end
end

desc "Open the project in Xcode"
task :xcode => [:dependencies] do
  sh "open #{XCODE_WORKSPACE}"
end

def check_manifest(file, manifest)
  return false unless File.exist?(file)
  return false unless File.exist?(manifest)
  FileUtils.identical?(file, manifest)
end

def fold(label, &block)
  puts "travis_fold:start:#{label}" if is_travis?
  yield
  puts "travis_fold:end:#{label}" if is_travis?
end

def is_travis?
  return ENV["TRAVIS"] != nil
end

def pod(args)
  args = %w[bundle exec pod] + args
  sh(*args)
end

def swiftlint_path
    "#{PROJECT_DIR}/vendor/swiftlint"
end

def swiftlint(args)
  args = [swiftlint_bin] + args
  sh(*args)
end

def swiftlint_bin
    "#{swiftlint_path}/bin/swiftlint"
end

def swiftlint_needs_install
  return true unless File.exist?(swiftlint_bin)
  installed_version = `#{swiftlint_bin} version`.chomp
  return (installed_version != SWIFTLINT_VERSION)
end

def xcodebuild(*build_cmds)
  cmd = "xcodebuild"
  cmd += " -destination 'platform=iOS Simulator,name=iPhone 6s'"
  cmd += " -sdk iphonesimulator"
  cmd += " -workspace #{XCODE_WORKSPACE}"
  cmd += " -scheme #{XCODE_SCHEME}"
  cmd += " -configuration #{xcode_configuration}"
  cmd += " "
  cmd += build_cmds.map(&:to_s).join(" ")
  cmd += " | xcpretty -f `bundle exec xcpretty-travis-formatter`" unless ENV['verbose']
  sh(cmd)
end

def xcode_configuration
  ENV['XCODE_CONFIGURATION'] || XCODE_CONFIGURATION
end

def command?(command)
  system("which #{command} > /dev/null 2>&1")
end
