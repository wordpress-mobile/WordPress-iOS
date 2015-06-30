#import "DDLogSwift.h"

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

@implementation DDLogSwift

+ (void) logError:(NSString *)message {
    DDLogError(message);
}

+ (void) logWarn:(NSString *)message {
    DDLogWarn(message);
}

+ (void) logInfo:(NSString *)message {
    DDLogInfo(message);
}

+ (void) logDebug:(NSString *)message {
    DDLogDebug(message);
}

+ (void) logVerbose:(NSString *)message {
    DDLogInfo(message);
}
@end