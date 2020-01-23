#!/usr/bin/env ruby

require 'find'
Find.find('./fastlane/screenshots') { |e|
    next if File.directory?(e)
    next if File.extname(e) != ".png"

    info = `identify "#{e}"`.sub(e, '').split
    dimensions = info[1].split('x')

    if e.include?('iPad') && dimensions[0] < dimensions[1]
        `convert "#{e}" -rotate -90 "#{e}"`
        puts "✅ #{e}"
    end
}
