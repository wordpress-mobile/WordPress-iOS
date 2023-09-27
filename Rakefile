# frozen_string_literal: true

require 'English'
require 'fileutils'
require 'tmpdir'
require 'rake/clean'
require 'yaml'
require 'digest'

RUBY_REPO_VERSION = File.read('./.ruby-version').rstrip
XCODE_WORKSPACE = 'WordPress.xcworkspace'
XCODE_SCHEME = 'WordPress'
XCODE_CONFIGURATION = 'Debug'
EXPECTED_XCODE_VERSION = File.read('.xcode-version').rstrip

PROJECT_DIR = __dir__
abort('Project directory contains one or more spaces – unable to continue.') if PROJECT_DIR.include?(' ')

SWIFTLINT_BIN = File.join(PROJECT_DIR, 'Pods', 'SwiftLint', 'swiftlint')

task default: %w[test]

desc 'Install required dependencies'
task dependencies: %w[dependencies:check assets:check]

namespace :dependencies do
  task check: %w[ruby:check bundler:check bundle:check credentials:apply pod:check lint:check]

  namespace :ruby do
    task :check do
      unless ruby_version_is_match?
        # show a warning that Ruby doesn't match .ruby-version
        puts '====================================================================================='
        puts 'Warning: Your local Ruby version doesn\'t match .ruby-version'
        puts ''
        puts ".ruby-version:\t#{RUBY_REPO_VERSION}"
        puts "Your Ruby:\t#{RUBY_VERSION}"
        puts ''
        puts 'Refer to the WPiOS docs on setting the exact version with rbenv.'
        puts ''
        puts 'Press enter to continue anyway'
        puts '====================================================================================='
        $stdin.gets.strip
      end
    end

    # compare repo Ruby version to local
    def ruby_version_is_match?
      RUBY_REPO_VERSION == RUBY_VERSION
    end
  end

  namespace :bundler do
    task :check do
      Rake::Task['dependencies:bundler:install'].invoke unless command?('bundler')
    end

    task :install do
      puts 'Bundler not found in PATH, installing to vendor'
      ENV['GEM_HOME'] = File.join(PROJECT_DIR, 'vendor', 'gems')
      ENV['PATH'] = File.join(PROJECT_DIR, 'vendor', 'gems', 'bin') + ":#{ENV.fetch('PATH', nil)}"
      sh 'gem install bundler' unless command?('bundler')
    end
    CLOBBER << 'vendor/gems'
  end

  namespace :bundle do
    task :check do
      sh 'bundle check > /dev/null', verbose: false do |ok, _res|
        next if ok

        # bundle check exits with a non zero code if install is needed
        dependency_failed('Bundler')
        Rake::Task['dependencies:bundle:install'].invoke
      end
    end

    task :install do
      fold('install.bundler') do
        sh 'bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}'
      end
    end
    CLOBBER << 'vendor/bundle'
    CLOBBER << '.bundle'
  end

  namespace :credentials do
    task :apply do
      next unless Dir.exist?(File.join(Dir.home, '.mobile-secrets/.git')) || ENV.key?('CONFIGURE_ENCRYPTION_KEY')

      # The string is indented all the way to the left to avoid padding when printed in the terminal
      command = %(
FASTLANE_SKIP_UPDATE_CHECK=1 \
FASTLANE_HIDE_CHANGELOG=1 \
FASTLANE_HIDE_PLUGINS_TABLE=1 \
FASTLANE_ENV_PRINTER=1 \
FASTLANE_SKIP_ACTION_SUMMARY=1 \
FASTLANE_HIDE_TIMESTAMP=1 \
bundle exec fastlane run configure_apply force:true
      )

      sh(command)
    end
  end

  namespace :pod do
    task :check do
      unless podfile_locked? && lockfiles_match?
        dependency_failed('CocoaPods')
        Rake::Task['dependencies:pod:install'].invoke
      end
    end

    task :install do
      fold('install.cocoapods') do
        pod %w[install]
      rescue StandardError
        puts "`pod install` failed. Will attempt to update the Gutenberg-Mobile XCFramework — a common reason for the failure — then retrying…\n\n"
        Rake::Task['dependencies:pod:update_gutenberg'].invoke
        pod %w[install]
      end
    end

    task :update_gutenberg do
      pod %w[update Gutenberg]
    end

    task :clean do
      fold('clean.cocoapods') do
        FileUtils.rm_rf('Pods')
      end
    end
    CLOBBER << 'Pods'
  end

  namespace :lint do
    task :check do
      if swiftlint_needs_install
        dependency_failed('SwiftLint')
        Rake::Task['dependencies:pod:install'].invoke
      end
    end
  end
