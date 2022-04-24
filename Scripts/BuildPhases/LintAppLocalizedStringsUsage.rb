#!/usr/bin/env ruby

require 'xcodeproj'

REPO_ROOT = Pathname.new(__dir__) + '../..'

def lint(file_path:, target_name:)
  violations_count = 0
  File.foreach(file_path, mode: 'rb:BOM|UTF-8').with_index do |line, line_no|
    next if line.match? %r(^\s*//) # Skip commented lines

    col_no = line.index('NSLocalizedString')
    next if col_no.nil?

    puts "#{file_path}:#{line_no+1}:#{col_no+1}: error: Use `AppLocalizedString` instead of `NSLocalizedString` in source files that are used in the `#{target_name}` extension target. See paNNhX-nP-p2 for more info."
    violations_count += 1
  end
  violations_count
end

## Main ##

project = Xcodeproj::Project.open(REPO_ROOT + 'WordPress/WordPress.xcodeproj')
targets_to_analyze = if ARGV.count.positive?
  project.targets.select { |t| t.name == ARGV.first }
else
  project.targets.select { |t| t.is_a?(Xcodeproj::Project::Object::PBXNativeTarget) && t.extension_target_type? }
end

violations_count = 0
targets_to_analyze.map do |target|
  build_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
  next if build_phase.nil?

  puts "Linting extension target #{target.name} for improper NSLocalizedString usage..."
  source_files = build_phase.files_references.map(&:real_path).select { |f| ['.m', '.swift'].any? { |ext| f.extname == ext } }
  source_files.each { |f| violations_count += lint(file_path: f, target_name: target.name) }
end

exit 1 if violations_count > 0
