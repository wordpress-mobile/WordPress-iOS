#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage: xcresult-to-junit.rb <bundle.xcresult> <report.junit>
#
# Keep the output identical to fastlane's `trainer`: Buildkite Test Engine tracks each test's history by its names.

# rubocop:disable Metrics

require 'json'
require 'open3'
require 'rexml/document'

SUITE_TYPES = ['Test Suite', 'Unit test bundle', 'UI test bundle'].freeze

def sanitize(text)
  text.to_s.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/) { |char| format('\\u%04x', char.ord) }
end

def element(name, **attributes)
  REXML::Element.new(name).tap do |node|
    attributes.compact.each { |key, value| node.attributes[key.to_s] = sanitize(value) }
  end
end

def children(node, *types)
  (node['children'] || []).select { |child| types.include?(child['nodeType']) }
end

def names(node, type)
  children(node, type).map { |child| child['name'] }
end

def seconds(node)
  node['duration'].to_s.tr(',', '.').chomp('s').to_f
end

def properties(pairs)
  element('properties').tap do |node|
    pairs.each { |name, value| node.add_element(element('property', name: name, value: value)) }
  end
end

def test_name(name, argument)
  return name if argument.nil?

  name.match?(/(\(.*\))/) ? name.gsub(/(\(.*\))/, "(#{argument})") : "#{name} (#{argument})"
end

def add_result(testcase, node)
  messages = names(node, 'Failure Message')
  case node['result']
  when 'Failed'
    (messages.empty? ? [nil] : messages).each { |message| testcase.add_element(element('failure', message: message)) }
  when 'Skipped'
    testcase.add_element(element('skipped', message: messages.first))
  end
end

def numbered(prefix, values)
  values.each_with_index.map { |value, index| ["#{prefix}#{index + 1}", value] }
end

def case_properties(test, argument, run, sources)
  pairs = argument ? [['testname', test['name']], ['argument', argument['name']]] : []
  pairs << ['repetition', run['name']] if run
  sources.each { |source| pairs.concat(numbered(*source)) }
  pairs
end

def sources_for(node, runs)
  origins = runs.empty? ? [node] : runs
  [
    ['source_reference', origins.flat_map { |origin| names(origin, 'Source Code Reference') }],
    ['attachment', origins.flat_map { |origin| names(origin, 'Attachment') }]
  ]
end

def classname(test)
  identifier = test['nodeIdentifier']
  identifier.split('/')[0...-1].join('.') unless identifier.nil?
end

def testcase_element(test, argument, run, sources)
  node = element(
    'testcase',
    name: test_name(test['name'], argument&.fetch('name')),
    classname: classname(test),
    time: seconds(run || test).to_s
  )
  add_result(node, run || argument || test)
  pairs = case_properties(test, argument, run, sources + [['tag', (test['tags'] || []).sort]])
  node.add_element(properties(pairs)) unless pairs.empty?
  node
end

# Returns one entry per test argument, or a single one for a test without arguments.
def expand(test)
  arguments = children(test, 'Arguments')
  (arguments.empty? ? [nil] : arguments).map do |argument|
    attributes = argument || test
    runs = children(attributes, 'Repetition', 'Test Case Run')
    nodes = (runs.empty? ? [nil] : runs).map { |run| testcase_element(test, argument, run, sources_for(attributes, runs)) }
    { nodes: nodes, result: attributes['result'], time: seconds(test) }
  end
end

def suite_totals(cases, suites)
  {
    tests: cases.count + suites.sum { |suite| suite[:tests] },
    failures: cases.count { |test| test[:result] == 'Failed' } + suites.sum { |suite| suite[:failures] },
    skipped: cases.count { |test| test[:result] == 'Skipped' } + suites.sum { |suite| suite[:skipped] },
    time: cases.sum { |test| test[:time] } + suites.sum { |suite| suite[:time] }
  }
end

def build_suite(node)
  cases = children(node, 'Test Case').flat_map { |test| expand(test) }
  suites = children(node, *SUITE_TYPES).map { |suite| build_suite(suite) }
  totals = suite_totals(cases, suites)

  xml = element('testsuite', name: node['name'], time: totals[:time], tests: totals[:tests], failures: totals[:failures], skipped: totals[:skipped])
  cases.flat_map { |test| test[:nodes] }.each { |testcase| xml.add_element(testcase) }
  suites.each { |suite| xml.add_element(suite[:xml]) }
  totals.merge(xml: xml)
end

def environment_properties(report)
  configurations = (report['testPlanConfigurations'] || []).map { |config| ['Configuration', config['configurationName']] }
  devices = (report['devices'] || []).map do |device|
    ['device', "#{device.fetch('modelName', 'Unknown Device')} (#{device.fetch('osVersion', 'Unknown OS Version')})"]
  end
  configurations + devices
end

def junit(report)
  plan = (report['testNodes'] || []).find { |node| node['nodeType'] == 'Test Plan' }
  suites = (plan&.fetch('children', nil) || []).map { |suite| build_suite(suite) }
  environment = plan ? environment_properties(report) : []

  root = element('testsuites', **%i[tests failures skipped time].to_h { |key| [key, suites.sum { |suite| suite[key] }] })
  suites.each do |suite|
    suite[:xml].add_element(properties(environment)) unless environment.empty?
    root.add_element(suite[:xml])
  end
  root
end

def render(root)
  document = REXML::Document.new
  document << REXML::XMLDecl.new('1.0', 'UTF-8')
  document.add(root)
  String.new.tap { |output| REXML::Formatters::Pretty.new.write(document, output) }
end

abort "Usage: #{$PROGRAM_NAME} <bundle.xcresult> <report.junit>" unless ARGV.count == 2

stdout, stderr, status = Open3.capture3('xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', ARGV[0])
abort "xcresulttool failed: #{stderr}" unless status.success?

File.write(ARGV[1], render(junit(JSON.parse(stdout))))

# rubocop:enable Metrics
