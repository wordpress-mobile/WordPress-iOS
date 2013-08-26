//
//  DTLog.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.08.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTLog.h"
#import <asl.h>

DTLogLevel DTCurrentLogLevel = DTLogLevelInfo;

#if DEBUG

// set default handler for debug mode
DTLogBlock DTLogHandler = ^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	
	DTLogMessagev(logLevel, format, args);
	
	va_end(args);
};

#else

// set no default handler for non-DEBUG mode
DTLogBlock DTLogHandler = NULL;

#endif

#pragma mark - Logging Functions

void DTLogSetLoggerBlock(DTLogBlock handler)
{
	DTLogHandler = [handler copy];
}

void DTLogSetLogLevel(DTLogLevel logLevel)
{
	DTCurrentLogLevel = logLevel;
}

void DTLogMessagev(DTLogLevel logLevel, NSString *format, va_list args)
{
	NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
	aslclient client = asl_open(NULL, [facility UTF8String], ASL_OPT_STDERR); // also log to stderr
	
	aslmsg msg = asl_new(ASL_TYPE_MSG);
	asl_set(msg, ASL_KEY_READ_UID, "-1");  // without this the message cannot be found by asl_search
	
	// convert to via NSString, since printf does not know %@
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	
	asl_log(client, msg, logLevel, "%s", [message UTF8String]);

	asl_free(msg);
	
	va_end(args);
}

void DTLogMessage(DTLogLevel logLevel, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	
	DTLogMessagev(logLevel, format, args);
	
	va_end(args);
}

NSArray *DTLogGetMessages(void)
{
	aslmsg query, message;
	int i;
	const char *key, *val;
	
	NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
	
	query = asl_new(ASL_TYPE_QUERY);
	
	// search only for current app messages
	asl_set_query(query, ASL_KEY_FACILITY, [facility UTF8String], ASL_QUERY_OP_EQUAL);
	
	aslresponse response = asl_search(NULL, query);
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	while ((message = aslresponse_next(response)))
	{
		NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
		
		for (i = 0; ((key = asl_key(message, i))); i++)
		{
			NSString *keyString = [NSString stringWithUTF8String:(char *)key];
			
			val = asl_get(message, key);
			
			NSString *string = val?[NSString stringWithUTF8String:val]:@"";
			[tmpDict setObject:string forKey:keyString];
		}
		
		[tmpArray addObject:tmpDict];
	}
	
	asl_free(query);
	aslresponse_free(response);
	
	if ([tmpArray count])
	{
		return [tmpArray copy];
	}
	
	return nil;
}
