#import <Foundation/Foundation.h>
@import CocoaLumberjack;

@interface WPCrashlyticsLogger : DDAbstractLogger

+ (instancetype)sharedInstance;

@end
