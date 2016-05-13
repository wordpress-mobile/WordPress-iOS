require 'fileutils'
require 'rake/clean'

task default: %w[test]

desc "Install required dependencies"
task :dependencies => %w[dependencies:check]

namespace :dependencies do
  task :check => %w[bundle:check pod:check]

  namespace :bundle do
    lockfile = 'Gemfile.lock'
    manifest = 'vendor/bundle/Manifest.lock'

    task :check do
      unless check_manifest(lockfile, manifest)
        Rake::Task["dependencies:bundle:install"].invoke
      end
    end

    task :install do
      sh "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}"
      FileUtils.cp(lockfile, manifest)
    end
    CLOBBER << "vendor/bundle"
  end

  namespace :pod do
    task :check do
      lockfile = 'Podfile.lock'
      manifest = 'Pods/Manifest.lock'
      unless check_manifest(lockfile, manifest)
        Rake::Task["dependencies:pods:install"].invoke
      end
    end

    task :install do
      fold("install.cocoapds") do
        pod %w[repo update]
        pod %w[install]
      end
    end
    CLOBBER << "Pods"
  end
end


desc "Build and test"
task :test => [:dependencies] do
  sh './Scripts/build.sh'
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
