//
//  SPAuthenticationWindowController.m
//  Simperium
//
//  Created by Michael Johnston on 8/14/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationWindowController.h"
#import "Simperium.h"
#import "NSString+Simperium.h"
#import <QuartzCore/CoreAnimation.h>
#import "SPAuthenticator.h"
#import "SPAuthenticationWindow.h"
#import "SPAuthenticationView.h"
#import "SPAuthenticationTextField.h"
#import "SPAuthenticationButton.h"
#import "SPAuthenticationConfiguration.h"
#import "SPAuthenticationValidator.h"

static NSUInteger windowWidth = 380;
static NSUInteger windowHeight = 540;

@interface SPAuthenticationWindowController () {
    BOOL earthquaking;
}

@end

@implementation SPAuthenticationWindowController
@synthesize authenticator;
@synthesize validator;
@synthesize optional;

- (id)init {
    rowSize = 50;
    SPAuthenticationWindow *window = [[SPAuthenticationWindow alloc] initWithContentRect:NSMakeRect(0, 0, windowWidth, windowHeight) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    if ((self = [super initWithWindow: window])) {
        self.validator = [[SPAuthenticationValidator alloc] init];
        
        SPAuthenticationView *authView = [[SPAuthenticationView alloc] initWithFrame:window.frame];
        [window.contentView addSubview:authView];
        
        NSUInteger paddingX = 30;
        NSUInteger width = windowWidth - paddingX*2;
        
        int cancelWidth = 60;
        NSString *cancelButtonText = NSLocalizedString(@"Skip", @"Text to display on OSX cancel button");

        cancelButton = [self linkButtonWithText:cancelButtonText frame:NSMakeRect(windowWidth-cancelWidth, windowHeight-5-20, cancelWidth, 20)];
        cancelButton.target = self;
        cancelButton.action = @selector(cancelAction:);
        [authView addSubview:cancelButton];
        
        NSImage *logoImage = [NSImage imageNamed:[[SPAuthenticationConfiguration sharedInstance] logoImageName]];
        CGFloat markerY = windowHeight-45-logoImage.size.height;
        NSRect logoRect = NSMakeRect(windowWidth/2 - logoImage.size.width/2, markerY, logoImage.size.width, logoImage.size.height);
        logoImageView = [[NSImageView alloc] initWithFrame:logoRect];
        logoImageView.image = logoImage;
        [authView addSubview:logoImageView];
        
        errorField = [self tipFieldWithText:@"" frame:NSMakeRect(paddingX, markerY - 30, width, 20)];
        [errorField setTextColor:[NSColor redColor]];
        [authView addSubview:errorField];

        markerY -= 30;
        usernameField = [[SPAuthenticationTextField alloc] initWithFrame:NSMakeRect(paddingX, markerY - rowSize, width, 40) secure:NO];
        
        [usernameField setPlaceholderString:NSLocalizedString(@"Email Address", @"Placeholder text for login field")];
        usernameField.delegate = self;
        [authView addSubview:usernameField];
        
        passwordField = [[SPAuthenticationTextField alloc] initWithFrame:NSMakeRect(paddingX, markerY - rowSize*2, width, 40) secure:YES];
        [passwordField setPlaceholderString:NSLocalizedString(@"Password", @"Placeholder text for password field")];
        
        passwordField.delegate = self;
        [authView addSubview:passwordField];

        confirmField = [[SPAuthenticationTextField alloc] initWithFrame:NSMakeRect(paddingX, markerY - rowSize*3, width, 40) secure:YES];
        [confirmField setPlaceholderString:NSLocalizedString(@"Confirm Password", @"Placeholder text for confirmation field")];
        confirmField.delegate = self;
        [authView addSubview:confirmField];
                
        markerY -= 30;
        signInButton = [[SPAuthenticationButton alloc] initWithFrame:NSMakeRect(paddingX, markerY - rowSize*3, width, 40)];
        signInButton.title = NSLocalizedString(@"Sign In", @"Title of button for signing in");
        signInButton.target = self;
        signInButton.action = @selector(signInAction:);
        [authView addSubview:signInButton];

        int progressSize = 20;
        signInProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(signInButton.frame.size.width - progressSize - paddingX, (signInButton.frame.size.height - progressSize) / 2, progressSize, progressSize)];
        [signInProgress setStyle:NSProgressIndicatorSpinningStyle];
        [signInProgress setDisplayedWhenStopped:NO];
        [signInButton addSubview:signInProgress];

        
        signUpButton = [[SPAuthenticationButton alloc] initWithFrame:NSMakeRect(paddingX, markerY - rowSize*4, width, 40)];
        signUpButton.title = NSLocalizedString(@"Sign Up", @"Title of button for signing up");
        signUpButton.target = self;
        signUpButton.action = @selector(signUpAction:);
        [authView addSubview:signUpButton];
        
        signUpProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(signUpProgress.frame.size.width - progressSize - paddingX, (signUpProgress.frame.size.height - progressSize) / 2, progressSize, progressSize)];
        [signUpProgress setStyle:NSProgressIndicatorSpinningStyle];
        [signUpProgress setDisplayedWhenStopped:NO];
        [signUpButton addSubview:signUpProgress];

        
        NSString *signUpTip = NSLocalizedString(@"Need an account?", @"Link to create an account");
        changeToSignUpField = [self tipFieldWithText:signUpTip frame:NSMakeRect(paddingX, markerY - rowSize*3 - 35, width, 20)];
        [authView addSubview:changeToSignUpField];

        NSString *signInTip = NSLocalizedString(@"Already have an account?", @"Link to sign in to an account");
        changeToSignInField = [self tipFieldWithText:signInTip frame:NSMakeRect(paddingX, markerY - rowSize*4 - 35, width, 20)];
        [authView addSubview:changeToSignInField];
        
        changeToSignUpButton = [self toggleButtonWithText:signUpButton.title frame:NSMakeRect(paddingX, changeToSignUpField.frame.origin.y - changeToSignUpField.frame.size.height - 2, width, 30)];
        [authView addSubview:changeToSignUpButton];
        
        changeToSignInButton = [self toggleButtonWithText:signInButton.title frame:NSMakeRect(paddingX, changeToSignInField.frame.origin.y - changeToSignInField.frame.size.height - 2, width, 30)];
        [authView addSubview:changeToSignInButton];
        
        // Enter sign up mode
        [self toggleAuthenticationMode:signUpButton];        
    }
    
    return self;
}

