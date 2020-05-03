SWIFTLINT_VERSION="0.27.0"
XCODE_WORKSPACE="WordPress.xcworkspace"
XCODE_SCHEME="WordPress"
XCODE_CONFIGURATION="Debug"

require 'fileutils'
require 'tmpdir'
require 'rake/clean'
require 'yaml'
require 'digest'
require 'json'
PROJECT_DIR = File.expand_path(File.dirname(__FILE__))

task default: %w[test]

desc "Install required dependencies"
task :dependencies => %w[dependencies:check assets:check]

namespace :dependencies do
  task :check => %w[bundler:check bundle:check credentials:apply pod:check lint:check]

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
    task :check do
      sh "bundle check --path=${BUNDLE_PATH:-vendor/bundle} > /dev/null", verbose: false do |ok, res|
        next if ok
        # bundle check exits with a non zero code if install is needed
        dependency_failed("Bundler")
        Rake::Task["dependencies:bundle:install"].invoke
      end
    end

    task :install do
      fold("install.bundler") do
        sh "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}"
      end
    end
    CLOBBER << "vendor/bundle"
    CLOBBER << ".bundle"
  end

  namespace :credentials do
    task :apply do
      next unless Dir.exist?(File.join(Dir.home, '.mobile-secrets/.git')) || ENV.key?('CONFIGURE_ENCRYPTION_KEY')
      sh('FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_ENV_PRINTER=1 bundle exec fastlane run configure_apply force:true')
    end
  end

  namespace :pod do
    task :check do
      unless podfile_locked? && lockfiles_match?
        dependency_failed("CocoaPods")
        Rake::Task["dependencies:pod:install"].invoke
      end
    end

    task :install do
      fold("install.cocoapds") do
        pod %w[install]
      end
    end

    task :clean do
      fold("clean.cocoapds") do
        FileUtils.rm_rf('Pods')
      end
    end
    CLOBBER << "Pods"
  end

  namespace :lint do

    task :check do
      if swiftlint_needs_install
        dependency_failed("SwiftLint")
        Rake::Task["dependencies:lint:install"].invoke
      end
    end

    task :install do
      fold("install.swiftlint") do
        puts "Installing SwiftLint #{SWIFTLINT_VERSION} into #{swiftlint_path}"
        Dir.mktmpdir do |tmpdir|
          # Try first using a binary release
          zipfile = "#{tmpdir}/swiftlint-#{SWIFTLINT_VERSION}.zip"
          sh "curl --fail --location -o #{zipfile} https://github.com/realm/SwiftLint/releases/download/#{SWIFTLINT_VERSION}/portable_swiftlint.zip || true"
          if File.exists?(zipfile)
            extracted_dir = "#{tmpdir}/swiftlint-#{SWIFTLINT_VERSION}"
            sh "unzip #{zipfile} -d #{extracted_dir}"
            FileUtils.mkdir_p("#{swiftlint_path}/bin")
            FileUtils.cp("#{extracted_dir}/swiftlint", "#{swiftlint_path}/bin/swiftlint")
          else
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
    end
    CLOBBER << "vendor/swiftlint"
  end

end

namespace :assets do
  task :check do
    next unless Dir['WordPress/Resources/AppImages.xcassets/AppIcon-Internal.appiconset/*.png'].empty?
    Dir.mktmpdir do |tmpdir|
      puts "Generate internal icon set"
      if system("export PROJECT_DIR=#{Dir.pwd}/WordPress && export TEMP_DIR=#{tmpdir} && ./Scripts/BuildPhases/AddVersionToIcons.sh >/dev/null 2>&1") != 0
        system("cp #{Dir.pwd}/WordPress/Resources/AppImages.xcassets/AppIcon.appiconset/*.png #{Dir.pwd}/WordPress/Resources/AppImages.xcassets/AppIcon-Internal.appiconset/")
      end
    end
  end
end

CLOBBER << "vendor"

desc "Mocks"
task :mocks do
  wordpress_mocks_path = "./Pods/WordPressMocks"
  # If WordPressMocks is referenced by a local path, use that.
  unless lockfile_hash.dig("EXTERNAL SOURCES", "WordPressMocks", :path).nil?
    wordpress_mocks_path = lockfile_hash.dig("EXTERNAL SOURCES", "WordPressMocks", :path)
  end

  sh "#{wordpress_mocks_path}/scripts/start.sh 8282"
end

