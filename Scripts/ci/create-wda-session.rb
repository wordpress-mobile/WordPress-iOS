#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

port = Integer(ARGV[0] || 8100)
uri = URI("http://localhost:#{port}/session")
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/json'
request.body = JSON.generate(capabilities: { alwaysMatch: {} })

response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 30, open_timeout: 10) do |http|
  http.request(request)
end

exit 1 unless response.code.to_i.between?(200, 499)

parsed = JSON.parse(response.body)
session_id = parsed.dig('value', 'sessionId') || parsed['sessionId']
print(session_id.to_s)
