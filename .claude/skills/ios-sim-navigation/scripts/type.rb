#!/usr/bin/env ruby
# type.rb — Focus a text field and type into it via WebDriverAgent.
#
# One Ruby invocation = one Claude turn. Collapses the four-step
# "tap field / wait for keyboard / send keys / read value back" loop
# into a single call. Reuses the session that tap.rb persists at
# /tmp/wda-<port>.session (bound to the foreground app's bundleId).
#
# Usage:
#   type.rb aid <field-aid>      --text "Hello world"
#   type.rb text "<field-label>" --text "Hello world"
#
# Options:
#   --text TXT              Text to send. Required.
#   --no-verify             Skip the post-type readback. By default the
#                           script reads the field's `value` (or `label`
#                           as fallback) and exits 1 if it doesn't
#                           contain TXT — catching dropped keypresses
#                           without an extra tool call.
#   --keyboard-timeout SEC  Max seconds to wait for the keyboard to
#                           appear after tapping the field (default 3.0).
#   --no-focus              Skip the tap + keyboard wait. Use when the
#                           field is already focused (e.g. a fresh post
#                           editor that auto-focuses its title).
#   --port PORT             WDA port (default: 8100, or $WDA_PORT).
#
# Why a single string and not per-character: WDA's /wda/keys accepts
# an array whose entries are sent as keystrokes. A single entry like
# `"hello"` types the whole word. Per-character arrays are only useful
# when you need to mix in control codes (e.g. `""` for Ctrl+A
# inside a clear-field sequence).
#
# Exit codes:
#   0  field tapped (if needed), keyboard up, text sent
#      (and field value/label contains TXT unless --no-verify)
#   1  field not found, keyboard didn't appear, or verify mismatch
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

# Poll /elements for XCUIElementTypeKeyboard. The cheap check from SKILL.md.
def wait_for_keyboard(timeout, port = PORT)
  sid = session_id(port)
  deadline = Time.now + timeout
  loop do
    code, body = http_post(
      "/session/#{sid}/elements",
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

def send_keys(text, port = PORT)
  sid = session_id(port)
  code, resp = http_post("/session/#{sid}/wda/keys", { "value" => [text] }, port)
  raise "send_keys failed: HTTP #{code}: #{resp}" unless code.between?(200, 299)
end

# Try the `value` attribute first; fall back to `label` if `value` is nil.
# Many SwiftUI / UIKit text-input controls expose the typed text via the
# enclosing element's `label` ("Post title. Hello world") even when that
# element's `value` is nil because the text lives on a descendant TextView.
def element_observed_text(eid, port = PORT)
  sid = session_id(port)
  ["value", "label"].each do |attr|
    code, body = http_get("/session/#{sid}/element/#{eid}/attribute/#{attr}", port)
    next unless code.between?(200, 299)
    observed = JSON.parse(body)["value"]
    return observed if observed && !observed.to_s.empty?
  end
  nil
end

port = PORT
text_to_send = nil
verify = true
keyboard_timeout = 3.0
no_focus = false

parser = OptionParser.new do |opts|
  opts.banner = "Usage: type.rb <aid|text> <field-locator> --text TXT [--no-verify] [--no-focus] [--keyboard-timeout SEC] [--port PORT]"
  opts.on("--text TXT")             { |v| text_to_send = v }
  opts.on("--no-verify")            { verify = false }
  opts.on("--no-focus")             { no_focus = true }
  opts.on("--keyboard-timeout SEC", Float) { |v| keyboard_timeout = v }
  opts.on("--port PORT", Integer)   { |v| port = v }
end
parser.parse!

if ARGV.size < 2 || text_to_send.nil?
  $stderr.puts parser.help
  exit 2
end

strategy = ARGV[0]
locator_value = ARGV[1..].join(" ")

unless %w[aid text].include?(strategy)
  $stderr.puts "unknown strategy: #{strategy} (use aid or text)"
  exit 2
end

begin
  eid = find_first(strategy, locator_value, port)
  unless eid
    $stderr.puts "no match for #{strategy}: #{locator_value}"
    exit 1
  end

  unless no_focus
    x, y = element_center(eid, port)
    tap_at(x, y, port)
    unless wait_for_keyboard(keyboard_timeout, port)
      $stderr.puts "keyboard didn't appear within #{keyboard_timeout}s after tapping #{strategy}=#{locator_value}"
      exit 1
    end
  end

  send_keys(text_to_send, port)

  if verify
    observed = element_observed_text(eid, port)
    if observed.nil? || !observed.to_s.include?(text_to_send)
      $stderr.puts "verify failed: expected to contain #{text_to_send.inspect}, got #{observed.inspect}"
      exit 1
    end
    puts "type ok #{strategy}=#{locator_value} verified=#{observed.inspect}"
  else
    puts "type ok #{strategy}=#{locator_value} sent #{text_to_send.inspect}"
  end
rescue => e
  $stderr.puts "error: #{e.message}"
  exit 2
end