desc "Build #{XCODE_SCHEME}"
task :build => [:dependencies] do
  xcodebuild(:build)
end

desc "Profile build #{XCODE_SCHEME}"
task :buildprofile => [:dependencies] do
  ENV["verbose"] = "1"
  xcodebuild(:build, "OTHER_SWIFT_FLAGS='-Xfrontend -debug-time-compilation -Xfrontend -debug-time-expression-type-checking'")
end

task :timed_build => [:clean] do
  require 'benchmark'
  time = Benchmark.measure do
    Rake::Task["build"].invoke
  end
  puts "CPU Time: #{time.total}"
  puts "Wall Time: #{time.real}"
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

namespace :git do
  hooks = %w[pre-commit post-checkout post-merge]

  desc "Install git hooks"
  task :install_hooks do
    hooks.each do |hook|
      target = hook_target(hook)
      source = hook_source(hook)
      backup = hook_backup(hook)

      next if File.symlink?(target) and File.readlink(target) == source
      next if File.file?(target) and File.identical?(target, source)
      if File.exist?(target)
        puts "Existing hook for #{hook}. Creating backup at #{target} -> #{backup}"
        FileUtils.mv(target, backup, :force => true)
      end
      FileUtils.ln_s(source, target)
      puts "Installed #{hook} hook"
    end
  end

  desc "Uninstall git hooks"
  task :uninstall_hooks do
    hooks.each do |hook|
      target = hook_target(hook)
      source = hook_source(hook)
      backup = hook_backup(hook)

      next unless File.symlink?(target) and File.readlink(target) == source
      puts "Removing hook for #{hook}"
      File.unlink(target)
      if File.exist?(backup)
        puts "Restoring hook for #{hook} from backup"
        FileUtils.mv(backup, target)
      end
    end
  end

  def hook_target(hook)
    ".git/hooks/#{hook}"
  end

  def hook_source(hook)
    "../../Scripts/hooks/#{hook}"
  end

  def hook_backup(hook)
    "#{hook_target(hook)}.bak"
  end
end

namespace :git do
  task :pre_commit => %[dependencies:lint:check] do
    begin
      swiftlint %w[lint --quiet --strict]
    rescue
      exit $?.exitstatus
    end
  end

  task :post_merge do
    check_dependencies_hook
  end

  task :post_checkout do
    check_dependencies_hook
  end
end

desc "Open the project in Xcode"
task :xcode => [:dependencies] do
  sh "open #{XCODE_WORKSPACE}"
end

desc "Install and configure WordPress iOS and it's dependencies - External Contributors"
namespace :init do
task :oss => %w[
  install:xcode:check
  dependencies
  install:tools:check_oss
  git:install_hooks
  credentials:setup
]

desc "Install and configure WordPress iOS and it's dependencies - a8c Developers"
task :developer => %w[
  install:xcode:check
  dependencies
  install:tools:check_developer
  git:install_hooks
  credentials:setup
  mobile_secrets:setup
]
end

