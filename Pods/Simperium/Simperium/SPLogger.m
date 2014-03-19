//
//  SPLogger.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 02/13/14.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPLogger.h"




#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPLogger ()
@property (nonatomic, strong) dispatch_queue_t queue;
@end


#pragma mark ====================================================================================
#pragma mark SPLogger
#pragma mark ====================================================================================

@implementation SPLogger

- (instancetype)init {
	if ((self = [super init])) {
		self.sharedLogLevel = SPLogLevelsOff;
        self.queue = dispatch_queue_create("com.simperium.SPLogger", NULL);
	}
	return self;
}

+ (instancetype)sharedInstance {
	static SPLogger* logger;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		logger = [[[self class] alloc] init];
	});
	
	return logger;
}

- (void)logWithLevel:(SPLogLevels)level flag:(SPLogFlags)flag format:(NSString*)format, ... {

	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	dispatch_async(self.queue, ^{
		if (_delegate) {
			[_delegate handleLogMessage:message];
		}
		
		NSLog(@"%@", message);
	});
}

@end