end

namespace :assets do
  task :check do
    next unless Dir['WordPress/Resources/AppImages.xcassets/AppIcon-Internal.appiconset/*.png'].empty?

    Dir.mktmpdir do |tmpdir|
      puts 'Generate internal icon set'
      if system("export PROJECT_DIR=#{Dir.pwd}/WordPress && export TEMP_DIR=#{tmpdir} && ./Scripts/BuildPhases/AddVersionToIcons.sh >/dev/null 2>&1") != 0
        system("cp #{Dir.pwd}/WordPress/Resources/AppImages.xcassets/AppIcon.appiconset/*.png #{Dir.pwd}/WordPress/Resources/AppImages.xcassets/AppIcon-Internal.appiconset/")
      end
    end
  end
end

CLOBBER << 'vendor'

desc 'Mocks'
task :mocks do
  sh "#{File.join(PROJECT_DIR, 'API-Mocks', 'scripts', 'start.sh')} 8282"
end

desc "Build #{XCODE_SCHEME}"
task build: [:dependencies] do
  xcodebuild(:build)
end

desc "Profile build #{XCODE_SCHEME}"
task buildprofile: [:dependencies] do
  ENV['verbose'] = '1'
  xcodebuild(:build, "OTHER_SWIFT_FLAGS='-Xfrontend -debug-time-compilation -Xfrontend -debug-time-expression-type-checking'")
end

task timed_build: [:clean] do
  require 'benchmark'
  time = Benchmark.measure do
    Rake::Task['build'].invoke
  end
  puts "CPU Time: #{time.total}"
  puts "Wall Time: #{time.real}"
end

desc 'Run test suite'
task test: [:dependencies] do
  xcodebuild(:build, :test)
end

desc 'Remove any temporary products'
task :clean do
  xcodebuild(:clean)
end

desc 'Checks the source for style errors'
task lint: %w[dependencies:lint:check] do
  swiftlint %w[lint --quiet]
end

namespace :lint do
  desc 'Automatically corrects style errors where possible'
  task autocorrect: %w[dependencies:lint:check] do
    swiftlint %w[lint --autocorrect --quiet]
  end
end

namespace :git do
  hooks = %w[pre-commit post-checkout post-merge]

  desc 'Install git hooks'
  task :install_hooks do
    hooks.each do |hook|
      target = hook_target(hook)
      source = hook_source(hook)
      backup = hook_backup(hook)

      next if File.symlink?(target) && (File.readlink(target) == source)
      next if File.file?(target) && File.identical?(target, source)

      if File.exist?(target)
        puts "Existing hook for #{hook}. Creating backup at #{target} -> #{backup}"
        FileUtils.mv(target, backup, force: true)
      end
      FileUtils.ln_s(source, target)
      puts "Installed #{hook} hook"
    end
  end

  desc 'Uninstall git hooks'
  task :uninstall_hooks do
    hooks.each do |hook|
      target = hook_target(hook)
      source = hook_source(hook)
      backup = hook_backup(hook)

      next unless File.symlink?(target) && (File.readlink(target) == source)

      puts "Removing hook for #{hook}"
      File.unlink(target)
      if File.exist?(backup)
        puts "Restoring hook for #{hook} from backup"
        FileUtils.mv(backup, target)
      end
    end
  end

  def hook_target(hook)
    hooks_dir = `git rev-parse --git-path hooks`.chomp
    File.join(hooks_dir, hook)
  end

  def hook_source(hook)
    File.absolute_path(File.join(PROJECT_DIR, 'Scripts', 'hooks', hook))
  end

  def hook_backup(hook)
    "#{hook_target(hook)}.bak"
  end
end

namespace :git do
  task pre_commit: %(dependencies:lint:check) do
    swiftlint %w[lint --quiet --strict]
  rescue StandardError
    exit $CHILD_STATUS.exitstatus
  end

  task :post_merge do
    check_dependencies_hook
  end

  task :post_checkout do
    check_dependencies_hook
  end
