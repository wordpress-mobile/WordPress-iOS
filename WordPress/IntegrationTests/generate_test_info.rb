#!/usr/bin/env ruby -wKU

def print_auth_info(integration_tests_wpcom_username, integration_tests_wpcom_password)
print <<-EOF
+ (NSString *)WPComUsername {
    return @"#{integration_tests_wpcom_username}";
}

+ (NSString *)WPComPassword {
    return @"#{integration_tests_wpcom_password}";
}
EOF
end

def print_class(integration_tests_wpcom_username, integration_tests_wpcom_password)
print <<-EOF
#import "IntegrationTestsInfo.h"
@implementation IntegrationTestsInfo
EOF
print_auth_info(integration_tests_wpcom_username, integration_tests_wpcom_password)
printf("@end\n")
end

rawpath = '~/.WPiOS_integration_tests'
path = File.expand_path(rawpath)
unless File.exists?(path)
  $stderr.puts "error: file #{path} not found"
  exit 1
end

integration_tests_wpcom_username = nil
integration_tests_wpcom_password = nil

File.open(path) do |f|
  f.each_line do |l|
    (k,v) = l.split("=")
    if k == "WPCOM_USERNAME"
      integration_tests_wpcom_username = v.chomp
    elsif k == "WPCOM_PASSWORD"
      integration_tests_wpcom_password = v.chomp
    end
  end
end

print_class(integration_tests_wpcom_username, integration_tests_wpcom_password)