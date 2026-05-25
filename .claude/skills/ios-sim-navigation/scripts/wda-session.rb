#!/usr/bin/env ruby
# wda-session.rb — Create a WDA session bound to an app, launching it with
# launch arguments, and persist the session so tap.rb reuses it.
#
# Why this exists: creating a WDA session relaunches the target app by default
# (forceAppLaunch defaults to YES), which discards any arguments passed via
# `simctl launch -key value` (they belong to the original process). This script
# instead lets WDA launch the app with the arguments, so the process WDA drives
# has them, and persists the session so tap.rb reuses it (no further relaunch).
#
# Usage:
#   wda-session.rb --bundle com.automattic.jetpack \
#     --arg -ui-test-site-url --arg https://example.com \
#     --arg -ui-test-site-user --arg demo \
#     --arg -ui-test-site-pass --arg secret
#
# Each --arg contributes one token to launchArguments, in order. A
# `-key value` pair is two --arg values, exactly as you'd pass them to
# `simctl launch`.
#
# Options:
#   --bundle ID        Required. App bundle id to launch and bind to.
#   --arg VALUE        Repeatable. One launch-argument token (order preserved).
#   --port PORT        WDA port (default: 8100, or $WDA_PORT).
#   --wait-quiescence  Wait for app quiescence after launch (default: off;
#                      a spinning login screen can keep an app from going
#                      quiescent, so off is both faster and more reliable).
#
# Exit codes: 0 on success (prints the session id), 2 on WDA/usage error.

require "net/http"
require "json"
require "uri"
require "optparse"

port = (ENV["WDA_PORT"] || 8100).to_i
bundle = nil
args = []
wait_quiescence = false

parser = OptionParser.new do |opts|
  opts.banner = "Usage: wda-session.rb --bundle ID [--arg VALUE ...] [--port PORT] [--wait-quiescence]"
  opts.on("--bundle ID") { |v| bundle = v }
  opts.on("--arg VALUE") { |v| args << v }
  opts.on("--port PORT", Integer) { |v| port = v }
  opts.on("--wait-quiescence") { wait_quiescence = true }
end
parser.parse!

unless bundle
  $stderr.puts parser.help
  exit 2
end

caps = {
  "alwaysMatch" => {
    "bundleId" => bundle,
    "arguments" => args,
    "shouldWaitForQuiescence" => wait_quiescence
  }
}

uri = URI("http://localhost:#{port}/session")
req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
req.body = JSON.dump({ "capabilities" => caps })

begin
  res = Net::HTTP.start(uri.host, uri.port) { |h| h.request(req) }
rescue Errno::ECONNREFUSED
  $stderr.puts "error: WDA not reachable on port #{port}. Run wda-start.rb first."
  exit 2
end

unless res.code.to_i.between?(200, 299)
  $stderr.puts "error: session create failed: HTTP #{res.code}: #{res.body}"
  exit 2
end

sid = JSON.parse(res.body).dig("value", "sessionId") rescue nil
unless sid
  $stderr.puts "error: no sessionId in response: #{res.body}"
  exit 2
end

# Same format and path tap.rb reads, so it reuses this session.
File.write("/tmp/wda-#{port}.session", JSON.dump({ session_id: sid, port: port }))
puts sid
