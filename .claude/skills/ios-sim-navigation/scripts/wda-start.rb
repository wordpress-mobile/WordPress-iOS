#!/usr/bin/env ruby
# Start WebDriverAgent server on a simulator.
#
# Workflow:
#   1. Clone WebDriverAgent into `<cwd>/.build/WebDriverAgent` if absent.
#   2. Run `xcodebuild build-for-testing` synchronously (foreground, so
#      its progress is visible). Incremental — fast on warm cache.
#   3. Spawn `xcodebuild test-without-building` in the background and
#      poll `/status` until WDA responds (~60 s).
#
# Invoke from the project root that should own the `.build/` cache —
# the WebDriverAgent path is resolved relative to the current working
# directory.
#
# Usage: ./wda-start.rb [--udid <UDID>] [--port <PORT>]
#
# Options:
#   --udid <UDID>   Target a specific simulator (default: first booted)
#   --port <PORT>   WDA port (default: 8100)
#
# Exit codes:
#   0  WDA started successfully
#   1  WDA failed to start
#   2  Configuration error

require "optparse"
require "net/http"
require "json"
require "fileutils"

DEFAULT_PORT = 8100

def get_booted_udid
  output = `xcrun simctl list devices booted -j 2>/dev/null`
  return nil unless $?.success?

  data = JSON.parse(output)
  data.fetch("devices", {}).each_value do |devices|
    devices.each do |d|
      return d["udid"] if d["state"] == "Booted"
    end
  end
  nil
end

def resolve_udid(udid)
  return udid if udid

  detected = get_booted_udid
  unless detected
    $stderr.puts "Error: No booted simulator found. Specify --udid or boot a simulator."
    exit 2
  end
  detected
end

def wda_running?(port)
  uri = URI("http://localhost:#{port}/status")
  response = Net::HTTP.get_response(uri)
  response.code.to_i == 200
rescue Errno::ECONNREFUSED, Errno::ECONNRESET
  false
end

udid = nil
port = DEFAULT_PORT

parser = OptionParser.new do |opts|
  opts.banner = "Usage: wda-start.rb [options]"
  opts.on("--udid UDID", "Target a specific simulator") { |v| udid = v }
  opts.on("--port PORT", Integer, "WDA port (default: 8100)") { |v| port = v }
end
parser.parse!

udid = resolve_udid(udid)

# Check if WDA is already running
if wda_running?(port)
  puts "WDA already running on port #{port}"
  exit 0
end

# Find (or clone) the WDA project. `.build/WebDriverAgent` lives next to
# the caller's cwd so test runs share one cache per project root.
wda_dir = File.join(Dir.pwd, ".build", "WebDriverAgent")
wda_project = File.join(wda_dir, "WebDriverAgent.xcodeproj")
unless File.exist?(wda_project)
  puts "WebDriverAgent not found at #{wda_dir}; cloning..."
  FileUtils.mkdir_p(File.dirname(wda_dir))
  clone_ok = system("git", "clone", "--depth", "1",
                    "https://github.com/appium/WebDriverAgent.git", wda_dir)
  unless clone_ok && File.exist?(wda_project)
    $stderr.puts "Error: failed to clone WebDriverAgent into #{wda_dir}"
    exit 2
  end
end

# Build first, synchronously, so cold checkouts complete their build
# phase before we start polling for WDA to come up. Incremental, so
# warm runs cost nothing.
puts "Building WebDriverAgent for testing (incremental on warm cache)..."
build_ok = system(
  "xcodebuild", "build-for-testing",
  "-project", wda_project,
  "-scheme", "WebDriverAgentRunner",
  "-destination", "id=#{udid}",
  "CODE_SIGNING_ALLOWED=NO"
)
unless build_ok
  $stderr.puts "Error: xcodebuild build-for-testing failed"
  exit 1
end

# Then run the test bundle (which hosts the WDA server) in the
# background. The 60 s `/status` poll below is for WDA to come up —
# the build is already done.
cmd = [
  "xcodebuild", "test-without-building",
  "-project", wda_project,
  "-scheme", "WebDriverAgentRunner",
  "-destination", "id=#{udid}",
  "USE_PORT=#{port}",
  "CODE_SIGNING_ALLOWED=NO"
]

log_path = "/tmp/wda-#{port}.log"
pid_path = "/tmp/wda-#{port}.pid"

puts "Starting WDA on port #{port} for simulator #{udid}..."
puts "Log: #{log_path}"

pid = spawn(*cmd, out: log_path, err: log_path)
File.write(pid_path, pid.to_s)
Process.detach(pid)

# Wait for WDA to become ready
max_wait = 60
interval = 2
elapsed = 0

while elapsed < max_wait
  sleep interval
  elapsed += interval

  begin
    uri = URI("http://localhost:#{port}/status")
    response = Net::HTTP.get_response(uri)
    if response.code.to_i == 200
      puts "WDA ready on port #{port} (took #{elapsed}s)"
      puts "PID: #{pid} (saved to #{pid_path})"
      exit 0
    end
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET
    # Not ready yet
  end
end

$stderr.puts "Error: WDA did not start within #{max_wait}s"
$stderr.puts "Check log: #{log_path}"
# Try to kill the process
begin
  Process.kill("TERM", pid)
rescue Errno::ESRCH
  # Process already gone
end
exit 1
