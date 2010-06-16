//
//  HTTPHelper.m
//
//  Created by Tyler Neylon on 6/20/09.
//  Copyright 2009 Bynomial. All rights reserved.
//
//  Helper class for working with HTTP connections.
//

#import "HTTPHelper.h"

@interface HTTPHelper()
- (id) init;
- (void) clearConnection;
@end

@implementation HTTPHelper

@synthesize timeOut;

+ (HTTPHelper*) sharedInstance {
	static HTTPHelper* instance = nil;
	if (instance == nil) instance = [[HTTPHelper alloc] init];
	return instance;
}

- (NSError*)synchronousGetURLAsString:(NSString *)URLAsString replyData:(NSString**)dataStr {
	
	NSURLRequestCachePolicy policy = NSURLRequestUseProtocolCachePolicy;
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLAsString]
														   cachePolicy:policy
													   timeoutInterval:timeOut];
	[request setValue:@"WordPress for iOS" forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"content-type"];
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	NSURLResponse* response;
	NSError* error;
	NSData* rawData = [NSURLConnection sendSynchronousRequest:request
											returningResponse:&response
														error:&error];
	if (error == nil) {
		*dataStr = [[NSString alloc] initWithBytes:[rawData bytes]
											length:[rawData length]
										  encoding:NSUTF8StringEncoding];
	}
	else {
		//NSLog(@"%@", error);
	}
	
	return error;
}

- (void)asynchronousGetURLAsString:(NSString *)URLAsString
						  delegate: (id<HTTPHelperDelegate>) delegate_ {
	[self clearConnection];
	NSURLRequestCachePolicy policy = NSURLRequestUseProtocolCachePolicy;
	NSMutableURLRequest *request = [NSMutableURLRequest
									requestWithURL:[NSURL
													URLWithString:URLAsString]
									cachePolicy:policy
									timeoutInterval:timeOut];
	[request setValue:@"WordPress for iOS" forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"content-type"];
	[request setValue:@"close" forHTTPHeaderField:@"Connection"];
	delegate = delegate_;
	connection = [[NSURLConnection alloc]
				  initWithRequest:request
				  delegate:self
				  startImmediately:YES];
	state = HTTPStateAwaitingFullResponse;
	dataSoFar = [[NSMutableData alloc] init];
}

- (NSError *)synchronousPostUrlAsString:(NSString *)UrlAsString withRequest:(NSString *)requestString replyData:(NSString **)reply {	
	NSError *error;
	NSData *data = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:UrlAsString]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:data];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[request setTimeoutInterval:10];
	
	NSHTTPURLResponse *response = NULL;
	NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	returnData = nil;
	[request release];
	
	return error;
}

#pragma mark private methods

- (id) init {
	self = [super init];
	if (self == nil) return nil;
	timeOut = 35;
	state = HTTPStateNoConnection;
	return self;
}

- (void) clearConnection {
	if (state == HTTPStateAwaitingFullResponse) {
		[connection cancel];
		state = HTTPStateNoConnection;
	}
	[connection release];
	connection = nil;
	[dataSoFar release];
	dataSoFar = nil;
}

#pragma mark NSURLConnection Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (delegate == nil) return;
	[dataSoFar appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (delegate) {
		NSString* dataStr = [[[NSString alloc] initWithData:dataSoFar encoding:NSUTF8StringEncoding] autorelease];
		[delegate httpSuccessWithDataString:dataStr];
	}
	[self clearConnection];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[delegate httpFailWithError:error];
	[self clearConnection];
}

@end