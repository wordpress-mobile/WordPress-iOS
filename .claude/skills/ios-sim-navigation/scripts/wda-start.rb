#!/usr/bin/env ruby
# Start WebDriverAgent on a specific simulator and port.
#
# Run this command with the coding agent's tracked background-task facility.
# The script prepares a shared, ready-to-run WDA cache when necessary, starts
# WDA, and performs one clean rebuild if the cached launch fails before WDA is
# ready. Stop this exact background task when navigation is complete.
#
# Usage: wda-start.rb --udid UDID --port PORT
#
# Exit codes:
#   1  WDA failed to prepare or launch
#   2  Invalid or conflicting configuration

require "fileutils"
require "net/http"
require "optparse"
require "socket"
require "timeout"
require "tmpdir"
require "uri"

class WebDriverAgent
  REPOSITORY = "https://github.com/appium/WebDriverAgent.git"
  SCHEME = "WebDriverAgentRunner"
  STARTUP_TIMEOUT = 60

  def initialize(udid:, port:)
    @udid = udid
    @port = port
    # Share one ready-to-run checkout across repository clones and worktrees.
    # Keeping DerivedData inside it also makes the checkout and build cache one unit.
    @directory = File.join(Dir.home, "Library", "Caches", "WordPress-iOS", "WebDriverAgent")
  end

  def run
    unless port_available?
      warn "error: port #{@port} is already in use; choose another port"
      return 2
    end

    unless prepare_cache
      warn "error: failed to prepare WebDriverAgent"
      return 1
    end

    return 2 unless ensure_port_remains_available

    state, exit_code = launch("Starting")
    return exit_code unless state == :failed_before_ready
    return 2 unless ensure_port_remains_available

    # Xcode upgrades can invalidate cached build products. Retry only once so a
    # persistent launch failure does not cause an unbounded rebuild loop.
    warn "WebDriverAgent failed before becoming ready; rebuilding once..."
    unless build_for_testing(at: @directory, clean: true)
      warn "error: WebDriverAgent rebuild failed"
      return 1
    end

    return 2 unless ensure_port_remains_available

    state, exit_code = launch("Retrying")
    if state == :failed_before_ready
      warn "error: WebDriverAgent failed before becoming ready after one rebuild"
      return 1
    end

    exit_code
  rescue SystemCallError => error
    warn "error: WebDriverAgent failed: #{error.message}"
    1
  end

  private

  def prepare_cache
    return true if cache_ready?(@directory)

    # A checkout without an xctestrun file usually means its build was interrupted.
    if File.exist?(project_path(@directory))
      puts "Repairing the incomplete WebDriverAgent cache..."
      return build_for_testing(at: @directory, clean: true)
    end

    if File.exist?(@directory)
      warn "error: WebDriverAgent cache is incomplete at #{@directory}"
      return false
    end

    cache_parent = File.dirname(@directory)
    FileUtils.mkdir_p(cache_parent)
    # Build in a sibling temporary directory, then rename it into place. The
    # same-volume rename is atomic, so other sessions never use a partial cache.
    staging_directory = Dir.mktmpdir(".WebDriverAgent-", cache_parent)

    begin
      puts "Preparing WebDriverAgent for first use..."
      return false unless clone_repository(into: staging_directory)
      return false unless build_for_testing(at: staging_directory)

      unless cache_ready?(staging_directory)
        warn "error: WebDriverAgent build did not produce an xctestrun file"
        return false
      end

      begin
        File.rename(staging_directory, @directory)
        staging_directory = nil
      rescue SystemCallError
        # Concurrent first-time starts may race here. Use the winner only when
        # it contains both the checkout and a completed simulator build.
        unless cache_ready?(@directory)
          warn "error: another process created an incomplete WebDriverAgent cache"
          return false
        end
        puts "Another process prepared WebDriverAgent first; using its cache."
      end

      true
    ensure
      FileUtils.rm_rf(staging_directory) if staging_directory && File.exist?(staging_directory)
    end
  end

  def clone_repository(into: directory)
    system("git", "clone", "--depth", "1", REPOSITORY, directory)
  end

  def build_for_testing(at: directory, clean: false)
    arguments = build_arguments(directory)

    if clean
      puts "Cleaning the cached WebDriverAgent build..."
      return false unless system("xcodebuild", "clean", *arguments)
    end

    puts "Building WebDriverAgent for simulator #{@udid}..."
    system("xcodebuild", "build-for-testing", *arguments)
  end

  def build_arguments(directory)
    [
      "-project", project_path(directory),
      "-scheme", SCHEME,
      "-destination", "id=#{@udid}",
      "-derivedDataPath", derived_data_path(directory),
      "CODE_SIGNING_ALLOWED=NO"
    ]
  end

  def cache_ready?(directory)
    pattern = File.join(derived_data_path(directory), "Build", "Products", "**", "*.xctestrun")
    File.exist?(project_path(directory)) && Dir.glob(pattern).any?
  end

  def project_path(directory)
    File.join(directory, "WebDriverAgent.xcodeproj")
  end

  def derived_data_path(directory)
    File.join(directory, "DerivedData")
  end

  def launch(verb)
    puts "#{verb} WebDriverAgent on port #{@port} for simulator #{@udid}..."
    $stdout.flush
    run_process(test_command)
  end

  def test_command
    [
      "xcodebuild", "test-without-building",
      "-project", project_path(@directory),
      "-scheme", SCHEME,
      "-destination", "id=#{@udid}",
      "-derivedDataPath", derived_data_path(@directory),
      "USE_PORT=#{@port}",
      "CODE_SIGNING_ALLOWED=NO"
    ]
  end

  def run_process(command)
    # Keep Ruby alive to detect failures before WDA is ready and trigger the
    # bounded rebuild. A process group lets background-task signals reach every
    # xcodebuild descendant through the forwarding handlers below.
    child_pid = Process.spawn(*command, pgroup: true)
    interrupted_signal = nil
    previous_handlers = {}

    %w[INT TERM HUP].each do |signal|
      previous_handlers[signal] = Signal.trap(signal) do
        interrupted_signal ||= signal
        terminate_process_group(child_pid, signal)
      end
    end

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + STARTUP_TIMEOUT

    loop do
      if ready?
        puts "WebDriverAgent is ready on port #{@port}."
        $stdout.flush
        _, status = Process.wait2(child_pid)
        state = interrupted_signal ? :interrupted : :exited_after_ready
        return [state, status_exit_code(status)]
      end

      if (result = Process.waitpid2(child_pid, Process::WNOHANG))
        state = interrupted_signal ? :interrupted : :failed_before_ready
        return [state, status_exit_code(result.last)]
      end

      if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        warn "error: WebDriverAgent did not become ready within #{STARTUP_TIMEOUT} seconds"
        terminate_process_group(child_pid, "TERM")
        _, status = Process.wait2(child_pid)
        return [:failed_before_ready, status_exit_code(status)]
      end

      sleep 0.25
    end
  ensure
    previous_handlers&.each { |signal, handler| Signal.trap(signal, handler) }
  end

  def ready?
    uri = URI("http://127.0.0.1:#{@port}/status")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 0.5
    http.read_timeout = 0.5
    http.get(uri.request_uri).is_a?(Net::HTTPSuccess)
  rescue SystemCallError, SocketError, Timeout::Error
    false
  end

  def ensure_port_remains_available
    return true if port_available?

    warn "error: port #{@port} became unavailable; choose another port"
    false
  end

  def port_available?
    server = TCPServer.new("127.0.0.1", @port)
    server.close
    true
  rescue Errno::EADDRINUSE, Errno::EACCES
    false
  end

  def terminate_process_group(pid, signal)
    Process.kill(signal, -pid)
  rescue Errno::ESRCH
    nil
  end

  def status_exit_code(status)
    return status.exitstatus if status.exited?
    return 128 + status.termsig if status.signaled?

    1
  end
end

udid = nil
port = nil

parser = OptionParser.new do |opts|
  opts.banner = "Usage: wda-start.rb --udid UDID --port PORT"
  opts.on("--udid UDID", "Target simulator UDID (required)") { |value| udid = value }
  opts.on("--port PORT", Integer, "WDA port (required)") { |value| port = value }
end
parser.parse!

if udid.nil? || port.nil? || !(1..65_535).cover?(port)
  warn parser.help
  exit 2
end

exit WebDriverAgent.new(udid: udid, port: port).run
