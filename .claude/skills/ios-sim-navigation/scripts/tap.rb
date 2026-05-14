#!/usr/bin/env ruby
# tap.rb — Tap an element on the iOS Simulator via WebDriverAgent.
#
# One Ruby invocation = one Claude turn. Handles session creation
# (bound to the foreground app's bundle id, which is required for
# pointer events to dispatch), element lookup, the actual tap, and
# (optionally) waiting for the next expected element to appear.
#
# Usage:
#   tap.rb aid <accessibility-id>
#   tap.rb text "<visible label>"      # matches accessibility id OR label
#   tap.rb at <x>,<y>                  # raw coordinates
#
# Options:
#   --wait-aid AID    After the tap, poll for an element with this aid.
#                     Exits 0 once found, 1 if --timeout elapses.
#   --wait-text TXT   Same, but matches by visible label OR aid.
#   --timeout SEC     Max wait, default 3 seconds. Bump up for known-slow
#                     transitions (network calls, large list loads).
#   --port PORT       WDA port (default: 8100, or $WDA_PORT).
#
# Use --wait-aid / --wait-text instead of `tap; sleep N; curl source`
# whenever you can name the element you expect afterwards. It's one
# turn instead of three, ~250ms cadence instead of fixed sleep, and
# returns ~200 B instead of a 25 KB tree dump.
#
# Exit codes:
#   0  tap dispatched (and wait condition met if specified)
#   1  tap target not found, OR wait target didn't appear in time
#   2  WDA error / usage error

require "net/http"
require "json"
require "uri"
require "optparse"

PORT = (ENV["WDA_PORT"] || 8100).to_i
SESSION_FILE = "/tmp/wda-#{PORT}.session"

def base_url(port = PORT)
  "http://localhost:#{port}"
end

def http_get(path, port = PORT)
  uri = URI("#{base_url(port)}#{path}")
  res = Net::HTTP.start(uri.host, uri.port) { |h| h.request(Net::HTTP::Get.new(uri)) }
  [res.code.to_i, res.body]
rescue Errno::ECONNREFUSED
  raise "WDA not reachable on port #{port}. Run wda-start.rb first."
end

def http_post(path, body, port = PORT)
  uri = URI("#{base_url(port)}#{path}")
  req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
  req.body = JSON.dump(body)
  res = Net::HTTP.start(uri.host, uri.port) { |h| h.request(req) }
  [res.code.to_i, res.body]
rescue Errno::ECONNREFUSED
  raise "WDA not reachable on port #{port}. Run wda-start.rb first."
end

def active_bundle(port = PORT)
  code, body = http_get("/wda/activeAppInfo", port)
  return nil unless code == 200
  JSON.parse(body).dig("value", "bundleId")
rescue
  nil
end

def session_id(port = PORT)
  if File.exist?(SESSION_FILE)
    sid = JSON.parse(File.read(SESSION_FILE))["session_id"] rescue nil
    if sid
      code, _ = http_get("/session/#{sid}", port)
      return sid if code == 200
    end
  end

  caps = { "alwaysMatch" => {} }
  bundle = active_bundle(port)
  caps["alwaysMatch"]["bundleId"] = bundle if bundle

  code, body = http_post("/session", { "capabilities" => caps }, port)
  raise "session create failed: HTTP #{code}: #{body}" unless code.between?(200, 299)
  sid = JSON.parse(body).dig("value", "sessionId")
  raise "no sessionId in response: #{body}" unless sid
  File.write(SESSION_FILE, JSON.dump({ session_id: sid, port: port }))
  sid
end

def locator_for(strategy, value)
  case strategy
  when "aid"
    ["accessibility id", value]
  when "text"
    escaped = value.gsub("'", "\\\\'")
    ["predicate string", "label == '#{escaped}' OR name == '#{escaped}'"]
  else
    raise "unknown strategy: #{strategy}"
  end
end

