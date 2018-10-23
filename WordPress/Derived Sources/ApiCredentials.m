#import "ApiCredentials.h"
@implementation ApiCredentials
+ (NSString *)client {
	return @"11";
}
+ (NSString *)secret {
	uint8_t bytes[] = {
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
	};
	char key[] = {
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
		***REMOVED***
	};
	long len = 64;
	NSMutableString *secret = [NSMutableString stringWithCapacity:len];
	for (int i = 0; i < len; i++ ) {
		char c = bytes[i] ^ key[i];
		[secret appendFormat:@"%c", c];
	}
	return [NSString stringWithString:secret];
}
+ (NSString *)pocketConsumerKey {
    return @"***REMOVED***";
}
+ (NSString *)crashlyticsApiKey {
    return @"***REMOVED***";
}
+ (NSString *)hockeyappAppId {
    return @"***REMOVED***";
}
+ (NSString *)giphyAppId {
    return @"***REMOVED***";
}
+ (NSString *)googlePlusClientId {
    return @"***REMOVED***";
}
+ (NSString *)googleLoginClientId {
    return @"***REMOVED***";
}
+ (NSString *)googleLoginSchemeId {
    return @"***REMOVED***";
}
+ (NSString *)googleLoginServerClientId {
    return @"***REMOVED***";
}
+ (NSString *)debuggingKey {
  return @"";
}
+ (NSString *)zendeskAppId {
    return @"***REMOVED***";
}
+ (NSString *)zendeskUrl {
    return @"***REMOVED***";
}
+ (NSString *)zendeskClientId {
    return @"***REMOVED***";
}
@end
