#!/usr/bin/env ruby

def check_dependencies
  unless Gem::Specification::find_all_by_name("shenzhen").any?
    print "This script requires the \'shenzhen\' gem. You can install it by running \'gem install shenzhen\'\n"
    exit
  end
end

def update_internal_version_plist
  require 'plist'

  internal_plist = Plist::parse_xml('./WordPress/WordPress-Internal-Info.plist')

  base_version_number = internal_plist["CFBundleVersion"]

  # Check if we need to add a .0 to the end(i.e. 4.2 -> 4.2.0)
  base_version_number = "#{base_version_number}.0" if base_version_number =~ /^\d+\.\d+$/
  version_number_with_date = "#{base_version_number}.#{Time.now.strftime("%Y%m%d")}"

  internal_plist["CFBundleVersion"] = version_number_with_date
  internal_plist["CFBundleShortVersionString"] = version_number_with_date
  internal_plist.save_plist("./WordPress/WordPress-Internal-Info.plist")
end

def build_ipa
  update_internal_version_plist
  print "Generating WordPress-Internal Archive\n"
  Kernel.system('ipa build -w WordPress.xcworkspace/ -s "WordPress Internal" -c Release-Internal')
end

def get_hockey_app_api_token
  unless File.exist?(".hockey_app_credentials")
    print ".hockey_app_credentials must exist for this script to work properly\n"
    exit
  end

  hockey_app_api_token = nil
  File.open(".hockey_app_credentials") do |f|
    f.each_line do |l|
      (k,v) = l.split("=")
      if k.downcase == "hockey_app_token"
        hockey_app_api_token = v.chomp
      end
    end
  end

  if hockey_app_api_token.nil?
    print ".hockey_app_credentials didn't have a value for HOCKEY_APP_TOKEN\n"
    exit
  end

  hockey_app_api_token
end

def upload_ipa_to_hockey_app(hockey_app_api_token)
  print "Uploading .ipa to HockeyApp\n"
  Kernel.system("ipa distribute:hockeyapp -f WordPress.ipa --token #{hockey_app_api_token} --mandatory")
end

if Dir.pwd =~ /Scripts/
  puts "Must run script from root folder"
  exit
end

check_dependencies
build_ipa
upload_ipa_to_hockey_app(get_hockey_app_api_token)

File.delete("WordPress.app.dSYM.zip") if File.exist?("WordPress.app.dSYM.zip")
File.delete("WordPress.ipa") if File.exist?("WordPress.ipa")

Kernel.system("git checkout WordPress/WordPress-Internal-Info.plist")
