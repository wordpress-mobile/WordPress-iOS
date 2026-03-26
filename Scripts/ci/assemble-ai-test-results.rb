#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

results_dir, app, site_url, *result_files = ARGV

abort 'Usage: assemble-ai-test-results.rb RESULTS_DIR APP SITE_URL [RESULT_FILES...]' if site_url.nil?

results = result_files.map do |path|
  JSON.parse(File.read(path))
end

passed = results.count { |result| result['status'] == 'pass' }
failed = results.count { |result| result['status'] == 'fail' }

lines = [
  '# Test Results',
  '',
  "- **Date:** #{Time.now.strftime('%Y-%m-%d %H:%M')}",
  "- **App:** #{app}",
  "- **Site:** #{site_url}",
  "- **Total:** #{results.length} | **Passed:** #{passed} | **Failed:** #{failed}",
  '',
  '## Results',
  ''
]

results.each do |result|
  status_label = result.fetch('status') == 'pass' ? 'PASS' : 'FAIL'
  lines << "### #{status_label}: #{result.fetch('title')}"
  lines << "**Reason:** #{result.fetch('reason')}"
  lines << "**Test File:** #{result.fetch('test_file')}"
  lines << "**Screenshot:** #{result.fetch('screenshot')}" if result['screenshot']
  lines << ''
end

File.write(File.join(results_dir, 'results.md'), "#{lines.join("\n")}\n")
