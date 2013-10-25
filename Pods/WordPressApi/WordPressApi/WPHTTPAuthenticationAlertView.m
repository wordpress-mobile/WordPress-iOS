//
//  WPHTTPAuthenticationAlertView.m
//  WordPress
//
//  Created by Jorge Bernal on 3/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPHTTPAuthenticationAlertView.h"

@implementation WPHTTPAuthenticationAlertView {
    UIAlertView *_alertView;
    NSURLAuthenticationChallenge *_challenge;
    UITextField *usernameField, *passwordField;
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    self = [super init];
    
    if (self) {
        _alertView = [[UIAlertView alloc] initWithTitle:nil
                                                message:nil
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label.")
                                      otherButtonTitles:nil];
        _challenge = challenge;
        
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            _alertView.alertViewStyle = UIAlertViewStyleDefault;
            _alertView.title = NSLocalizedString(@"Certificate error", @"Popup title for wrong SSL certificate.");
            _alertView.message = [NSString stringWithFormat:NSLocalizedString(@"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.\n\nWould you like to trust the certificate anyway?", @""), challenge.protectionSpace.host];
            [_alertView addButtonWithTitle:NSLocalizedString(@"Trust", @"Connect when the SSL certificate is invalid")];
        } else {
            _alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            _alertView.title = NSLocalizedString(@"Authentication required", @"Popup title to ask for user credentials.");
            _alertView.message = NSLocalizedString(@"Please enter your credentials", @"Popup message to ask for user credentials (fields shown below).");
            [_alertView addButtonWithTitle:NSLocalizedString(@"Log In", @"Log In button label.")];
        }
    }
    
    return self;
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSURLCredential *credential;
        if ([_challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            credential = [NSURLCredential credentialForTrust:_challenge.protectionSpace.serverTrust];
        } else {
            NSString *username, *password;
            if ([self respondsToSelector:@selector(setAlertViewStyle:)]) {
                username = [[alertView textFieldAtIndex:0] text];
                password = [[alertView textFieldAtIndex:1] text];
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
}

- (void)show
{
    [_alertView show];
}

@end
