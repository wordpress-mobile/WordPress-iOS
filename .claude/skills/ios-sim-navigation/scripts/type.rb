#!/usr/bin/env ruby
# Focus a text field and type through an explicit WDA session.
#
# Usage:
#   type.rb aid FIELD_ID --text TXT --port PORT --session-id ID
#   type.rb text "Field label" --text TXT --port PORT --session-id ID
#
# Exit codes:
#   0  Text sent and optionally verified
#   1  Field not found, keyboard absent, or verification failed
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

def wait_for_keyboard(timeout, port, session_id)
  deadline = Time.now + timeout
  loop do
    code, body = http_post(
      "/session/#{session_id}/elements",
      { "using" => "class name", "value" => "XCUIElementTypeKeyboard" },
      port
    )
    if code.between?(200, 299)
      matches = (JSON.parse(body)["value"] rescue nil) || []
      return true unless matches.empty?
    end
    return false if Time.now >= deadline

    sleep 0.1
  end
end

def send_keys(text, port, session_id)
  code, response = http_post(
    "/session/#{session_id}/wda/keys",
    { "value" => [text] },
    port
  )
  raise "send_keys failed: HTTP #{code}: #{response}" unless code.between?(200, 299)
end

def element_observed_text(element_id, port, session_id)
  ["value", "label"].each do |attribute|
    code, body = http_get(
      "/session/#{session_id}/element/#{element_id}/attribute/#{attribute}",
      port
    )
    next unless code.between?(200, 299)

    observed = JSON.parse(body)["value"]
    return observed if observed && !observed.to_s.empty?
  end
  nil
end

port = nil
session_id = nil
text_to_send = nil
verify = true
keyboard_timeout = 3.0
no_focus = false

parser = OptionParser.new do |opts|
  opts.banner = "Usage: type.rb <aid|text> <field-locator> --text TXT --port PORT --session-id ID [--no-verify] [--no-focus] [--keyboard-timeout SEC]"
  opts.on("--port PORT", Integer) { |value| port = value }
  opts.on("--session-id ID") { |value| session_id = value }
  opts.on("--text TXT") { |value| text_to_send = value }
  opts.on("--no-verify") { verify = false }
  opts.on("--no-focus") { no_focus = true }
  opts.on("--keyboard-timeout SEC", Float) { |value| keyboard_timeout = value }
end
parser.parse!

if ARGV.size < 2 || port.nil? || !(1..65_535).cover?(port) || session_id.nil? || session_id.empty? || text_to_send.nil?
  warn parser.help
  exit 2
end

strategy = ARGV[0]
locator_value = ARGV[1..].join(" ")
unless %w[aid text].include?(strategy)
  warn "unknown strategy: #{strategy} (use aid or text)"
  exit 2
end

begin
  validate_session(port, session_id)
  element_id = find_first(strategy, locator_value, port, session_id)
  unless element_id
    warn "no match for #{strategy}: #{locator_value}"
    exit 1
  end

  unless no_focus
    x, y = element_center(element_id, port, session_id)
    tap_at(x, y, port, session_id)
    unless wait_for_keyboard(keyboard_timeout, port, session_id)
      warn "keyboard didn't appear within #{keyboard_timeout}s after tapping #{strategy}=#{locator_value}"
      exit 1
    end
  end

  send_keys(text_to_send, port, session_id)

  if verify
    observed = element_observed_text(element_id, port, session_id)
    if observed.nil? || !observed.to_s.include?(text_to_send)
      warn "verify failed: expected to contain #{text_to_send.inspect}, got #{observed.inspect}"
      exit 1
    end
    puts "type ok #{strategy}=#{locator_value} verified=#{observed.inspect}"
  else
    puts "type ok #{strategy}=#{locator_value} sent #{text_to_send.inspect}"
  end
rescue => error
  warn "error: #{error.message}"
  exit 2
end
