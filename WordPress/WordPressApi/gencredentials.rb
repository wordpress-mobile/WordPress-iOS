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

def print_class(client, secret)
  print <<-EOF
#import "WordPressComApiCredentials.h"
@implementation WordPressComApiCredentials
EOF
  print_client(client)
  print_secret(secret)
  printf("@end\n")
end

path = File.expand_path("~/.wpcom_app_credentials")
unless File.exists?(path)
  $stderr.puts "error: file #{path} not found"
  exit 1
end

client = nil
secret = nil
File.open(path) do |f|
  f.lines.each do |l|
    (k,v) = l.split("=")
    if k == "WPCOM_APP_ID"
      client = v.chomp
    elsif k == "WPCOM_APP_SECRET"
      secret = v.chomp
    else
      $stderr.puts "warning: Unknown key #{k}"
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

print_class(client, secret)
