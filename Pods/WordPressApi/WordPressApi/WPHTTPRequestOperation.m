//
//  WPHTTPRequestOperation.m
//  WordPressApiExample
//
//  Created by Diego E. Rey Mendez on 5/13/14.
//  Copyright (c) 2014 Automattic. All rights reserved.
//

#import "WPHTTPRequestOperation.h"

#import <AFNetworking/AFNetworking.h>
#import "WPHTTPAuthenticationAlertView.h"

@implementation WPHTTPRequestOperation

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
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
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
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
