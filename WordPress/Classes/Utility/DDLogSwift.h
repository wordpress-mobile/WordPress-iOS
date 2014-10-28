#import <Foundation/Foundation.h>

@interface DDLogSwift : NSObject

+ (void) logError:(NSString *)message;
+ (void) logWarn:(NSString *)message;
+ (void) logInfo:(NSString *)message;
+ (void) logDebug:(NSString *)message;
+ (void) logVerbose:(NSString *)message;

@end