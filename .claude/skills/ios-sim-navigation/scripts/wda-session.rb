#!/usr/bin/env ruby
# Create a WDA session bound to an app, optionally launching it with caller-
# supplied arguments and environment variables. The session ID is printed to
# stdout and must be passed explicitly to every navigation command.
#
# Usage:
#   wda-session.rb --port PORT --bundle ID [--arg VALUE ...]
#                  [--env KEY=VALUE ...] [--wait-quiescence]
#
# Exit codes: 0 on success, 2 on WDA or usage error.

require "json"
require "net/http"
require "optparse"
require "uri"

port = nil
bundle = nil
args = []
env = {}
wait_quiescence = false

parser = OptionParser.new do |opts|
  opts.banner = "Usage: wda-session.rb --port PORT --bundle ID [--arg VALUE ...] [--env KEY=VALUE ...] [--wait-quiescence]"
  opts.on("--port PORT", Integer, "WDA port (required)") { |value| port = value }
  opts.on("--bundle ID", "App bundle ID (required)") { |value| bundle = value }
  opts.on("--arg VALUE", "Repeatable launch-argument token") { |value| args << value }
  opts.on("--env KEY=VALUE", "Repeatable launch environment entry") do |value|
    key, env_value = value.split("=", 2)
    if key.nil? || key.empty? || env_value.nil?
      warn "error: --env expects KEY=VALUE, got: #{value}"
      exit 2
    end
    env[key] = env_value
  end
  opts.on("--wait-quiescence", "Wait for app quiescence after launch") { wait_quiescence = true }
end
parser.parse!

if port.nil? || !(1..65_535).cover?(port) || bundle.nil? || bundle.empty?
  warn parser.help
  exit 2
end

always_match = {
  "bundleId" => bundle,
  "arguments" => args,
  "shouldWaitForQuiescence" => wait_quiescence
}
always_match["environment"] = env unless env.empty?

uri = URI("http://localhost:#{port}/session")
request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
request.body = JSON.dump({ "capabilities" => { "alwaysMatch" => always_match } })

begin
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
rescue Errno::ECONNREFUSED, Errno::ECONNRESET
  warn "error: WDA not reachable on port #{port}; start it first"
  exit 2
end

unless response.code.to_i.between?(200, 299)
  warn "error: session create failed: HTTP #{response.code}: #{response.body}"
  exit 2
end

session_id = JSON.parse(response.body).dig("value", "sessionId") rescue nil
unless session_id
  warn "error: no sessionId in response: #{response.body}"
  exit 2
end

puts session_id
