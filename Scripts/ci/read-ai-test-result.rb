#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

result_file = ARGV[0]
key = ARGV[1]

abort 'Usage: read-ai-test-result.rb RESULT_FILE KEY' if result_file.nil? || key.nil?

data = JSON.parse(File.read(result_file))
value = data[key]
print(value.nil? ? '' : value.to_s)
