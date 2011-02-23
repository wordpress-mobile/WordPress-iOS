//
//  FileLogger.h
//  WordPress
//
//  Created by Jorge Bernal on 2/23/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileLogger : NSObject {
	NSFileHandle *logFile;
}
+ (FileLogger *)sharedInstance;
- (void)log:(NSString *)format, ...;
- (void)flush;
@end

#define WPFLog(fmt, ...) [[FileLogger sharedInstance] log:fmt, ##__VA_ARGS__]