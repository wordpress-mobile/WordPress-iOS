//
//  FileLogger.m
//  WordPress
//
//  Created by Jorge Bernal on 2/23/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "FileLogger.h"


@implementation FileLogger

- (void)dealloc {
	[logFile dealloc]; logFile = nil;
	[super dealloc];
}

- (id) init {
	if (self == [super init]) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"migration.log"];		
		logFile = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
	}
	return self;
}

- (void)flush {
	[logFile synchronizeFile];
}

- (void)log:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	NSString *message = [NSString stringWithFormat:format, ap];
	NSLog(message);
	[logFile writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (FileLogger *)sharedInstance {
	static FileLogger *instance = nil;
	if (instance == nil) instance = [[FileLogger alloc] init];
	return instance;
}

@end
