//
//  FileLogger.h
//  WordPress
//
//  Created by Jorge Bernal on 2/23/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FILELOGGER_ONLY_NSLOG_ON_DEBUG 1
NSString *FileLoggerPath();

@interface FileLogger : NSObject {
	NSFileHandle *logFile;
}
+ (FileLogger *)sharedInstance;
- (void)log:(NSString *)message;
+ (void)log:(NSString *)format, ...;
- (void)flush;
- (void)reset;
@end

#define WPFLog(fmt, ...) [FileLogger log:fmt, ##__VA_ARGS__]
#define WPFLogMethod() [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
