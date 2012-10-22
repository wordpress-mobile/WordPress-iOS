//
//  FileLogger.m
//  WordPress
//
//  Created by Jorge Bernal on 2/23/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FileLogger.h"

NSString *FileLoggerPath() {
	static NSString *filePath;
	
	if (filePath == nil) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		filePath = [documentsDirectory stringByAppendingPathComponent:@"wordpress.log"];		
	}
	
	return filePath;
}

@implementation FileLogger

- (id) init {
    self = [super init];
	if (self) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:FileLoggerPath()])
			[fileManager createFileAtPath:FileLoggerPath()
								 contents:nil
							   attributes:nil];
		logFile = [NSFileHandle fileHandleForWritingAtPath:FileLoggerPath()];
		[logFile seekToEndOfFile];
	}
	return self;
}

- (void)flush {
	[logFile synchronizeFile];
}

- (void)log:(NSString *)message {
	[logFile writeData:[[NSString stringWithFormat:@"%@ %@\n", [NSDate date], message] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)reset {
    [logFile truncateFileAtOffset:0];
}

+ (void)log:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
#if !FILELOGGER_ONLY_NSLOG_ON_DEBUG || defined(DEBUG)
	NSLog(@"# %@", message); // The # symbol indicates that the message will be logged to file, useful when looking at the console
#endif
	[[FileLogger sharedInstance] log:message];
    va_end(ap);
}

+ (FileLogger *)sharedInstance {
	static FileLogger *instance = nil;
	if (instance == nil) instance = [[FileLogger alloc] init];
	return instance;
}

@end
