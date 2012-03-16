//
//  AFAuthenticationAlertView.m
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "AFAuthenticationAlertView.h"

@implementation AFAuthenticationAlertView {
    AFHTTPRequestOperation *_operation;
    NSOperationQueue *_queue;
    NSURLProtectionSpace *_protectionSpace;
}

- (void)dealloc {
    [_operation release];
    [_queue release];
    [_protectionSpace release];

    [super dealloc];
}

- (id)initWithProtectionSpace:(NSURLProtectionSpace *)protectionSpace operation:(AFHTTPRequestOperation *)operation andQueue:(NSOperationQueue *)queue {
    self = [super init];
    if (self) {
        _operation = [operation retain];
        _queue = [queue retain];
        _protectionSpace = [protectionSpace retain];
    }
    return self;
}

- (void)show {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Authentication required", @"")
                                                    message:NSLocalizedString(@"Please enter your credentials", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                          otherButtonTitles:NSLocalizedString(@"Login", @""), nil];
    // FIXME: what about iOS 4?
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alert.delegate = self;
    [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *username = [[alertView textFieldAtIndex:0] text];
        NSString *password = [[alertView textFieldAtIndex:1] text];
        
        NSURLCredential *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
        [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:_protectionSpace];

        [_queue addOperation:_operation];
    }
}

@end
