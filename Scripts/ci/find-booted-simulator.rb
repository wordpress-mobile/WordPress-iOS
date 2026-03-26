#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

requested_name = ARGV[0].to_s
wait_seconds = ARGV[1].to_f
poll_interval = ARGV[2].to_f
poll_interval = 1.0 if poll_interval <= 0
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + [wait_seconds, 0].max

loop do
  output, status = Open3.capture2('xcrun', 'simctl', 'list', 'devices', 'booted', '-j')
  exit 1 unless status.success?

  data = JSON.parse(output)
  devices = data.fetch('devices', {}).each_value.flat_map do |list|
    list.select { |device| device['state'] == 'Booted' }
  end

  device = if requested_name.empty?
             devices.first
           else
             devices.find { |entry| entry['name'] == requested_name }
           end

  if device
    print(device['udid'])
    exit 0
  end

  break if wait_seconds <= 0 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

  sleep poll_interval
end

exit 1
