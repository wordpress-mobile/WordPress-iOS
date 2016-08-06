#!/usr/bin/env ruby

begin
  require 'plist'
rescue LoadError
  puts "This script requires the \'plist\' gem. You can install it by running \'gem install plist\'"
  exit
end

internal_plist = Plist::parse_xml('./WordPress/WordPress-Internal-Info.plist')

base_version_number = internal_plist["CFBundleVersion"]

# Check if we need to add a .0 to the end(i.e. 4.2 -> 4.2.0)
base_version_number = "#{base_version_number}.0" if base_version_number =~ /^\d+\.\d+$/
version_number_with_date = "#{base_version_number}.#{Time.now.strftime("%Y%m%d")}"

internal_plist["CFBundleVersion"] = version_number_with_date
internal_plist["CFBundleShortVersionString"] = version_number_with_date
internal_plist.save_plist("./WordPress/WordPress-Internal-Info.plist")