end

desc 'Open the project in Xcode'
task xcode: [:dependencies] do
  sh "open #{XCODE_WORKSPACE}"
end

desc 'Install and configure WordPress iOS and its dependencies - External Contributors'
namespace :init do
  task oss: %w[
    install:xcode:check
    dependencies
    install:tools:check_oss
    install:lint:check
    credentials:setup
  ]

  desc 'Install and configure WordPress iOS and its dependencies - Automattic Developers'
  task developer: %w[
    install:xcode:check
    dependencies
    install:tools:check_developer
    install:lint:check
    credentials:setup
    gpg_key:setup
  ]
end

namespace :install do
  namespace :xcode do
    task check: %w[xcode_app:check xcode_select:check]

    # xcode_app namespace checks for the existance of xcode on developer's machine,
    # checks to make sure that developer is using the correct version per the CI specs
    # and confirms developer has xcode-select command line tools, if not installs them
    namespace :xcode_app do
      # check the existance of xcode, and compare version to CI specs
      task :check do
        puts 'Checking for system for Xcode'
        if xcode_installed?
          puts 'Xcode installed'
        else
          # if xcode is not installed, prompt user to install and terminate rake
          puts 'Xcode not Found!'
          puts ''
          puts '====================================================================================='
          puts 'Developing for WordPressiOS requires Xcode.'
          puts 'Please install Xcode before setting up WordPressiOS'
          puts 'https://apps.apple.com/app/xcode/id497799835?mt=12'
          abort('')
        end

        puts 'Checking CI recommended installed Xcode version'

        unless xcode_version_is_correct?
          # if xcode is the wrong version, prompt user to install the correct version and terminate rake
          puts 'Not recommended version of Xcode installed'
          puts "It is recommended to use Xcode version #{EXPECTED_XCODE_VERSION}"
          puts 'Please press enter to continue'
          $stdin.gets.strip
          next
        end
      end

      # Check if Xcode is installed
      def xcode_installed?
        system 'xcodebuild -version', %i[out err] => File::NULL
      end

      # compare xcode version to expected CI spec version
      def xcode_version_is_correct?
        if xcode_version == EXPECTED_XCODE_VERSION
          puts 'Correct version of Xcode installed'
          true
        else
          false
        end
      end

      def xcode_version
        puts 'Checking installed version of Xcode'
        version = `xcodebuild -version`

        version.split[1]
      end
    end

    # Xcode-select command line tools must be installed to update dependencies
    # Xcode_select checks the existence of xcode-select on developer's machine, installs if not found
    namespace :xcode_select do
      task :check do
        puts 'Checking system for Xcode-select'
        if command?('xcode-select')
          puts 'Xcode-select installed'
        else
          Rake::Task['install:xcode:xcode_select:install'].invoke
        end
      end

      task :install do
        puts 'Installing xcode select'
        sh 'xcode-select --install'
      end
    end
  end

  # Tools namespace deals with installing developer and OSS tools required to work on WPiOS
  namespace :tools do
    task check_oss: %w[homebrew:check addons:check_oss]
    task check_developer: %w[homebrew:check addons:check_developer]

    # Check for Homebrew and install if missing
    namespace :homebrew do
      task :check do
        puts 'Checking system for Homebrew'
        if command?('brew')
          puts 'Homebrew installed'
        else
          Rake::Task['install:tools:homebrew:prompt'].invoke
        end
      end

      # prompt developer that Homebrew is required to install required tools and confirm they want to install
      # allow to bail out of install script if they developer declines to install homebrew
      task :prompt do
        puts '====================================================================================='
        puts 'Setting WordPress iOS requires installing Homebrew to manage installing some tools'
        puts 'For more information on Homebrew check out https://brew.sh/'
        puts 'Do you want to continue with the WordPress iOS setup and install Homebrew?'
        puts "Press 'Y' to install Homebrew.  Press 'N' for exit"
        puts '====================================================================================='

        if display_prompt_response == true
          Rake::Task['install:tools:homebrew:install'].invoke
        else
          abort('')
        end
      end

      task :install do
        command = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
        sh command
      end
    end

    # Install required tools to work with WPiOS
    namespace :addons do
      # NOTE: hash key = default installed directory on device
      # hash value = brew install location
      oss_tools = { 'convert' => 'imagemagick',
                    'gs' => 'ghostscript' }
      developer_tools = { 'convert' => 'imagemagick',
                          'gs' => 'ghostscript',
                          'sentry-cli' => 'getsentry/tools/sentry-cli',
                          'gpg' => 'gpg',
                          'git-crypt' => 'git-crypt' }

      # Check for tool, install if not installed
      task :check_oss do
        tool_check(oss_tools)
      end

      task :check_developer do
        tool_check(developer_tools)
      end

      # check if the developer tool is present in the machine, if not install
      def tool_check(hash)
        hash.each do |key, value|
          puts "Checking system for #{key}"
          if command?(key)
            puts "#{key} found"
          else
            tool_install(value)
          end
        end
      end

      # install selected developer tool
      def tool_install(tool)
        puts "#{tool} not found.  Installing #{tool}"
        sh "brew install #{tool}"
      end
    end
  end

  namespace :lint do
    task :check do
      unless git_initialized?
        puts 'Initializing git repository'
        sh 'git init', verbose: false
      end

      Rake::Task['git:install_hooks'].invoke
    end

    def git_initialized?
      sh 'git rev-parse --is-inside-work-tree > /dev/null 2>&1', verbose: false
    end
  end