namespace :install do
  namespace :xcode do
    task :check => %w[xcode_app:check xcode_select:check]

    #xcode_app namespace checks for the existance of xcode on developer's machine,
    #checks to make sure that developer is using the correct version per the CI specs
    #and confirms developer has xcode-select command line tools, if not installs them
    namespace :xcode_app do
      #check the existance of xcode, and compare version to CI specs
      task :check do
        puts "Checking for system for XCode"
        if !xcode_installed?
          #if xcode is not installed, prompt user to install and terminate rake
          puts "Developing for WordPressiOS requires XCode."
          puts "Please install XCode before setting up WordPressiOS"
          puts "https://apps.apple.com/app/xcode/id497799835?mt=12"
          abort("")
        else
          puts "Xcode installed"
        end

        if !xcode_version_is_correct?
          #if xcode is the wrong version, prompt user to install the correct version and terminate rake
          puts "Incorrect Version of XCode"
          puts "Please install correct version: (instert ci version)"
          next
        end

        #CS-NOTE: clobber is not working.  Figure out what is going on and fix auto file cleanup
        #CLOBBER << "json.txt"
        #clean()
      end

      #export developer tools system report to json file
      def xcode_installed?
        sh "system_profiler SPDeveloperToolsDataType -json > json.txt", verbose: false
        file = File.read('json.txt')
        profile = JSON.parse(file)

        profile['SPDeveloperToolsDataType'].count > 0
      end

      #compare xcode version to expected CI spec version
      def xcode_version_is_correct?
        if get_xcode_version > get_ci_xcode_version
          puts "Correct version of XCode installed"
          return true
        end
      end

      #get xcode version from json system profiler developer tools report
      def get_xcode_version
        puts "Checking installed XCode version"
        file = File.read('json.txt')
        profile = JSON.parse(file)

        #returns version in format example: '11.4.1 (16137)'
        full_xcode_version = profile['SPDeveloperToolsDataType'][0]['spdevtools_apps']['spxcode_app']

        #remove the trailing version info
        return full_xcode_version.split(" ")[0]
      end

      def get_ci_xcode_version
        puts "Checking CI recommendded installed XCode version"
        ci_config = File.read(".circleci/config.yml")
        specs = YAML.load(ci_config)

        ci_version = specs["jobs"]["Build Tests"]["executor"]["xcode-version"]
      end
    #End namespace xcode-app
    end

    #XCode-select command line tools must be installed to update dependencies
    #xcode_select checks the existence of xcode-select on developer's machine, installs if not found
    namespace :xcode_select do
      task :check do
        puts "Checking system for XCode-select"
        unless command?("xcode-select")
          Rake::Task["xcode:xcode_select:install"].invoke
        else
          puts "XCode-select installed"
        end
      end

      task :install do
        puts "Installing xcode select"
        sh "xcode-select --install"
      end
    #End namesapce :xcode-select
    end
  #End namespace xcode
  end

  #Tools namespace deals with installing developer and OSS tools required to work on WPiOS
  namespace :tools do
    #CS_NOTE: look for a cleaner way to choos which tools to install, there is a bit of repeating that could be cleaner
    task :check_oss => %w[homebrew:check addons:check_oss]
    task :check_developer => %w[homebrew:check addons:check_developer]

    #Check for Homebrew and install if missing
    namespace :homebrew do
      task :check do
        puts "Checking system for Homebrew"
        unless command?("brew")
          Rake::Task["tools:homebrew:install"].invoke
        else
          puts "Homebrew installed"
        end
      end

      task :install do
        sh "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
      end
    #End namespace homebrew
    end

    #Install required tools to work with WPiOS
    namespace :addons do
      #NOTE: hash key = default installed directory on device
      # hash value = brew install location
      oss_tools = {"convert" => "imagemagick",
                  "gs" => "ghostscript",
      }
      developer_tools = {"convert" => "imagemagick",
                        "gs" => "ghostscript",
                        "sentry-cli" => "getsentry/tools/sentry-cli",
                        "gpg" => "gpg",
                        "git-crypt" => "git-crypt",
      }

      #Check for tool, install if not installed
      #C-NOTE: the tool_check method does two things, check and install
      #would it be better to make one method check and one method install, for clarity?
      task :check_oss do
        tool_check(oss_tools)
      end

      task :check_developer do
        tool_check(developer_tools)
      end

      #check machine for if the developer tool is present, if not install
      def tool_check(hash)
        hash.each do |key, value|
          puts "Checking system for #{key}"
          unless command?(key)
            tool_install(value)
          else
            puts "#{key} found"
          end
        end
      end

      ##install selected developer tool
      def tool_install(tool)
        puts "#{tool} not found.  Installing #{tool}"
        puts "brew install #{tool}"
      end

    #End namespace addons
    end

  #End namespace Tools
  end

end #End namespace install

#Credentials deals with the setting up the developer's WPCOM API app ID and app Secret
namespace :credentials do
  task :setup => %w[credentials:set_app_secrets]

    #user given app id and secret and create a new wpcom_app_credentials file
    task :set_app_secrets do
      create_secrets_file()
      set_app_secrets(get_app_id, get_app_secret)
      #CS-NOTE:Figure out removal of temp file
    end

    def get_app_id
      STDOUT.puts "Please enter your App id"
      app_id = STDIN.gets.strip
    end

    def get_app_secret
      STDOUT.puts "Please enter your App Secret"
      app_secret = STDIN.gets.strip
    end

    #create temporary secrets file from example file
    def create_secrets_file
      sh "cp WordPress/Credentials/wpcom_app_credentials-example .configure-files/temp_wpcom_app_credentials", verbose: false
    end

    #create a new wpcom_app_credentials file combining the app secret and app id
    def set_app_secrets(id, secret)
      puts "Creating credentials file"
      new_file = File.new(".configure-files/wpcom_app_credentials", "w")
      File.open(".configure-files/temp_wpcom_app_credentials") do |file|
        file.each_line do |line|
          string = line.to_s()
          if string.include? "WPCOM_APP_ID="
            new_file.puts("WPCOM_APP_ID=#{id}")
          elsif string.include? "WPCOM_APP_SECRET="
            new_file.puts("WPCOM_APP_SECRET=#{secret}")
          else
            new_file.write(line)
          end
        end
      end
    end

