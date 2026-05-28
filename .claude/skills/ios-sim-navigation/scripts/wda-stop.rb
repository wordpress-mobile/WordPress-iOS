#!/usr/bin/env ruby
# Stop a running WebDriverAgent server.
#
# Usage: ./wda-stop.rb [--port <PORT>]
#
# Options:
#   --port <PORT>   WDA port (default: 8100)
#
# Exit codes:
#   0  WDA stopped (or was not running)
#   1  Failed to stop WDA

require "optparse"

port = 8100

parser = OptionParser.new do |opts|
  opts.banner = "Usage: wda-stop.rb [options]"
  opts.on("--port PORT", Integer, "WDA port (default: 8100)") { |v| port = v }
end
parser.parse!

pid_path = "/tmp/wda-#{port}.pid"
stopped = false

# Try the PID file first
if File.exist?(pid_path)
  pid = File.read(pid_path).strip.to_i
  if pid > 0
    begin
      Process.kill("TERM", pid)
      puts "Sent TERM to WDA process #{pid}"
      stopped = true
    rescue Errno::ESRCH
      puts "WDA process #{pid} already gone"
      stopped = true
    end
  end
  File.delete(pid_path)
end

# Also kill any xcodebuild processes running WebDriverAgent
pids = `pgrep -f "xcodebuild.*WebDriverAgent" 2>/dev/null`.strip.split("\n").map(&:to_i)
pids.each do |p|
  next if p <= 0
  begin
    Process.kill("TERM", p)
    puts "Killed xcodebuild process #{p}"
    stopped = true
  rescue Errno::ESRCH
    # Already gone
  end
end

if stopped
  puts "WDA stopped"
else
  puts "WDA was not running"
end