def find_first(strategy, value, port = PORT)
  using, val = locator_for(strategy, value)
  sid = session_id(port)
  code, body = http_post("/session/#{sid}/elements", { "using" => using, "value" => val }, port)
  return nil if code == 404
  raise "find failed: HTTP #{code}: #{body}" unless code.between?(200, 299)
  matches = JSON.parse(body)["value"] || []
  return nil if matches.empty?
  m = matches.first
  m["ELEMENT"] || m["element-6066-11e4-a52e-4f735466cecf"] || m.values.first
end

# Poll /elements every interval_s until target appears or deadline passes.
# Returns the elapsed time on success, nil on timeout.
def wait_for(strategy, value, timeout, port = PORT)
  using, val = locator_for(strategy, value)
  sid = session_id(port)
  deadline = Time.now + timeout
  start = Time.now
  loop do
    code, body = http_post("/session/#{sid}/elements", { "using" => using, "value" => val }, port)
    if code.between?(200, 299)
      matches = (JSON.parse(body)["value"] rescue nil) || []
      return Time.now - start unless matches.empty?
    end
    return nil if Time.now >= deadline
    sleep 0.25
  end
end

def element_center(eid, port = PORT)
  sid = session_id(port)
  code, body = http_get("/session/#{sid}/element/#{eid}/rect", port)
  raise "rect failed: HTTP #{code}: #{body}" unless code.between?(200, 299)
  rect = JSON.parse(body)["value"]
  [rect["x"] + rect["width"] / 2.0, rect["y"] + rect["height"] / 2.0]
end

def tap_at(x, y, port = PORT)
  sid = session_id(port)
  body = {
    "actions" => [{
      "type" => "pointer", "id" => "finger1",
      "parameters" => { "pointerType" => "touch" },
      "actions" => [
        { "type" => "pointerMove", "duration" => 0, "x" => x, "y" => y },
        { "type" => "pointerDown" },
        { "type" => "pointerUp" }
      ]
    }]
  }
  code, resp = http_post("/session/#{sid}/actions", body, port)
  raise "tap failed: HTTP #{code}: #{resp}" unless code.between?(200, 299)
end

port = PORT
wait_strategy = nil
wait_value = nil
wait_timeout = 3.0

parser = OptionParser.new do |opts|
  opts.banner = "Usage: tap.rb <aid|text|at> <value> [--wait-aid AID|--wait-text TXT] [--timeout SEC] [--port PORT]"
  opts.on("--wait-aid AID") { |v| wait_strategy = "aid"; wait_value = v }
  opts.on("--wait-text TXT") { |v| wait_strategy = "text"; wait_value = v }
  opts.on("--timeout SEC", Float) { |v| wait_timeout = v }
  opts.on("--port PORT", Integer) { |v| port = v }
end
parser.parse!

if ARGV.size < 2
  $stderr.puts parser.help
  exit 2
end

strategy = ARGV[0]
value = ARGV[1..].join(" ")

begin
  case strategy
  when "at"
    x, y = value.split(",").map { |s| Float(s) }
    tap_at(x, y, port)
    puts "tap ok at #{x.round(1)},#{y.round(1)}"
  when "aid", "text"
    eid = find_first(strategy, value, port)
    unless eid
      $stderr.puts "no match for #{strategy}: #{value}"
      exit 1
    end
    x, y = element_center(eid, port)
    tap_at(x, y, port)
    puts "tap ok #{strategy}=#{value} at #{x.round(1)},#{y.round(1)}"
  else
    $stderr.puts "unknown strategy: #{strategy} (use aid, text, or at)"
    exit 2
  end

  if wait_strategy
    elapsed = wait_for(wait_strategy, wait_value, wait_timeout, port)
    if elapsed
      puts "wait ok #{wait_strategy}=#{wait_value} in #{elapsed.round(2)}s"
    else
      $stderr.puts "wait timeout: #{wait_strategy}=#{wait_value} not seen in #{wait_timeout}s"
      exit 1
    end
  end
rescue => e
  $stderr.puts "error: #{e.message}"
  exit 2
end
