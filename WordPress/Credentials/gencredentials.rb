#!/usr/bin/env ruby -wKU

def print_client(client)
  printf("+ (NSString *)client {\n\treturn @\"#{client}\";\n}\n")
end

def print_secret(secret)
  printf <<-EOF
+ (NSString *)secret {
	uint8_t bytes[] = {
EOF
	printf "\t\t"
  length = secret.length
  key = Array.new(length) {|i| rand(256)}
  length.times do |i|
    if RUBY_VERSION < '1.9' then
      c = secret[i]
    else
      c = secret.getbyte(i)
    end
    c ^= key[i]
    printf("0x%02x", c)
    if (length > i + 1)
      printf(", ")
      printf("\n\t\t") if (i % 8 == 7)
    end
  end
  printf("\n\t};\n")
  printf("\tchar key[] = {\n\t\t")
  length.times do |i|
    c = key[i]
    printf("0x%02x", c)
    if (length > i + 1)
      printf(", ")
      printf("\n\t\t") if (i % 8 == 7)
    end
  end
  print <<-EOF

	};
	long len = #{length};
	NSMutableString *secret = [NSMutableString stringWithCapacity:len];
	for (int i = 0; i < len; i++ ) {
		char c = bytes[i] ^ key[i];
		[secret appendFormat:@"%c", c];
	}
	return [NSString stringWithString:secret];
}
EOF
end

def print_pocket(pocket)
    print <<-EOF
+ (NSString *)pocketConsumerKey {
    return @"#{pocket}";
}
EOF
end

def print_crashlytics(crashlytics)
print <<-EOF
+ (NSString *)crashlyticsApiKey {
    return @"#{crashlytics}";
}
EOF
end

def print_hockeyapp(hockeyapp)
print <<-EOF
+ (NSString *)hockeyappAppId {
    return @"#{hockeyapp}";
}
EOF
end

def print_googleplus(googleplus)
print <<-EOF
+ (NSString *)googlePlusClientId {
    return @"#{googleplus}";
}
EOF
end

def print_google_login_server(google_login_server)
print <<-EOF
+ (NSString *)googleLoginServerClientId {
    return @"#{google_login_server}";
}
EOF
end

def print_google_login_scheme(scheme_id)
print <<-EOF
+ (NSString *)googleLoginSchemeId {
    return @"#{scheme_id}";
}
EOF
end

def print_google_login_client(client_id)
print <<-EOF
+ (NSString *)googleLoginClientId {
    return @"#{client_id}";
}
EOF
end

def print_debugging_key(debugging_key)
print <<-EOF
+ (NSString *)debuggingKey {
  return @"#{debugging_key}";
}
EOF
end

def print_zendesk_app_id(zendesk_app_id)
print <<-EOF
+ (NSString *)zendeskAppId {
    return @"#{zendesk_app_id}";
}
EOF
end

def print_zendesk_url(zendesk_url)
print <<-EOF
+ (NSString *)zendeskUrl {
    return @"#{zendesk_url}";
}
EOF
end

def print_zendesk_client_id(zendesk_client_id)
print <<-EOF
+ (NSString *)zendeskClientId {
    return @"#{zendesk_client_id}";
}
EOF
end

def print_class(client, secret, pocket, crashlytics, hockeyapp, googleplus, google_client, google_scheme, google_login_server, debugging_key, zendesk_app_id, zendesk_url, zendesk_client_id)
  print <<-EOF
#import "ApiCredentials.h"
@implementation ApiCredentials
EOF
  print_client(client)
  print_secret(secret)
  print_pocket(pocket)
  print_crashlytics(crashlytics)
  print_hockeyapp(hockeyapp)
  print_googleplus(googleplus)
  print_google_login_client(google_client)
  print_google_login_scheme(google_scheme)
  print_google_login_server(google_login_server)
  print_debugging_key(debugging_key)
  print_zendesk_app_id(zendesk_app_id)
  print_zendesk_url(zendesk_url)
  print_zendesk_client_id(zendesk_client_id)
  printf("@end\n")
end

rawpath = ENV['WPCOM_CONFIG']
if rawpath.nil?
    $stderr.puts "error: file WPCOM_CONFIG not defined"
    exit 1
end

path = File.expand_path(rawpath)
unless File.exist?(path)
  $stderr.puts "error: file #{path} not found"
  exit 1
end

client = nil
secret = nil
pocket = nil
crashlytics = nil
hockeyapp = nil
googleplus = nil
google_client = nil
google_scheme = nil
google_login_server = nil
debugging_key = nil
zendesk_app_id = nil
zendesk_url = nil
zendesk_client_id = nil
File.open(path) do |f|
  f.each_line do |l|
    (k,value) = l.split("=")
    next if !value
    value.strip!
    if k == "WPCOM_APP_ID"
      client = value
    elsif k == "WPCOM_APP_SECRET"
      secret = value
    elsif k == "POCKET_CONSUMER_KEY"
      pocket = value
    elsif k == "CRASHLYTICS_API_KEY"
      crashlytics = value
    elsif k == "HOCKEYAPP_APP_ID"
      hockeyapp = value
    elsif k == "GOOGLE_PLUS_CLIENT_ID"
      googleplus = value
    elsif k == "GOOGLE_LOGIN_CLIENT_ID"
      google_client = value
    elsif k == "GOOGLE_LOGIN_SCHEME_ID"
      google_scheme = value
    elsif k == "GOOGLE_LOGIN_SERVER_ID"
      google_login_server = value
    elsif k == "DEBUGGING_KEY"
      debugging_key = value
    elsif k == "ZENDESK_APP_ID"
      zendesk_app_id = value
    elsif k == "ZENDESK_URL"
      zendesk_url = value
    elsif k == "ZENDESK_CLIENT_ID"
      zendesk_client_id = value
    end
  end
end

if client.nil?
  $stderr.puts "warning: Client not found"
  exit 2
end

if secret.nil?
  $stderr.puts "warning: Secret not found"
  exit 3
end

configuration = ENV["CONFIGURATION"]
if !configuration.nil? && ["Release", "Release-Internal"].include?(configuration)

  if crashlytics.nil?
    $stderr.puts "warning: Crashlytics API key not found"
  end

  if pocket.nil?
    $stderr.puts "warning: Pocket API key not found"
  end

  if googleplus.nil?
    $stderr.puts "warning: Google Plus API key not found"
  end

  if google_id.nil?
    $stderr.puts "warning: Google Login Client ID not found"
  end

  if configuration == "Release-Internal"
    if hockeyapp.nil?
      $stderr.puts "warning: HockeyApp App Id not found"
    end 
  end
  
  if zendesk_app_id.nil? || zendesk_url.nil? || zendesk_client_id.nil?
      $stderr.puts "warning: Zendesk keys not found"
  end
end

print_class(client, secret, pocket, crashlytics, hockeyapp, googleplus, google_client, google_scheme, google_login_server, debugging_key, zendesk_app_id, zendesk_url, zendesk_client_id)