end

# Credentials deals with the setting up the developer's WPCOM API app ID and app Secret
namespace :credentials do
  task setup: %w[credentials:prompt credentials:set_app_secrets]

  task :prompt do
    puts ''
    puts '====================================================================================='
    puts 'To be able to log into the WordPress app while developing you will need to setup API credentials'
    puts 'To do this follow these steps'
    puts ''
    puts ''
    puts ''
    puts '====================================================================================='

    puts "1. Go to https://wordpress.com/start/user and create a WordPress.com account (if you don't already have one)."
    prompt_for_continue('Once you have created your account,')

    puts '====================================================================================='
    puts '2. Now register an API application at https://developer.wordpress.com/apps/.'
    prompt_for_continue('Once you have registered your API App,')

    puts '====================================================================================='
    puts '3. Make sure to set "Redirect URLs"= https://localhost and "Type" = Native and click "Create" then "Update".'
    prompt_for_continue('Once you have set the redirect url and type,')

    puts '====================================================================================='
    prompt_for_continue('Lastly, keep your Client ID and App Secret on hand for the next steps,')
  end

  def prompt_for_continue(prompt)
    puts "#{prompt} Please press enter to continue"
    $stdin.gets.strip
  end

  # user given app id and secret and create a new wpcom_app_credentials file
  task :set_app_secrets do
    set_app_secrets(client_id, client_secret)
  end

  def client_id
    $stdout.puts 'Please enter your Client ID'
    $stdin.gets.strip
  end

  def client_secret
    $stdout.puts 'Please enter your Client Secret'
    $stdin.gets.strip
  end

  # Duplicate the example file and add the new app secret and app id
  def set_app_secrets(id, secret)
    puts 'Writing App ID and App Secret to secrets file'

    replaced_text = File.read('WordPress/Credentials/Secrets-example.swift')
                        .gsub('let client = "0"', "let client=\"#{id}\"")
                        .gsub('let secret = "your-secret-here"', "let secret=\"#{secret}\"")

    File.open('WordPress/Credentials/Secrets.swift', 'w') do |file|
      file.puts replaced_text
    end
  end
end

