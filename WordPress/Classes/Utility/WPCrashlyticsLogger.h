#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface WPCrashlyticsLogger : DDAbstractLogger

+ (instancetype)sharedInstance;

@end
