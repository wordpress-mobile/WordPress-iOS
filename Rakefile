# frozen_string_literal: true

require 'fileutils'
require 'rake/clean'

XCODE_WORKSPACE = 'WordPress.xcworkspace'
PROJECT_DIR = __dir__
abort('Project directory contains one or more spaces – unable to continue.') if PROJECT_DIR.include?(' ')

CLOBBER << 'vendor'

desc 'Checks the source for style errors. Lints the whole project, or only the given paths: rake lint[path1,path2]'
task :lint, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact)
end

desc 'Automatically fix linting errors where possible. Fixes the whole project, or only the given paths: rake lintfix[path1,path2]'
task :lintfix, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact, extra_args: ['--fix'])
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
  task :pre_commit do
    puts 'No precommit hook configured to run at this time.'
  end

  # Kept so hooks installed by `rake git:install_hooks` keep working. They used to
  # re-run `rake dependencies`; the app schemes' build pre-action does that now.
  task :post_merge
  task :post_checkout
end

desc 'Open the project in Xcode'
task :xcode do
  sh "open #{XCODE_WORKSPACE}"
end

desc 'Set up your own WordPress.com API credentials - External Contributors'
namespace :init do
  task oss: %w[credentials:setup]

  desc 'Set up your own WordPress.com API credentials - Automattic Developers'
  task developer: %w[credentials:setup]
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

# See Scripts/swiftlint.sh, which the SwiftLint build phase also calls.
def run_swiftlint(paths: [], extra_args: [])
  sh(File.join(PROJECT_DIR, 'Scripts', 'swiftlint.sh'), *extra_args, *paths.map { |path| File.expand_path(path) })
end
