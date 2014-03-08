/*
 *  PasscodeManager.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "PasscodeViewController.h" 
#import "PasscodeButtonStyleProvider.h"

@interface PasscodeManager : NSObject <PasscodeViewControllerDelegate> 

+ (PasscodeManager *)sharedManager;

- (void) activatePasscodeProtection;
- (void) setupNewPasscodeWithCompletion:(void (^)(BOOL success)) completion;
- (void) changePasscodeWithCompletion:(void (^)(BOOL success)) completion;
- (void) disablePasscodeProtectionWithCompletion:(void (^) (BOOL success)) completion;
- (void) setPasscodeInactivityDurationInMinutes:(NSNumber *) minutes;
- (void) didSetupPasscode;
- (void) setPasscode:(NSString *)passcode;
- (void) togglePasscodeProtection:(BOOL)isOn;
- (BOOL) isPasscodeProtectionOn;
- (BOOL) isPasscodeCorrect:(NSString *)passcode;
- (BOOL) shouldLock;
- (NSNumber *) getPasscodeInactivityDurationInMinutes;

@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIImage *backgroundImage;
@property (strong, nonatomic) UIImage *logo;
@property (strong, nonatomic) UIImage *appLockedCoverScreenBackgroundImage;
@property (strong, nonatomic) UIColor *instructionsLabelColor;
@property (strong, nonatomic) UIColor *cancelOrDeleteButtonColor;
@property (strong, nonatomic) UIColor *passcodeViewLineColor;
@property (strong, nonatomic) UIColor *passcodeViewFillColor;
@property (strong, nonatomic) UIColor *errorLabelColor;
@property (strong, nonatomic) UIColor *errorLabelBackgroundColor;
@property (strong, nonatomic) UIColor *appLockedCoverScreenBackgroundColor;
@property (strong, nonatomic) UIFont *errorLabelFont;
@property (strong, nonatomic) UIFont *instructionsLabelFont;
@property (strong, nonatomic) UIFont *cancelOrDeleteButtonFont;
@property (strong, nonatomic) PasscodeButtonStyleProvider *buttonStyleProvider;
@property (assign) BOOL shouldUseAppLockedCoverScreen; 

@end
