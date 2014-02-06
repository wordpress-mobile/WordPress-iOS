//
//  DDFileLogger+Simperium.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/30/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "DDFileLogger+Simperium.h"


@implementation DDFileLogger (Simperium)

+ (DDFileLogger*)sharedInstance {
	static DDFileLogger *logger;
    static dispatch_once_t _once;
	
    dispatch_once(&_once, ^{
		logger = [[DDFileLogger alloc] init];
	});
	
	return logger;
}

- (NSData*)exportLogfiles {
	NSArray *logfiles = [self.logFileManager sortedLogFilePaths];
	NSMutableData *export = [NSMutableData data];
	
	for (NSString *path in logfiles) {
		NSData *logfile = [NSData dataWithContentsOfFile:path];
		if (logfile.length) {
			[export appendData:logfile];
		}
	}
	
	return export;
}

@end
