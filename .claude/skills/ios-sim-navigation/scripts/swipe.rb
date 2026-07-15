#!/usr/bin/env ruby
# Perform a directional or coordinate swipe through an explicit WDA session.
#
# Usage:
#   swipe.rb <up|down|left|right|back> --port PORT --session-id ID
#   swipe.rb at X1,Y1,X2,Y2 --port PORT --session-id ID
#
# Options:
#   --duration MS    Swipe duration (default: 500 milliseconds).
#   --port PORT      WDA port (required).
#   --session-id ID  Active WDA session id (required).
#
# Exit codes: 0 on success, 2 on WDA or usage error.

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

def window_size(port, session_id)
  code, body = http_get("/session/#{session_id}/window/size", port)
  raise "window/size failed: HTTP #{code}: #{body}" unless code.between?(200, 299)

  value = JSON.parse(body)["value"]
  [value["width"].to_f, value["height"].to_f]
end

def swipe_from_to(x1, y1, x2, y2, duration_ms, port, session_id)
  body = {
    "actions" => [{
      "type" => "pointer", "id" => "finger1",
      "parameters" => { "pointerType" => "touch" },
      "actions" => [
        { "type" => "pointerMove", "duration" => 0, "x" => x1, "y" => y1 },
        { "type" => "pointerDown" },
        { "type" => "pointerMove", "duration" => duration_ms, "x" => x2, "y" => y2 },
        { "type" => "pointerUp" }
      ]
    }]
  }
  code, response = http_post("/session/#{session_id}/actions", body, port)
  raise "swipe failed: HTTP #{code}: #{response}" unless code.between?(200, 299)
end

def coordinates_for(direction, port, session_id)
  width, height = window_size(port, session_id)
  case direction
  when "up"    then [width - 30, height * 2 / 3.0, width - 30, height * 1 / 3.0]
  when "down"  then [width - 30, height * 1 / 3.0, width - 30, height * 2 / 3.0]
  when "left"  then [width * 3 / 4.0, height / 2.0, width / 4.0, height / 2.0]
  when "right" then [width / 4.0, height / 2.0, width * 3 / 4.0, height / 2.0]
  when "back"  then [5.0, height / 2.0, width * 2 / 3.0, height / 2.0]
  else raise "unknown direction: #{direction}"
  end
end

port = nil
session_id = nil
duration_ms = 500

parser = OptionParser.new do |opts|
  opts.banner = "Usage: swipe.rb <up|down|left|right|back|at> [X1,Y1,X2,Y2] --port PORT --session-id ID [--duration MS]"
  opts.on("--port PORT", Integer) { |value| port = value }
  opts.on("--session-id ID") { |value| session_id = value }
  opts.on("--duration MS", Integer) { |value| duration_ms = value }
end
parser.parse!

if ARGV.empty? || port.nil? || !(1..65_535).cover?(port) || session_id.nil? || session_id.empty?
  warn parser.help
  exit 2
end

direction = ARGV[0]

begin
  validate_session(port, session_id)

  if direction == "at"
    coordinates = (ARGV[1] || "").split(",").map { |component| Float(component) rescue nil }
    if coordinates.size != 4 || coordinates.any?(&:nil?)
      warn "usage: swipe.rb at X1,Y1,X2,Y2 --port PORT --session-id ID"
      exit 2
    end
    x1, y1, x2, y2 = coordinates
  else
    x1, y1, x2, y2 = coordinates_for(direction, port, session_id)
  end

  swipe_from_to(x1, y1, x2, y2, duration_ms, port, session_id)
  puts "swipe ok #{direction} (%.1f,%.1f -> %.1f,%.1f, %dms)" % [x1, y1, x2, y2, duration_ms]
rescue => error
  warn "error: #{error.message}"
  exit 2
end