- (void)setOptional:(BOOL)on {
    optional = on;
    [cancelButton setHidden:!optional];
}

- (BOOL)optional {
    return optional;
}

- (NSTextField *)tipFieldWithText:(NSString *)text frame:(CGRect)frame {
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    NSFont *font = [NSFont fontWithName:[SPAuthenticationConfiguration sharedInstance].mediumFontName size:13];
    [field setStringValue:[text uppercaseString]];
    [field setEditable:NO];
    [field setSelectable:NO];
    [field setBordered:NO];
    [field setDrawsBackground:NO];
    [field setAlignment:NSCenterTextAlignment];
    [field setFont:font];
    [field setTextColor:[NSColor colorWithCalibratedWhite:153.f/255.f alpha:1.0]];
    
    return field;
}

- (NSButton *)linkButtonWithText:(NSString *)text frame:(CGRect)frame {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    [button setBordered:NO];
    [button setButtonType:NSMomentaryChangeButton];
    button.target = self;
    button.action = @selector(toggleAuthenticationMode:);
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    NSColor *linkColor = [SPAuthenticationConfiguration sharedInstance].controlColor;
    
    NSFont *font = [NSFont fontWithName:[SPAuthenticationConfiguration sharedInstance].mediumFontName size:13];
    NSDictionary *attributes = @{NSFontAttributeName : font,
                                 NSForegroundColorAttributeName : linkColor,
                                 NSParagraphStyleAttributeName : style};
    [button setAttributedTitle: [[NSAttributedString alloc] initWithString:[text uppercaseString] attributes:attributes]];
    
    return button;
}

