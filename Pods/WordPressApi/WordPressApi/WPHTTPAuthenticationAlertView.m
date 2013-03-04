//
//  WPHTTPAuthenticationAlertView.m
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPHTTPAuthenticationAlertView.h"

@implementation WPHTTPAuthenticationAlertView {
    NSURLAuthenticationChallenge *_challenge;
    UITextField *usernameField, *passwordField;
}


- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    self = [super initWithTitle:nil
                        message:nil
                       delegate:self
              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label.")
              otherButtonTitles:nil];

    if (self) {
        _challenge = challenge;

        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            self.alertViewStyle = UIAlertViewStyleDefault;
            self.title = NSLocalizedString(@"Certificate error", @"Popup title for wrong SSL certificate.");
            self.message = [NSString stringWithFormat:NSLocalizedString(@"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.\n\nWould you like to trust the certificate anyway?", @""), challenge.protectionSpace.host];
            [self addButtonWithTitle:NSLocalizedString(@"Trust", @"Connect when the SSL certificate is invalid")];
        } else {
            self.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            self.title = NSLocalizedString(@"Authentication required", @"Popup title to ask for user credentials.");
            self.message = NSLocalizedString(@"Please enter your credentials", @"Popup message to ask for user credentials (fields shown below).");
            [self addButtonWithTitle:NSLocalizedString(@"Log In", @"Log In button label.")];
        }
    }
    return self;
}


-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    if (buttonIndex == 1) {
        NSURLCredential *credential;
        if ([_challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            credential = [NSURLCredential credentialForTrust:_challenge.protectionSpace.serverTrust];
        } else {
            NSString *username, *password;
            if ([self respondsToSelector:@selector(setAlertViewStyle:)]) {
                username = [[self textFieldAtIndex:0] text];
                password = [[self textFieldAtIndex:1] text];
            } else {
                username = usernameField.text;
                password = passwordField.text;
            }
            credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
        }

        [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:[_challenge protectionSpace]];
        [[_challenge sender] useCredential:credential forAuthenticationChallenge:_challenge];
    } else {
        [[_challenge sender] cancelAuthenticationChallenge:_challenge];
    }
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end
