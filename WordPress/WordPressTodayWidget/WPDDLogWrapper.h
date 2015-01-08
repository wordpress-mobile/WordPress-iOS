#import <Foundation/Foundation.h>

@interface WPDDLogWrapper : NSObject

+ (void) logVerbose:(NSString *)message;
+ (void) logError:(NSString *)message;
+ (void) logInfo:(NSString *)message;

@end