- (NSButton *)toggleButtonWithText:(NSString *)text frame:(CGRect)frame {
    NSButton *button = [self linkButtonWithText:text frame:frame];
    button.target = self;
    button.action = @selector(toggleAuthenticationMode:);

    return button;
}


- (IBAction)toggleAuthenticationMode:(id)sender {
	self.signingIn = (sender == changeToSignInButton);
}

- (void)setSigningIn:(BOOL)signingIn {
    _signingIn = signingIn;
	[self refreshFields];
}

- (void)refreshFields {
    [signInButton setHidden:!_signingIn];
    [signInButton setEnabled:_signingIn];
    [signUpButton setHidden:_signingIn];
    [signUpButton setEnabled:!_signingIn];
    [changeToSignInButton setHidden:_signingIn];
    [changeToSignInButton setEnabled:!_signingIn];
    [changeToSignUpButton setHidden:!_signingIn];
    [changeToSignUpButton setEnabled:_signingIn];
    [changeToSignInField setHidden:_signingIn];
    [changeToSignUpField setHidden:!_signingIn];
    [confirmField setHidden:_signingIn];
    
    [self.window.contentView setNeedsDisplay:YES];
    [self clearAuthenticationError];
}


#pragma mark Actions

- (IBAction)signInAction:(id)sender {
    if (![self validateSignIn]) {
        return;
    }
    
    signInButton.title = NSLocalizedString(@"Signing In...", @"Displayed temporarily while signing in");
    [signInProgress startAnimation:self];
    [signInButton setEnabled:NO];
    [changeToSignUpButton setEnabled:NO];
    [usernameField setEnabled:NO];
    [passwordField setEnabled:NO];
    [self.authenticator authenticateWithUsername:[usernameField stringValue] password:[passwordField stringValue]
                                       success:^{
                                       }
                                       failure:^(int responseCode, NSString *responseString) {
                                           NSLog(@"Error signing in (%d): %@", responseCode, responseString);
                                           [self showAuthenticationErrorForCode:responseCode];
                                           [signInProgress stopAnimation:self];
                                           signInButton.title = NSLocalizedString(@"Sign In", @"Title of button for signing in");
                                           [signInButton setEnabled:YES];
                                           [changeToSignUpButton setEnabled:YES];
                                           [usernameField setEnabled:YES];
                                           [passwordField setEnabled:YES];
                                       }
     ];
}

- (IBAction)signUpAction:(id)sender {
    if (![self validateSignUp]) {
        return;
    }
    
    signUpButton.title = NSLocalizedString(@"Signing Up...", @"Displayed temoprarily while signing up");
    [signUpProgress startAnimation:self];
    [signUpButton setEnabled:NO];
    [changeToSignInButton setEnabled:NO];
    [usernameField setEnabled:NO];
    [passwordField setEnabled:NO];
    [confirmField setEnabled:NO];

    [self.authenticator createWithUsername:[usernameField stringValue] password:[passwordField stringValue]
                                 success:^{
                                     //[self close];
                                 }
                                 failure:^(int responseCode, NSString *responseString) {
                                     NSLog(@"Error signing up (%d): %@", responseCode, responseString);
                                     [self showAuthenticationErrorForCode:responseCode];
                                     signUpButton.title = NSLocalizedString(@"Sign Up", @"Title of button for signing up");
                                     [signUpProgress stopAnimation:self];
                                     [signUpButton setEnabled:YES];
                                     [changeToSignInButton setEnabled:YES];
                                     [usernameField setEnabled:YES];
                                     [passwordField setEnabled:YES];
                                     [confirmField setEnabled:YES];
                                 }];
}

- (IBAction)cancelAction:(id)sender {
    [authenticator cancel];
}


# pragma mark Validation and Error Handling

- (BOOL)validateUsername {
    if (![self.validator validateUsername:usernameField.stringValue]) {
        [self earthquake:usernameField];
        [self showAuthenticationError:NSLocalizedString(@"Not a valid email address", @"Error when you enter a bad email address")];
        
        return NO;
    }

    return YES;
}

