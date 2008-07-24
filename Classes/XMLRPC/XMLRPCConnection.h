//
//  Cocoa XML-RPC Client Framework
//  XMLRPCConnection.h
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
 
#import <Foundation/Foundation.h>

@class XMLRPCRequest, XMLRPCResponse;

/* XML-RPC Connecion Notifications */
extern NSString *XMLRPCRequestFailedNotification;
extern NSString *XMLRPCSentRequestNotification;
extern NSString *XMLRPCReceivedResponseNotification;

@interface XMLRPCConnection : NSObject {
	NSURLConnection *_connection;
	NSString *_method;
	NSMutableData *_data;
	id _delegate;
}

- (id)initWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id)delegate;

#pragma mark -

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest: (XMLRPCRequest *)request;

#pragma mark -

- (void)cancel;

@end

#pragma mark -

@interface NSObject (XMLRPCConnectionDelegate)

- (void)connection: (XMLRPCConnection *)connection didReceiveResponse: (XMLRPCResponse *)response
	forMethod: (NSString *)method;

- (void)connection: (XMLRPCConnection *)connection didFailWithError: (NSError *)error
	forMethod: (NSString *)method;

@end