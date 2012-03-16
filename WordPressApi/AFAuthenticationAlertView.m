//
//  AFAuthenticationAlertView.m
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "AFAuthenticationAlertView.h"

@implementation AFAuthenticationAlertView {
    NSURLAuthenticationChallenge *_challenge;
}

- (void)dealloc {
    [_challenge release];

    [super dealloc];
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    self = [super init];
    if (self) {
        _challenge = [challenge retain];
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
        [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:[_challenge protectionSpace]];
        [[_challenge sender] useCredential:credential forAuthenticationChallenge:_challenge];
    } else {
        [[_challenge sender] continueWithoutCredentialForAuthenticationChallenge:_challenge];
    }
}

@end
