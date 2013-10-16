//
//  FileLogger.m
//  WordPress
//
//  Created by Jorge Bernal on 2/23/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FileLogger.h"
#import <Crashlytics/Crashlytics.h>
#import "DDFileLogger.h"
#import "WordPressAppDelegate.h"

NSString *FileLoggerPath() {
    static NSString *filePath;
	
	if (filePath == nil) {
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        DDFileLogger *logger = appDelegate.fileLogger;
        filePath = [logger.logFileManager.sortedLogFileNames objectAtIndex:0];
	}
	
	return filePath;
}

@implementation FileLogger

- (void)flush {
    // This method is no longer appropriate
    
}

- (void)log:(NSString *)message {
    NSString *logMessage = [NSString stringWithFormat:@"%@ %@\n", [NSDate date], message];
    DDLogInfo(logMessage);
}

- (void)reset {
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    DDFileLogger *logger = appDelegate.fileLogger;
    
    [logger rollLogFile];
}

+ (void)log:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
#if !FILELOGGER_ONLY_NSLOG_ON_DEBUG || defined(DEBUG)
	NSLog(@"# %@", message); // The # symbol indicates that the message will be logged to file, useful when looking at the console
#endif
	DDLogInfo(message);
    va_end(ap);
}

+ (FileLogger *)sharedInstance {
	static FileLogger *instance = nil;
	if (instance == nil) instance = [[FileLogger alloc] init];
	return instance;
}

+ (void)setLoggingLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (int)loggingLevel
{
    return ddLogLevel;
}


@end
