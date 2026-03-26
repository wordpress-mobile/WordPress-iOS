#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

result_file, title, test_file, status, reason, screenshot = ARGV

abort 'Usage: write-ai-test-result.rb RESULT_FILE TITLE TEST_FILE STATUS REASON [SCREENSHOT]' if reason.nil?
abort "Status must be 'pass' or 'fail'" unless %w[pass fail].include?(status)

FileUtils.mkdir_p(File.dirname(result_file))

payload = {
  'status' => status,
  'title' => title,
  'test_file' => test_file,
  'reason' => reason,
  'screenshot' => screenshot.to_s.empty? ? nil : screenshot,
  'updated_at' => Time.now.utc.iso8601
}

File.write(result_file, "#{JSON.pretty_generate(payload)}\n")
