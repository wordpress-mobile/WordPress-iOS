#import <Foundation/Foundation.h>
#import "WPDDLogWrapper.h"

// Logging Framework Lumberjack
#import <CocoaLumberjack/CocoaLumberjack.h>

#if DEBUG
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#endif

#ifndef COCOA_LUMBERJACK
#define COCOA_LUMBERJACK
int ddLogLevel = DDLogLevelInfo;
#endif

@implementation WPDDLogWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
#if DEBUG
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    }
    
    return self;
}

+ (void) logVerbose:(NSString *)message {
    DDLogVerbose(message);
}

+ (void) logError:(NSString *)message {
    DDLogError(message);
}

+ (void) logInfo:(NSString *)message {
    DDLogInfo(message);
}

@end