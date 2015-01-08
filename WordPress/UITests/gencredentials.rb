#!/usr/bin/env ruby -wKU

def print_credentials(name, user, password)
    print <<-EOF
NSString * const #{name}User = @"#{user}";
NSString * const #{name}Password = @"#{password}";
EOF
end

def print_class(one_step_user, one_step_password, two_step_user, two_step_password, self_hosted_user, self_hosted_password, self_hosted_site_url, self_hosted_site_name)
  print <<-EOF
#import "WordPressTestCredentials.h"
EOF
  print_credentials("oneStep", one_step_user, one_step_password);
  print_credentials("twoStep", two_step_user, two_step_password);
  print_credentials("selfHosted", self_hosted_user, self_hosted_password);
  print <<-EOF
NSString * const selfHostedSiteURL = @"#{self_hosted_site_url}";
NSString * const selfHostedSiteName = @"#{self_hosted_site_name}";
EOF
end

rawpath = "~/.wp_test_credentials"
if rawpath.nil?
    $stderr.puts "error: file ~/.wp_test_credentials not defined"
    exit 1
end

path = File.expand_path(rawpath)
unless File.exists?(path)
  $stderr.puts "error: file #{path} not found"
  exit 1
end

one_step_user = nil
one_step_password = nil
two_step_user = nil
two_step_password = nil
self_hosted_user = nil
self_hosted_password = nil
self_hosted_site_url = nil
self_hosted_site_name = nil
File.open(path) do |f|
  f.each_line do |l|
    (k,v) = l.split("=")
    if k == "oneStepUser"
      one_step_user = v.chomp
    elsif k == "oneStepPassword"
      one_step_password = v.chomp
    elsif k == "twoStepUser"
      two_step_user = v.chomp
    elsif k == "twoStepPassword"
      two_step_password = v.chomp
    elsif k == "selfHostedUser"
      self_hosted_user = v.chomp
    elsif k == "selfHostedPassword"
      self_hosted_password = v.chomp
    elsif k == "selfHostedSiteURL"
      self_hosted_site_url = v.chomp
    elsif k == "selfHostedSiteName"
      self_hosted_site_name = v.chomp
    else
      $stderr.puts "warning: Unknown key #{k}"
    end
  end
end

print_class(one_step_user, one_step_password, two_step_user, two_step_password, self_hosted_user, self_hosted_password, self_hosted_site_url, self_hosted_site_name)
