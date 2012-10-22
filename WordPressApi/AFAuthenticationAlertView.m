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
    UITextField *usernameField, *passwordField;
}


- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    self = [super initWithTitle:NSLocalizedString(@"Authentication required", @"Popup title to ask for user credentials.")
                message:NSLocalizedString(@"Please enter your credentials", @"Popup message to ask for user credentials (fields shown below).")
               delegate:self
      cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label.")
      otherButtonTitles:NSLocalizedString(@"Log In", @"Log In button label."), nil];
    if (self) {
        _challenge = challenge;
        
        self.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    }
    return self;
}


-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    if (buttonIndex == 1) {
        NSString *username, *password;
        if ([self respondsToSelector:@selector(setAlertViewStyle:)]) {
            username = [[self textFieldAtIndex:0] text];
            password = [[self textFieldAtIndex:1] text];
        } else {
            username = usernameField.text;
            password = passwordField.text;
        }
        
        NSURLCredential *credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
        [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:[_challenge protectionSpace]];
        [[_challenge sender] useCredential:credential forAuthenticationChallenge:_challenge];
    } else {
        [[_challenge sender] cancelAuthenticationChallenge:_challenge];
    }
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end
