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

- (void)dealloc {
    [_challenge release];
    [usernameField release];
    [passwordField release];

    [super dealloc];
}

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    self = [super init];
    if (self) {
        _challenge = [challenge retain];
    }
    
    [self initWithTitle:NSLocalizedString(@"Authentication required", @"")
                                                    message:NSLocalizedString(@"Please enter your credentials", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                          otherButtonTitles:NSLocalizedString(@"Login", @""), nil];
    
    // FIXME: what about iOS 4?
    if ([self respondsToSelector:@selector(setAlertViewStyle:)]) {
        self.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    } else {
        if (DeviceIsPad()) {
            self.message = [self.message stringByAppendingString:@"\n\n\n\n"];
        } else {
            self.message = [self.message stringByAppendingString:@"\n\n\n"];
        }
        usernameField = [[UITextField alloc] initWithFrame:CGRectMake(12.0f, 48.0f, 260.0f, 29.0f)];
        usernameField.placeholder = NSLocalizedString(@"Username", @"");
        usernameField.backgroundColor = [UIColor whiteColor];
        usernameField.textColor = [UIColor blackColor];
        usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        usernameField.keyboardType = UIKeyboardTypeDefault;
        usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
        usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self addSubview:usernameField];
        
        passwordField = [[UITextField alloc]  initWithFrame:CGRectMake(12.0, 82.0, 260.0, 29.0)]; 
        passwordField.placeholder = NSLocalizedString(@"Password", @"");
        passwordField.secureTextEntry = YES;
        passwordField.backgroundColor = [UIColor whiteColor];
        passwordField.textColor = [UIColor blackColor];
        passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        passwordField.keyboardType = UIKeyboardTypeDefault;
        passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
        [self addSubview:passwordField];
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
