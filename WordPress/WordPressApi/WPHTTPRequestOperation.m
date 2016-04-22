#import "WPHTTPRequestOperation.h"

#import <AFNetworking/AFNetworking.h>
#import "WPHTTPAuthenticationAlertController.h"

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
                [WPHTTPAuthenticationAlertController presentWithChallenge:challenge];
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
                [WPHTTPAuthenticationAlertController presentWithChallenge:challenge];
			});
		}
	}
}

@end
