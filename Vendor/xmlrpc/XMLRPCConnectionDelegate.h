#import <Foundation/Foundation.h>

@class XMLRPCConnection, XMLRPCRequest, XMLRPCResponse;

@protocol XMLRPCConnectionDelegate<NSObject>

- (void)request: (XMLRPCRequest *)request didReceiveResponse: (XMLRPCResponse *)response;

- (void)request: (XMLRPCRequest *)request didFailWithError: (NSError *)error;

#pragma mark -

- (BOOL)request: (XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace;

- (void)request: (XMLRPCRequest *)request didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

- (void)request: (XMLRPCRequest *)request didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

@end
