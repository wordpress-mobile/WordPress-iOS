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

def print_mixpanel(mixpanel_dev, mixpanel_prod)
    print <<-EOF
+ (NSString *)mixpanelAPIToken {
#ifdef DEBUG
    return @"#{mixpanel_dev}";
#else
    return @"#{mixpanel_prod}";
#endif
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

def print_helpshift_api_key(helpshift_api_key)
print <<-EOF
+ (NSString *)helpshiftAPIKey {
    return @"#{helpshift_api_key}";
}
EOF
end

def print_helpshift_domain_name(helpshift_domain_name)
print <<-EOF
+ (NSString *)helpshiftDomainName {
    return @"#{helpshift_domain_name}";
}
EOF
end

def print_helpshift_app_id(helpshift_app_id)
print <<-EOF
+ (NSString *)helpshiftAppId {
    return @"#{helpshift_app_id}";
}
EOF
end

def print_simperium(simperium_api_key, simperium_app_id)
print <<-EOF
+ (NSString *)simperiumAppId {
	return @"#{simperium_app_id}";
}
+ (NSString *)simperiumAPIKey {
	return @"#{simperium_api_key}";
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

def print_lookback_token(lookback_token)
print <<-EOF
+ (NSString *)lookbackToken {
  return @"#{lookback_token}";
}
EOF
end

def print_appbotx_api_key(appbotx_api_key)
print <<-EOF
+ (NSString *)appbotXAPIKey {
  return @"#{appbotx_api_key}";
}
EOF
end

def print_class(client, secret, pocket, mixpanel_dev, mixpanel_prod, crashlytics, hockeyapp, googleplus, helpshift_api_key, helpshift_domain_name, helpshift_app_id, simperium_api_key, simperium_app_id, debugging_key, lookback_token, appbotx_api_key)
  print <<-EOF
#import "WordPressComApiCredentials.h"
@implementation WordPressComApiCredentials
EOF
  print_client(client)
  print_secret(secret)
  print_pocket(pocket)
  print_mixpanel(mixpanel_dev, mixpanel_prod)
  print_crashlytics(crashlytics)
  print_hockeyapp(hockeyapp)
  print_googleplus(googleplus)
  print_helpshift_api_key(helpshift_api_key)
  print_helpshift_domain_name(helpshift_domain_name)
  print_helpshift_app_id(helpshift_app_id)
  print_simperium(simperium_api_key, simperium_app_id)
  print_debugging_key(debugging_key)
  print_lookback_token(lookback_token)
  print_appbotx_api_key(appbotx_api_key)
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
mixpanel_dev = nil
mixpanel_prod = nil
crashlytics = nil
hockeyapp = nil
googleplus = nil
simperium_api_key = nil
simperium_app_id = nil
helpshift_api_key = nil
helpshift_domain_name = nil
helpshift_app_id = nil
debugging_key = nil
lookback_token = nil
appbotx_api_key = nil
File.open(path) do |f|
  f.each_line do |l|
    (k,v) = l.split("=")
    if k == "WPCOM_APP_ID"
      client = v.chomp
    elsif k == "WPCOM_APP_SECRET"
      secret = v.chomp
    elsif k == "POCKET_CONSUMER_KEY"
      pocket = v.chomp
    elsif k == "MIXPANEL_DEVELOPMENT_API_TOKEN"
      mixpanel_dev = v.chomp
    elsif k == "MIXPANEL_PRODUCTION_API_TOKEN"
      mixpanel_prod = v.chomp
    elsif k == "CRASHLYTICS_API_KEY"
      crashlytics = v.chomp
    elsif k == "HOCKEYAPP_APP_ID"
      hockeyapp = v.chomp
    elsif k == "GOOGLE_PLUS_CLIENT_ID"
      googleplus = v.chomp
    elsif k == "SIMPERIUM_API_KEY"
      simperium_api_key = v.chomp
    elsif k == "SIMPERIUM_APP_ID"
      simperium_app_id = v.chomp
    elsif k == "HELPSHIFT_API_KEY"
      helpshift_api_key = v.chomp
    elsif k == "HELPSHIFT_DOMAIN_NAME"
      helpshift_domain_name = v.chomp
    elsif k == "HELPSHIFT_APP_ID"
      helpshift_app_id = v.chomp
    elsif k == "DEBUGGING_KEY"
      debugging_key = v.chomp
    elsif k == "LOOKBACK_TOKEN"
      lookback_token = v.chomp
    elsif k == "APPBOTX_API_KEY"
      appbotx_api_key = v.chomp
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

  if mixpanel_dev.nil? || mixpanel_prod.nil?
    $stderr.puts "warning: Mixpanel keys not found"
  end

  if crashlytics.nil?
    $stderr.puts "warning: Crashlytics API key not found"
  end

  if pocket.nil?
    $stderr.puts "warning: Pocket API key not found"
  end

  if googleplus.nil?
    $stderr.puts "warning: Google Plus API key not found"
  end

  if simperium_api_key.nil? || simperium_app_id.nil?
    $stderr.puts "warning: Simperium keys not found"
  end

  if helpshift_api_key.nil? || helpshift_domain_name.nil? || helpshift_app_id.nil?
    $stderr.puts "warning: Helpshift keys not found"
  end

  if lookback_token.nil?
    $stderr.puts "warning: Lookback token not found"
  end

  if appbotx_api_key.nil?
    $stderr.puts "warning: AppbotX API key not found"
  end

  if configuration == "Release-Internal"
    if hockeyapp.nil?
      $stderr.puts "warning: HockeyApp App Id not found"
    end 
  end
end

print_class(client, secret, pocket, mixpanel_dev, mixpanel_prod, crashlytics, hockeyapp, googleplus, helpshift_api_key, helpshift_domain_name, helpshift_app_id, simperium_api_key, simperium_app_id, debugging_key, lookback_token, appbotx_api_key)
