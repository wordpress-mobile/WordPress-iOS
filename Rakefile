# frozen_string_literal: true

PROJECT_DIR = __dir__
abort('Project directory contains one or more spaces – unable to continue.') if PROJECT_DIR.include?(' ')

desc 'Checks the source for style errors. Lints the whole project, or only the given paths: rake lint[path1,path2]'
task :lint, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact)
end

desc 'Automatically fix linting errors where possible. Fixes the whole project, or only the given paths: rake lintfix[path1,path2]'
task :lintfix, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact, extra_args: ['--fix'])
end

desc 'Set up your own WordPress.com API credentials - External Contributors'
namespace :init do
  task oss: %w[credentials:setup]
end

# Credentials deals with the setting up the developer's WPCOM API app ID and app Secret
namespace :credentials do
  desc 'Set up your own WordPress.com API credentials'
  task :setup do
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

    set_app_secrets(client_id, client_secret)
  end

  def prompt_for_continue(prompt)
    puts "#{prompt} Please press enter to continue"
    $stdin.gets.strip
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
