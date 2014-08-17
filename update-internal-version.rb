#!/usr/bin/env ruby

begin
  require 'plist'
rescue LoadError
  puts "This script requires the \'plist\' gem. You can install it by running \'gem install plist\'"
  exit
end

print "Enter the version number to use as the base (i.e. 4.2.0) "
base_version_number = gets.chomp

version_number_with_date = "#{base_version_number}.#{Time.now.strftime("%Y%m%d")}"

internal_plist = Plist::parse_xml('./WordPress/WordPress-Internal-Info.plist')
internal_plist["CFBundleVersion"] = version_number_with_date
internal_plist["CFBundleShortVersionString"] = version_number_with_date
internal_plist.save_plist("./WordPress/WordPress-Internal-Info.plist")
