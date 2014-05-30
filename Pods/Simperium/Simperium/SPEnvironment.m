//
//  SPEnvironment.m

#import "SPEnvironment.h"

// Production
NSString* const SPBaseURL			= @"https://api.simperium.com/1/";
NSString* const SPAuthURL			= @"https://auth.simperium.com/1/";
NSString* const SPWebsocketURL		= @"wss://api.simperium.com/sock/1";
NSString* const SPReachabilityURL	= @"api.simperium.com";

NSString* const SPAPIVersion		= @"1.1";

#if TARGET_OS_IPHONE
NSString* const SPLibraryID			= @"ios";
#else
NSString* const SPLibraryID			= @"osx";
#endif

// TODO: Update this automatically via a script that looks at current git tag
NSString* const SPLibraryVersion	= @"0.6.5";
