# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'pathname'
require 'rbconfig'
require 'tmpdir'
require 'timeout'

RSpec.describe 'WPiOS coding adapter' do
  let(:adapter_source) { Pathname.new(__dir__).parent }
  let(:uuid) { '11111111-1111-1111-1111-111111111111' }
  let(:booted_uuid) { '22222222-2222-2222-2222-222222222222' }
  let(:created_uuid) { '33333333-3333-3333-3333-333333333333' }
  let(:runtime) { 'com.apple.CoreSimulator.SimRuntime.iOS-26-0' }
  let(:phone) { 'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro' }

  around do |example|
    Dir.mktmpdir('wpios adapter ') do |directory|
      @root = Pathname.new(directory).realpath
      @repo, @bin, @adapter = %w[checkout bin snapshot].map { |name| @root.join(name) }
      [@repo, @bin, @adapter, @root.join('home')].each(&:mkpath)
      FileUtils.cp(Dir[adapter_source.join('*.sh')], @adapter)
      File.symlink(RbConfig.ruby, @bin.join('ruby'))
      %w[xcrun xcodebuild sleep].each do |name|
        path = @bin.join(name)
        path.write("#!/usr/bin/env ruby\n#{adapter_source.join('spec/fixtures/fake_tool.rb').read}")
        path.chmod(0o755)
      end
      @env = {
        'HOME' => @root.join('home').to_s, 'PATH' => "#{@bin}:/usr/bin:/bin", 'LANG' => 'C',
        'GIT_CONFIG_NOSYSTEM' => '1', 'GIT_CONFIG_GLOBAL' => File::NULL,
        'AGENT_OUTPUT_DIR' => @root.join('output').to_s, 'AGENT_STATE_DIR' => @root.join('state').to_s,
        'TRACE' => @root.join('trace.jsonl').to_s, 'CREATED_UDID' => created_uuid
      }
      _output, status = Open3.capture2e(@env, 'git', 'init', '--quiet', @repo.to_s, unsetenv_others: true)
      raise 'git init failed' unless status.success?

      @simulators = {
        'devices' => {
          runtime => [{ 'udid' => uuid, 'name' => 'Custom named simulator', 'deviceTypeIdentifier' => phone,
                        'state' => 'Shutdown', 'isAvailable' => true }],
          'com.apple.CoreSimulator.SimRuntime.iOS-18-0' => [{ 'udid' => booted_uuid, 'name' => 'iPhone 16',
                                                              'deviceTypeIdentifier' => phone, 'state' => 'Booted', 'isAvailable' => true }]
        },
        'runtimes' => [{ 'identifier' => runtime, 'platform' => 'iOS', 'version' => '26.0', 'isAvailable' => true,
                         'supportedDeviceTypes' => [{ 'identifier' => phone, 'productFamily' => 'iPhone' }] }]
      }
      example.run
    end
  end

  def run_adapter(script, *, status: 0)
    @env['SIMULATORS'] = JSON.generate(@simulators)
    output, result = Timeout.timeout(15) do
      Open3.capture2e(@env, '/bin/bash', @adapter.join(script).to_s, *, chdir: @repo, unsetenv_others: true)
    end
    expect(result.exitstatus).to eq(status), output
    output
  end

  def commands
    path = @root.join('trace.jsonl')
    path.exist? ? path.readlines.map { |line| JSON.parse(line) } : []
  end

  def prepare
    run_adapter('prepare.sh')
  end

  it 'uses the copied adapter and performs the default build and launch check' do
    prepare
    expect(@root.join('state/simulator-udid').read.strip).to eq(booted_uuid)
    run_adapter('verify.sh')
    build = commands.find { |command| command.last == 'build' }
    expect(build).to include('CODE_SIGNING_ALLOWED=NO', '-disableAutomaticPackageResolution', @root.join('state/DerivedData').to_s)
    expect(commands.any? { |command| command[1, 2] == %w[simctl boot] }).to be(false)
    expect(commands.any? { |command| command[1, 2] == %w[simctl install] }).to be(true)
    expect(Dir[@root.join('output/evidence/simulator-*.png')]).not_to be_empty
  end

  it 'boots an explicitly requested device' do
    run_adapter('prepare.sh', '--simulator-udid', uuid)
    expect(commands).to include(['xcrun', 'simctl', 'boot', uuid])
  end

  it 'keeps the worker log intact' do
    path = @root.join('output/evidence/prepare.log')
    path.dirname.mkpath
    path.write("Worker log prefix\n")
    run_adapter('prepare.sh')
    expect(path.read).to eq("Worker log prefix\n")
    logs = Dir[@root.join('output/evidence/prepare-*.log')]
    expect(logs.size).to eq(1)
    expect(File.read(logs.first)).to include('Simulator ready:')
  end

  it 'creates a device on the newest compatible installed runtime for a fresh user' do
    @simulators['devices'] = {}
    base = @simulators['runtimes'].first
    @simulators['runtimes'] += [base.merge('version' => '18.0', 'identifier' => 'older'),
                                base.merge('version' => '27.0', 'isAvailable' => false),
                                base.merge('version' => '28.0', 'platform' => 'watchOS')]
    prepare
    create = commands.find { |command| command[1, 2] == %w[simctl create] }
    expect(create.last(2)).to eq([phone, runtime])
    expect(commands).to include(['xcrun', 'simctl', 'boot', created_uuid])
    expect(@root.join('state/simulator-udid').read.strip).to eq(created_uuid)
  end

  it 'fails without publishing state when no runtime is installed' do
    @simulators = { 'devices' => {}, 'runtimes' => [] }
    run_adapter('prepare.sh', status: 1)
    expect(@root.join('state/simulator-udid')).not_to exist
    expect(commands.any? { |command| command[1, 2] == %w[simctl create] }).to be(false)
  end

  it 'does not create a device when no compatible iPhone type exists' do
    @simulators['devices'] = {}
    @simulators['runtimes'][0]['supportedDeviceTypes'] = [{ 'productFamily' => 'iPad' }]
    run_adapter('prepare.sh', status: 1)
    expect(commands.any? { |command| command[1, 2] == %w[simctl create] }).to be(false)
  end

  it 'does not publish state or boot after a creation failure' do
    @simulators['devices'] = {}
    @env['CREATE_STATUS'] = '21'
    run_adapter('prepare.sh', status: 1)
    expect(@root.join('state/simulator-udid')).not_to exist
    expect(commands.any? { |command| command[1, 2] == %w[simctl boot] }).to be(false)
  end

  it 'never substitutes another device for a missing requested UUID' do
    run_adapter('prepare.sh', '--simulator-udid', created_uuid, status: 1)
    expect(commands.any? { |command| command[1, 2] == %w[simctl create] }).to be(false)
  end

  it 'rejects malformed requested UUIDs before running tools' do
    ['', 'invalid', '../../anything'].each { |value| run_adapter('prepare.sh', '--simulator-udid', value, status: 2) }
    expect(commands).to be_empty
  end

  it 'does not publish state after a boot failure' do
    @env['BOOT_STATUS'] = '7'
    run_adapter('prepare.sh', '--simulator-udid', uuid, status: 7)
    expect(@root.join('state/simulator-udid')).not_to exist
  end

  it 'propagates a failed build without installing' do
    prepare
    @env['BUILD_STATUS'] = '65'
    run_adapter('verify.sh', status: 65)
    expect(commands.any? { |command| command[1, 2] == %w[simctl install] }).to be(false)
  end

  it 'preserves each scoped test selector' do
    prepare
    run_adapter('verify.sh', '--test', 'WordPressTest/One', '--test', 'WordPressTest/Two/testMethod')
    command = commands.find { |entry| entry.last == 'test' }
    expect(command).to include('-only-testing:WordPressTest/One', '-only-testing:WordPressTest/Two/testMethod', 'WordPressUnitTests')
    expect(commands.any? { |entry| entry[1, 2] == %w[simctl install] }).to be(false)
  end

  it 'rejects unscoped or invalid tests before building' do
    ['WordPressTest', '*', 'Target/Suite --skip-testing:Other', '-workspace/Other'].each do |selector|
      run_adapter('verify.sh', '--test', selector, status: 2)
    end
    expect(commands).to be_empty
  end

  it 'rejects missing or malformed simulator state' do
    run_adapter('verify.sh', status: 1)
    @root.join('state/simulator-udid').write('not-a-uuid')
    run_adapter('verify.sh', status: 1)
    expect(commands).to be_empty
  end

  it 'can build without installing or taking a screenshot' do
    prepare
    @root.join('trace.jsonl').delete
    run_adapter('verify.sh', '--build-only')
    expect(commands.size).to eq(1)
    expect(commands[0][0]).to eq('xcodebuild')
  end

  it 'can take a screenshot without rebuilding' do
    prepare
    @root.join('trace.jsonl').delete
    run_adapter('verify.sh', '--screenshot')
    expect(commands.size).to eq(1)
    expect(commands[0].first(5)).to eq(['xcrun', 'simctl', 'io', booted_uuid, 'screenshot'])
  end

  it 'rejects output inside the checkout before creating it' do
    @env['AGENT_OUTPUT_DIR'] = @repo.join('unwanted-evidence').to_s
    run_adapter('prepare.sh', status: 1)
    expect(@repo.join('unwanted-evidence')).not_to exist
  end

  it 'rejects output routed into the checkout through a symlink' do
    File.symlink(@repo, @root.join('alias'))
    @env['AGENT_OUTPUT_DIR'] = @root.join('alias/nested/evidence').to_s
    run_adapter('prepare.sh', status: 1)
    expect(@repo.join('nested')).not_to exist
  end

  it 'handles a missing directory followed by a parent component' do
    @env['AGENT_OUTPUT_DIR'] = "#{@root}/missing/../output"
    prepare
    expect(@root.join('output/evidence')).to be_directory
  end

  it 'resolves symlinks after missing and parent components before checking the checkout' do
    @repo.join('nested').mkpath
    File.symlink(@repo.join('nested'), @root.join('alias'))
    @env['AGENT_OUTPUT_DIR'] = "#{@root}/missing/../alias/../unwanted-evidence"
    run_adapter('prepare.sh', status: 1)
    expect(@repo.join('unwanted-evidence')).not_to exist
  end

  it 'rejects conflicting modes' do
    run_adapter('verify.sh', '--screenshot', '--test', 'Target/Suite', status: 2)
    run_adapter('verify.sh', '--build-only', '--launch', status: 2)
  end

  it 'refuses the secrets CLI without executing it' do
    path = @bin.join('a8c-secrets')
    path.write("#!/bin/bash\necho must-not-run\nexit 99\n")
    path.chmod(0o755)
    expect(run_adapter('prepare.sh', status: 1)).not_to include('must-not-run')
    expect(commands).to be_empty
  end
end
