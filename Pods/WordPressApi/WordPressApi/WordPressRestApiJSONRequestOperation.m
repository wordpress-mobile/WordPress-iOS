//
//  WordPressRestApiJSONRequestOperation.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import "WordPressRestApiJSONRequestOperation.h"
#import "WordPressRestApi.h"

#import "WPHTTPAuthenticationAlertView.h"

@implementation WordPressRestApiJSONRequestOperation

+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {
    NSURL *testURL = [NSURL URLWithString:WordPressRestApiEndpointURL];
    if ([urlRequest.URL.host isEqualToString:testURL.host] && [urlRequest.URL.path rangeOfString:testURL.path].location == 0)
        return YES;

    return NO;
}

- (NSError *)error {
    if (self.response.statusCode >= 400) {
        NSString *errorMessage = [self.responseObject objectForKey:@"message"];
        NSUInteger errorCode = WordPressRestApiErrorJSON;
        if ([self.responseObject objectForKey:@"error"] && errorMessage) {
            NSString *error = [self.responseObject objectForKey:@"error"];
            if ([error isEqualToString:@"invalid_token"]) {
                errorCode = WordPressRestApiErrorInvalidToken;
            } else if ([error isEqualToString:@"authorization_required"]) {
                errorCode = WordPressRestApiErrorAuthorizationRequired;
            }
            return [NSError errorWithDomain:WordPressRestApiErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage, WordPressRestApiErrorCodeKey: error}];
        }
    }
    return [super error];
}

// AFMIG: added
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return ![protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		// Handle invalid certificates
		SecTrustResultType result;
		OSStatus certificateStatus = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
		if (certificateStatus == 0 && result == kSecTrustResultRecoverableTrustFailure) {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				WPHTTPAuthenticationAlertView *alert = [[WPHTTPAuthenticationAlertView alloc] initWithChallenge:challenge];
				[alert show];
			});
		} else {
			[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
		}
	} else {
		NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[challenge protectionSpace]];
		
		if ([challenge previousFailureCount] == 0 && credential) {
			[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				WPHTTPAuthenticationAlertView *alert = [[WPHTTPAuthenticationAlertView alloc] initWithChallenge:challenge];
				[alert show];
			});
		}
	}
}

@end