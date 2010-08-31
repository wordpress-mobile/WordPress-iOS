//
//  Cocoa XML-RPC Client Framework
//  XMLRPCConnection.m
//
//  Created by Eric J. Czarny on Thu Jan 15 2004.
//  Copyright (c) 2004 Divisible by Zero.
//

//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without 
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or 
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "XMLRPCRequest.h"
#import "XMLRPCEncoder.h"

@implementation XMLRPCRequest

- (id)initWithHost: (NSURL *)host
{
	if (self = [super init])
	{
		if (host != nil)
		{
			_request = [[NSMutableURLRequest alloc] initWithURL: host];
		}
		else
		{
			_request = [[NSMutableURLRequest alloc] init];
		}
		
		_encoder = [[XMLRPCEncoder alloc] init];
		
		[_request setTimeoutInterval:120.0f];
		
		// TODO: this should not be kept in the generic classes.
		NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
		[self setUserAgent:[NSString stringWithFormat:@"wp-iphone/%@",version]];
	}
	
	return self;
}

#pragma mark -

- (void)setHost: (NSURL *)host
{
	[_request setURL: host];
}

- (NSURL *)host
{
	return [_request URL];
}

#pragma mark -

- (void)setUserAgent: (NSString *)agent
{
	if ([self userAgent] == nil)
	{
		[_request addValue: agent forHTTPHeaderField: @"User-Agent"];
	}
	else
	{
		[_request setValue: agent forHTTPHeaderField: @"User-Agent"];
	}
}

- (NSString *)userAgent
{
	return [_request valueForHTTPHeaderField: @"User-Agent"];
}

#pragma mark -

- (void)setMethod: (NSString *)method withObject: (id)object
{
	[_encoder setMethod: method withObjects: [NSArray arrayWithObject: object]];
}

- (void)setMethod: (NSString *)method withObjects: (NSArray *)objects
{
	[_encoder setMethod: method withObjects: objects];
}

#pragma mark -

- (NSString *)method
{
	return [_encoder method];
}

- (NSArray *)objects
{
	return [_encoder objects];
}

#pragma mark -

- (NSString *)source
{
	return [_encoder source];
}

#pragma mark -

- (NSURLRequest *)request
{
	NSData *request = [[_encoder encode] dataUsingEncoding: NSUTF8StringEncoding];
	NSNumber *length = [NSNumber numberWithInt: [request length]];
	
	if (request == nil)
	{
		return nil;
	}
	
	[_request setHTTPMethod: @"POST"];
	
	if ([_request valueForHTTPHeaderField: @"Content-Length"] == nil)
	{
		[_request addValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
	}
	else
	{
		[_request setValue: @"text/xml" forHTTPHeaderField: @"Content-Type"];
	}
	
	if ([_request valueForHTTPHeaderField: @"Content-Length"] == nil)
	{
		[_request addValue: [length stringValue] forHTTPHeaderField: @"Content-Length"];
	}
	else
	{
		[_request setValue: [length stringValue] forHTTPHeaderField: @"Content-Length"];
	}
	
	[_request setHTTPBody: request];
	
	return (NSURLRequest *)_request;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"\nhost: %@\nuser-agent: %@\nmethod: %@\nobjects:%@\nsource:%@", 
			self.host, self.userAgent, self.method, self.objects, self.source];
}

#pragma mark -

- (void)dealloc
{
	[_request release];
	[_encoder release];
	
	[super dealloc];
}

@end