namespace :gpg_key do
  # automate the process of creatong a GPG key
  task setup: %w[gpg_key:check gpg_key:prompt gpg_key:finish]

  # confirm that GPG tools is installed
  task :check do
    puts 'Checking system for GPG Tools'
    if command?('gpg')
      puts 'GPG Tools found'
    else
      Rake::Task['gpg_key:install'].invoke
    end
  end

  # install GPG Tools
  task :install do
    puts 'GPG Tools not found.  Installing GPG Tools'
    sh 'brew install gpg'
  end

  # Ask developer if they need to create a new key.
  # If yes, begin process of creating key, if no move on
  task :prompt do
    next unless create_gpg_key?

    if create_default_key?
      display_default_config_helpers
      Rake::Task['gpg_key:generate_default'].invoke
    else
      Rake::Task['gpg_key:generate_custom'].invoke
    end
  end

  # Generate new GPG key
  task :generate_custom do
    puts ''
    puts 'Begin Generating Custom GPG Keys'
    puts '====================================================================================='

    sh 'gpg --full-generate-key', verbose: false
  end

  # Generate new default GPG key
  task :generate_default do
    puts ''
    puts 'Begin Generating Default GPG Keys'
    puts '====================================================================================='

    sh 'gpg --generate-key', verbose: false
  end

  # prompt developer to send GPG key to Platform
  task :finish do
    puts '====================================================================================='
    puts 'Key Generation Complete!'
    puts 'Please send your GPG public key to Platform 9-3/4'
    puts 'You can contact them in the Slack channel #platform9'
    puts '====================================================================================='
  end

  # ask user if they want to create a key, loop till given a valid answer
  def create_gpg_key?
    puts '====================================================================================='
    puts 'To access production credentials for the WordPress app you will need to a GPG Key'
    puts 'Do you need to generate a new GPG Key?'
    puts "Press 'Y' to create a new key.  Press 'N' to skip"

    display_prompt_response
  end

  # ask user if they want to create a key,  loop till given a valid answer
  def create_default_key?
    puts '====================================================================================='
    puts 'You can choose to setup with a default or custom key pair setup'
    puts 'Default setup - Type: RSA to RSA, RSA length: 2048, Valid for: does not expire'
    puts 'Would you like to continue with the default setup?'
    puts '====================================================================================='
    puts "Press 'Y' for Yes.  Press 'N' for custom configuration"

    display_prompt_response
  end

  # display prompt for developer to aid in setting up default key
  def display_default_config_helpers
    puts ''
    puts ''
    puts '====================================================================================='
    puts 'You will need to enter the following info to create your key'
    puts 'Please enter your real name, email address, and a password for your key when prompted'
    puts '====================================================================================='
  end
end

# prompt for a Y or N response, continue asking if other character
# return true for Y and false for N
def display_prompt_response
  response = $stdin.gets.strip.upcase
  until %w[Y N].include?(response)
    puts 'Invalid entry, please enter Y or N'
    response = $stdin.gets.strip.upcase
  end

  response == 'Y'
end

# FIXME: This used to add Travis folding formatting, but we no longer use Travis. I'm leaving it here for the moment, but I think we should remove it.
def fold(_)
  yield
end

def pod(args)
  args = %w[bundle exec pod] + args
  sh(*args)
end

def lockfile_hash
  YAML.load_file('Podfile.lock')
end

def lockfiles_match?
  File.file?('Pods/Manifest.lock') && FileUtils.compare_file('Podfile.lock', 'Pods/Manifest.lock')
end

def podfile_locked?
  podfile_checksum = Digest::SHA1.file('Podfile')
  lockfile_checksum = lockfile_hash['PODFILE CHECKSUM']

  podfile_checksum == lockfile_checksum
end

def swiftlint(args)
  args = [SWIFTLINT_BIN] + args
  sh(*args)
end

def swiftlint_needs_install
  File.exist?(SWIFTLINT_BIN) == false
end

def xcodebuild(*build_cmds)
  cmd = 'xcodebuild'
  cmd += " -destination 'platform=iOS Simulator,name=iPhone 6s'"
  cmd += ' -sdk iphonesimulator'
  cmd += " -workspace #{XCODE_WORKSPACE}"
  cmd += " -scheme #{XCODE_SCHEME}"
  cmd += " -configuration #{xcode_configuration}"
  cmd += ' '
  cmd += build_cmds.map(&:to_s).join(' ')
  cmd += ' | bundle exec xcpretty -f `bundle exec xcpretty-travis-formatter` && exit ${PIPESTATUS[0]}' unless ENV['verbose']
  sh(cmd)
end

def xcode_configuration
  ENV.fetch('XCODE_CONFIGURATION') { XCODE_CONFIGURATION }
end

def command?(command)
  system("which #{command} > /dev/null 2>&1")
end

def dependency_failed(component)
  msg = "#{component} dependencies missing or outdated. "
  if ENV['DRY_RUN']
    msg += 'Run rake dependencies to install them.'
    raise msg
  else
    msg += 'Installing...'
    puts msg
  end
end

def check_dependencies_hook
  ENV['DRY_RUN'] = '1'
  begin
    Rake::Task['dependencies'].invoke
  rescue StandardError => e
    puts e.message
    exit 1
  end
end
