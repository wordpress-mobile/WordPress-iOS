#!/usr/bin/env ruby
# Tap an element on the iOS Simulator through an explicit WDA session.
#
# Usage:
#   tap.rb aid ACCESSIBILITY_ID --port PORT --session-id ID
#   tap.rb text "Visible label" --port PORT --session-id ID
#   tap.rb at X,Y --port PORT --session-id ID
#
# Options:
#   --wait-aid AID    Poll for an element after the tap.
#   --wait-text TXT   Poll for a visible label or accessibility id.
#   --timeout SEC     Wait timeout (default: 3 seconds).
#   --port PORT       WDA port (required).
#   --session-id ID   Active WDA session id (required).
#
# Exit codes:
#   0  Tap dispatched and optional wait condition met
#   1  Tap target not found or wait condition timed out
#   2  WDA or usage error

require "json"
require "net/http"
require "optparse"
require "uri"

def base_url(port)
  "http://localhost:#{port}"
end

def http_get(path, port)
  uri = URI("#{base_url(port)}#{path}")
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(Net::HTTP::Get.new(uri)) }
  [response.code.to_i, response.body]
rescue Errno::ECONNREFUSED, Errno::ECONNRESET
  raise "WDA not reachable on port #{port}; start it first"
end

def http_post(path, body, port)
  uri = URI("#{base_url(port)}#{path}")
  request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
  request.body = JSON.dump(body)
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  [response.code.to_i, response.body]
rescue Errno::ECONNREFUSED, Errno::ECONNRESET
  raise "WDA not reachable on port #{port}; start it first"
end

def validate_session(port, session_id)
  code, = http_get("/session/#{session_id}", port)
  return if code == 200

  raise "session #{session_id} is not active on port #{port}; create a new session explicitly"
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

def find_first(strategy, value, port, session_id)
  using, locator = locator_for(strategy, value)
  code, body = http_post(
    "/session/#{session_id}/elements",
    { "using" => using, "value" => locator },
    port
  )
  return nil if code == 404
  raise "find failed: HTTP #{code}: #{body}" unless code.between?(200, 299)

  matches = JSON.parse(body)["value"] || []
  return nil if matches.empty?

  match = matches.first
  match["ELEMENT"] || match["element-6066-11e4-a52e-4f735466cecf"] || match.values.first
end

def wait_for(strategy, value, timeout, port, session_id)
  using, locator = locator_for(strategy, value)
  deadline = Time.now + timeout
  start = Time.now

  loop do
    code, body = http_post(
      "/session/#{session_id}/elements",
      { "using" => using, "value" => locator },
      port
    )
    if code.between?(200, 299)
      matches = (JSON.parse(body)["value"] rescue nil) || []
      return Time.now - start unless matches.empty?
    end
    return nil if Time.now >= deadline

    sleep 0.25
  end
end

def element_center(element_id, port, session_id)
  code, body = http_get("/session/#{session_id}/element/#{element_id}/rect", port)
  raise "rect failed: HTTP #{code}: #{body}" unless code.between?(200, 299)

  rect = JSON.parse(body)["value"]
  [rect["x"] + rect["width"] / 2.0, rect["y"] + rect["height"] / 2.0]
end

def tap_at(x, y, port, session_id)
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
  code, response = http_post("/session/#{session_id}/actions", body, port)
  raise "tap failed: HTTP #{code}: #{response}" unless code.between?(200, 299)
end

port = nil
session_id = nil
wait_strategy = nil
wait_value = nil
wait_timeout = 3.0

parser = OptionParser.new do |opts|
  opts.banner = "Usage: tap.rb <aid|text|at> <value> --port PORT --session-id ID [--wait-aid AID|--wait-text TXT] [--timeout SEC]"
  opts.on("--port PORT", Integer) { |value| port = value }
  opts.on("--session-id ID") { |value| session_id = value }
  opts.on("--wait-aid AID") { |value| wait_strategy = "aid"; wait_value = value }
  opts.on("--wait-text TXT") { |value| wait_strategy = "text"; wait_value = value }
  opts.on("--timeout SEC", Float) { |value| wait_timeout = value }
end
parser.parse!

if ARGV.size < 2 || port.nil? || !(1..65_535).cover?(port) || session_id.nil? || session_id.empty?
  warn parser.help
  exit 2
end

strategy = ARGV[0]
value = ARGV[1..].join(" ")

begin
  validate_session(port, session_id)

  case strategy
  when "at"
    x, y = value.split(",").map { |component| Float(component) }
    tap_at(x, y, port, session_id)
    puts "tap ok at #{x.round(1)},#{y.round(1)}"
  when "aid", "text"
    element_id = find_first(strategy, value, port, session_id)
    unless element_id
      warn "no match for #{strategy}: #{value}"
      exit 1
    end
    x, y = element_center(element_id, port, session_id)
    tap_at(x, y, port, session_id)
    puts "tap ok #{strategy}=#{value} at #{x.round(1)},#{y.round(1)}"
  else
    warn "unknown strategy: #{strategy} (use aid, text, or at)"
    exit 2
  end

  if wait_strategy
    elapsed = wait_for(wait_strategy, wait_value, wait_timeout, port, session_id)
    if elapsed
      puts "wait ok #{wait_strategy}=#{wait_value} in #{elapsed.round(2)}s"
    else
      warn "wait timeout: #{wait_strategy}=#{wait_value} not seen in #{wait_timeout}s"
      exit 1
    end
  end
rescue ArgumentError
  warn "invalid coordinates: #{value}"
  exit 2
rescue => error
  warn "error: #{error.message}"
  exit 2
end
