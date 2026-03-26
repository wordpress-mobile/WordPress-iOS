#!/usr/bin/env ruby
# frozen_string_literal: true

file_path = ARGV[0]
command = ARGV[1]

abort 'Usage: inspect-ai-test-case.rb FILE_PATH COMMAND [ARGS...]' if file_path.nil? || command.nil?

content = File.read(file_path)
sections = {}
current_name = nil
buffer = []

content.each_line do |line|
  heading = line.match(/^##\s+(.+)$/)
  if heading
    sections[current_name] = buffer.join.strip if current_name
    current_name = heading[1].strip
    buffer = []
  elsif current_name
    buffer << line
  end
end
sections[current_name] = buffer.join.strip if current_name

case command
when 'title'
  title = content[/^#\s+(.+)$/, 1] || File.basename(file_path, '.md')
  print title
when 'slug'
  slug = File.basename(file_path, '.md').downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
  print slug
when 'section-present'
  pattern = Regexp.new(ARGV.fetch(2), Regexp::IGNORECASE)
  matched = sections.any? { |name, body| name.match?(pattern) && !body.to_s.strip.empty? }
  print(matched ? '1' : '0')
else
  abort "Unknown command: #{command}"
end
