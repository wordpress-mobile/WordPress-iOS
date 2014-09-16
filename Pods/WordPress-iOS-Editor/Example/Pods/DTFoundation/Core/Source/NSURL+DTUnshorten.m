//
//  NSURL+DTUnshorten.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 6/2/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "NSURL+DTUnshorten.h"

@implementation NSURL (DTUnshorten)

- (void)unshortenWithCompletion:(NSURLUnshortenCompletionHandler)completion
{
	static NSCache *unshortenCache = nil;
	static dispatch_queue_t shortenQueue = NULL;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		unshortenCache = [[NSCache alloc] init];
		shortenQueue = dispatch_queue_create("DTUnshortenQueue", 0);
	});
	
	NSURL *shortURL = self;
	
	// assume HTTP if scheme is missing
	if (![self scheme])
	{
		NSString *str = [@"http://" stringByAppendingString:[self absoluteString]];
		shortURL = [NSURL URLWithString:str];
	}
	
	dispatch_async(shortenQueue, ^{
		// look into cache first
		NSURL *longURL = [unshortenCache objectForKey:shortURL];

		// nothing cached, load it
		if (!longURL)
		{
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:shortURL];
			request.HTTPMethod = @"HEAD";
			
			NSError *error = nil;
			NSHTTPURLResponse *response = nil;
			
			[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			
			longURL = [response URL];
			
			// cache result
			if (longURL)
			{
				[unshortenCache setObject:longURL forKey:shortURL];
			}
		}
		
		if (completion)
		{
			completion(longURL);
		}
	});
}

@end