#End namesapce Credentials
end

#Mobile secrets prompts the developer to add their SSH keys to the mobile secrets
#repository and ping Platform with their GPG public key
namespace :mobile_secrets do
  task :setup => %w[mobile_secrets:ssh_secret mobile_secrets:gpg_public_key]

  task :ssh_secret do
    ##prompt developer to enter their ssh https://code.a8c.com/settings/user/[your user name]/page/ssh/
    puts ""
    puts ""
    puts ""
    puts "====================================================================================="
    puts "====================================================================================="
    puts "Access to Mobile Secrets Repository:"
    puts "To get started, you will need to enter your SSH public key at:"
    puts "https://code.a8c.com/settings/user/[your user name]/page/ssh/"
    puts "-------------------------------------------------------------------------------------"
    ##prompt developer to amend their secrets
    puts "Once there enter something like this:"
    puts "Host code.a8c.com"
    puts "  Hostname code.a8c.com"
    puts "  ProxyCommand ssh -W %h:%p -N -l your-matticspace-username proxy.automattic.com"
    puts "  User git"
    puts " "

    puts "====================================================================================="
    puts "====================================================================================="
    STDOUT.puts "Once complete please press enter to continue"
    complete = STDIN.gets.strip
  end

  task :gpg_public_key do
    #Prompt developer to ping platform with key
    puts "====================================================================================="
    puts "====================================================================================="
    puts "Please send your GPG public key to Platform 9-3/4"
    puts "You can contact them in the Slack channel #platform9"
    puts "If you do not have a GPG public key, please go to https://gpgtools.org/ to create one"
    puts "====================================================================================="
    puts "====================================================================================="
  end
#End namespace mobile_secrets
end

#Secrets unlocks access to the mobile secrets repository and decrypts them
desc "Unlock mobile secrets repository"
task :secrets_unlock => %w[secrets_unlock:default]

namespace :secrets_unlock do
  task default: %w[secrets_unlock:check_git_crypt secrets_unlock:create_secrets_file secrets_unlock:git_crypt_unlock]

  task :check_git_crypt do
    puts 'secrets'
    #Check and make sure git-crypt is installed, if not install it.
    unless command?("git-crypt")
      tool_install("git-crypt")
    end
  end

  #Clone mobile secrets key
  task :create_secrets_file do
    sh "git clone ssh://git@code.a8c.com/diffusion/18/mobile-secrets.git ~/.mobile-secrets"
    sh "cd ~/.mobile-secrets"
  end

  #Unlock mobile secrets key
  task :git_crypt_unlock do
    unless command?("git-crypt")
      sh "git-crypt unlock"
    end
  end
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

def lockfile_hash
  YAML.load(File.read("Podfile.lock"))
end

def lockfiles_match?
  File.file?('Pods/Manifest.lock') && FileUtils.compare_file('Podfile.lock', 'Pods/Manifest.lock')
end

def podfile_locked?
  podfile_checksum = Digest::SHA1.file("Podfile")
  lockfile_checksum = lockfile_hash["PODFILE CHECKSUM"]

  podfile_checksum == lockfile_checksum
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
  installed_version = `"#{swiftlint_bin}" version`.chomp
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
  cmd += " | bundle exec xcpretty -f `bundle exec xcpretty-travis-formatter` && exit ${PIPESTATUS[0]}" unless ENV['verbose']
  sh(cmd)
end

def xcode_configuration
  ENV['XCODE_CONFIGURATION'] || XCODE_CONFIGURATION
end

def command?(command)
  system("which #{command} > /dev/null 2>&1")
end
def dependency_failed(component)
  msg = "#{component} dependencies missing or outdated. "
  if ENV['DRY_RUN']
    msg += "Run rake dependencies to install them."
    fail msg
  else
    msg += "Installing..."
    puts msg
  end
end

def check_dependencies_hook
  ENV['DRY_RUN'] = "1"
  begin
    Rake::Task['dependencies'].invoke
  rescue Exception => e
    puts e.message
    exit 1
  end
end
