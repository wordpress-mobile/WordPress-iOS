//
//  DDNSLoggerLogger.h
//  Created by Peter Steinberger on 26.10.10.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface DDNSLoggerLogger : DDAbstractLogger <DDLogger>
{
}

+ (DDNSLoggerLogger *)sharedInstance;

- (void)setupWithBonjourServiceName:(NSString *)serviceName;

// Inherited from DDAbstractLogger

// - (id <DDLogFormatter>)logFormatter;
// - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

@end
