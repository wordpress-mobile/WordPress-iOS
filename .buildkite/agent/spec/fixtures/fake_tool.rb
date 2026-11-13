# frozen_string_literal: true

require 'json'

name = File.basename($PROGRAM_NAME)
File.open(ENV.fetch('TRACE'), 'a') { |file| file.puts JSON.generate([name, *ARGV]) }
case name
when 'xcodebuild'
  puts 'fake xcodebuild'
  exit(ARGV.include?('-version') ? 0 : ENV.fetch('BUILD_STATUS', '0').to_i)
when 'sleep'
  exit 0
end
case ARGV.first(2)
when %w[simctl list]
  puts ENV.fetch('SIMULATORS')
when %w[simctl create]
  puts ENV.fetch('CREATED_UDID')
  exit ENV.fetch('CREATE_STATUS', '0').to_i
when %w[simctl boot]
  exit ENV.fetch('BOOT_STATUS', '0').to_i
else
  File.write(ARGV.fetch(4), 'fake png') if ARGV[1] == 'io' && ARGV[3] == 'screenshot'
end