- (BOOL)validatePasswordSecurity {
    if (![self.validator validatePasswordSecurity:passwordField.stringValue]) {
        [self earthquake:passwordField];
        [self earthquake:confirmField];
        
        NSString *errorStr = NSLocalizedString(@"Password should be at least %ld characters", @"Error when your password isn't long enough");
        NSString *notLongEnough = [NSString stringWithFormat:errorStr, (long)self.validator.minimumPasswordLength];
        [self showAuthenticationError:notLongEnough];
        
        return NO;
    }
    
    return YES;
}

- (BOOL)validatePasswordsMatch{
    if (![passwordField.stringValue isEqualToString:confirmField.stringValue]) {
        [self earthquake:passwordField];
        [self earthquake:confirmField];

        return NO;
    }
    
    return YES;
}

- (BOOL)validateConnection {
    if (!authenticator.connected) {
        [self showAuthenticationError:NSLocalizedString(@"You're not connected to the internet", @"Error when you're not connected")];
        return NO;
    }
    
    return YES;
}

- (BOOL)validateSignIn {
    [self clearAuthenticationError];
    return [self validateConnection] &&
           [self validateUsername] &&
           [self validatePasswordSecurity];
}

- (BOOL)validateSignUp {
    [self clearAuthenticationError];
    return [self validateConnection] &&
           [self validateUsername] &&
           [self validatePasswordsMatch] &&
           [self validatePasswordSecurity];
}

- (void)earthquake:(NSView *)view {
    // Quick and dirty way to prevent overlapping animations that can move the view
    if (earthquaking)
        return;
    
    earthquaking = YES;
    CAKeyframeAnimation *shakeAnimation = [self shakeAnimation:view.frame];
    [view setAnimations:@{@"frameOrigin":shakeAnimation}];
	[[view animator] setFrameOrigin:view.frame.origin];
}

- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{
    // From http://www.cimgf.com/2008/02/27/core-animation-tutorial-window-shake-effect/
    int numberOfShakes = 4;
    CGFloat vigourOfShake = 0.02;
    CGFloat durationOfShake = 0.5;
    
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
	
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
	int index;
	for (index = 0; index < numberOfShakes; ++index)
	{
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
		CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
	}
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    shakeAnimation.delegate = self;
    
    return shakeAnimation;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    earthquaking = NO;
}

- (void)showAuthenticationError:(NSString *)errorMessage {
    [errorField setStringValue:errorMessage];
}

- (void)showAuthenticationErrorForCode:(NSUInteger)responseCode {
    switch (responseCode) {
        case 409:
            // User already exists
            [self showAuthenticationError:NSLocalizedString(@"That email is already being used", @"Error when address is in use")];
            [self earthquake:usernameField];
            [[self window] makeFirstResponder:usernameField];
            break;
        case 401:
            // Bad email or password
            [self showAuthenticationError:NSLocalizedString(@"Bad email or password", @"Error for bad email or password")];
            break;

        default:
            // General network problem
            [self showAuthenticationError:NSLocalizedString(@"We're having problems. Please try again soon.", @"Generic error")];
            break;
    }
}

- (void)clearAuthenticationError {
    [errorField setStringValue:@""];
}

#pragma mark NSTextView delegates

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector
{
    BOOL retval = NO;
    
    if (commandSelector == @selector(insertNewline:)) {
        if (_signingIn && [control isEqual:passwordField.textField]) {
            [self signInAction:nil];
        } else if (!_signingIn && [control isEqual:confirmField.textField]) {
            [self signUpAction:nil];
        }
    }
    
    return retval;
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    [self.window.contentView setNeedsDisplay:YES];
    return YES;
}

- (void)controlTextDidChange:(NSNotification *)obj {
    // Intercept return and invoke actions
    NSEvent *currentEvent = [NSApp currentEvent];
    if (currentEvent.type == NSKeyDown && [currentEvent.charactersIgnoringModifiers isEqualToString:@"\r"]) {
        if (_signingIn && [[obj object] isEqual:passwordField.textField]) {
            [self signInAction:nil];
        } else if (!_signingIn && [[obj object] isEqual:confirmField.textField]) {
            [self signUpAction:nil];
        }
    }
}


@end
