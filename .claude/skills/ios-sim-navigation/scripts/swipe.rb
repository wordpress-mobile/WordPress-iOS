#!/usr/bin/env ruby
# swipe.rb — Perform a directional or coordinate swipe via WebDriverAgent.
#
# One Ruby invocation = one Claude turn. Wraps the W3C pointer-actions
# JSON body and computes direction-to-coordinates from the simulator's
# window size automatically. Reuses the session that tap.rb persists at
# /tmp/wda-<port>.session.
#
# Usage:
#   swipe.rb up                  # vertical swipe up (scrolls content down)
#   swipe.rb down                # vertical swipe down (scrolls content up)
#   swipe.rb left
#   swipe.rb right
#   swipe.rb back                # edge swipe from left edge → right (back nav fallback)
#   swipe.rb at X1,Y1,X2,Y2      # explicit coordinates
#
# Options:
#   --duration MS  Swipe duration in milliseconds (default 500).
#                  Bump to 1000 if the gesture lands on a tappable
#                  item so it isn't misread as a tap.
#   --port PORT    WDA port (default: 8100, or $WDA_PORT).
#
# Vertical swipes use the right-edge x (window_width - 30) so the
# gesture doesn't land on interactive elements in the center. See
# SKILL.md "Swipe direction guide" for the underlying math.
#
# Exit codes:
#   0  swipe dispatched
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

def window_size(port = PORT)
  sid = session_id(port)
  code, body = http_get("/session/#{sid}/window/size", port)
  raise "window/size failed: HTTP #{code}: #{body}" unless code.between?(200, 299)
  v = JSON.parse(body)["value"]
  [v["width"].to_f, v["height"].to_f]
end

def swipe_from_to(x1, y1, x2, y2, duration_ms, port = PORT)
  sid = session_id(port)
  body = {
    "actions" => [{
      "type" => "pointer", "id" => "finger1",
      "parameters" => { "pointerType" => "touch" },
      "actions" => [
        { "type" => "pointerMove", "duration" => 0,           "x" => x1, "y" => y1 },
        { "type" => "pointerDown" },
        { "type" => "pointerMove", "duration" => duration_ms, "x" => x2, "y" => y2 },
        { "type" => "pointerUp" }
      ]
    }]
  }
  code, resp = http_post("/session/#{sid}/actions", body, port)
  raise "swipe failed: HTTP #{code}: #{resp}" unless code.between?(200, 299)
end

# Direction-to-coordinates math from SKILL.md "Swipe direction guide".
# Returns [x1, y1, x2, y2].
def coords_for_direction(direction, port = PORT)
  w, h = window_size(port)
  case direction
  when "up"    then [w - 30, h * 2 / 3.0, w - 30, h * 1 / 3.0]
  when "down"  then [w - 30, h * 1 / 3.0, w - 30, h * 2 / 3.0]
  when "left"  then [w * 3 / 4.0, h / 2.0, w / 4.0,     h / 2.0]
  when "right" then [w / 4.0,     h / 2.0, w * 3 / 4.0, h / 2.0]
  when "back"  then [5.0,         h / 2.0, w * 2 / 3.0, h / 2.0]
  else raise "unknown direction: #{direction}"
  end
end

port = PORT
duration_ms = 500

parser = OptionParser.new do |opts|
  opts.banner = "Usage: swipe.rb <up|down|left|right|back|at> [X1,Y1,X2,Y2] [--duration MS] [--port PORT]"
  opts.on("--duration MS", Integer) { |v| duration_ms = v }
  opts.on("--port PORT",   Integer) { |v| port = v }
end
parser.parse!

if ARGV.empty?
  $stderr.puts parser.help
  exit 2
end

direction = ARGV[0]

begin
  if direction == "at"
    coords = (ARGV[1] || "").split(",").map { |s| Float(s) rescue nil }
    if coords.size != 4 || coords.any?(&:nil?)
      $stderr.puts "usage: swipe.rb at X1,Y1,X2,Y2"
      exit 2
    end
    x1, y1, x2, y2 = coords
  else
    x1, y1, x2, y2 = coords_for_direction(direction, port)
  end

  swipe_from_to(x1, y1, x2, y2, duration_ms, port)
  puts "swipe ok #{direction} (%.1f,%.1f → %.1f,%.1f, %dms)" % [x1, y1, x2, y2, duration_ms]
rescue => e
  $stderr.puts "error: #{e.message}"
  exit 2
end
