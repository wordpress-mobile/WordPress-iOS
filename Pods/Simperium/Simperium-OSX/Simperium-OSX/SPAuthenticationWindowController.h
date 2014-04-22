//
//  SPAuthenticationWindowController.h
//  Simperium
//
//  Created by Michael Johnston on 7/20/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SPAuthenticator;
@class SPAuthenticationTextField;
@class SPAuthenticationValidator;

@interface SPAuthenticationWindowController : NSWindowController<NSTextFieldDelegate> {
    NSImageView *logoImageView;
    NSButton *cancelButton;
    SPAuthenticationTextField *usernameField;
    SPAuthenticationTextField *passwordField;
    SPAuthenticationTextField *confirmField;
    NSTextField *changeToSignInField;
    NSTextField *changeToSignUpField;
    NSTextField *errorField;
    NSButton *signInButton;
    NSButton *signUpButton;
    NSButton *changeToSignInButton;
    NSButton *changeToSignUpButton;
    NSProgressIndicator *signInProgress;
    NSProgressIndicator *signUpProgress;
    BOOL optional;
    CGFloat rowSize;
}

@property (nonatomic, retain) SPAuthenticator *authenticator;
@property (nonatomic, retain) SPAuthenticationValidator *validator;
@property (nonatomic, assign) BOOL optional;
@property (nonatomic, assign) BOOL signingIn;

- (IBAction) signUpAction:(id)sender;
- (IBAction) signInAction:(id)sender;

@end
