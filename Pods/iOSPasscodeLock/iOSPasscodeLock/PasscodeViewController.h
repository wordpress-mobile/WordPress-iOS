/*
 *  MainViewController.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

#ifndef IS_IPAD
#define IS_IPAD   ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#endif


@protocol PasscodeViewControllerDelegate <NSObject>

@optional

-(void)didSetupPasscode;
-(void)passcodeSetupCancelled;
-(void)didVerifyPasscode;
-(void)passcodeVerificationFailed;

@end

typedef enum PasscodeType : NSUInteger {
    PasscodeTypeVerify,
    PasscodeTypeVerifyForSettingChange,
    PasscodeTypeSetup,
    PasscodeTypeChangePasscode
} PasscodeType;

@interface PasscodeViewController : UIViewController

@property (nonatomic, unsafe_unretained) id <PasscodeViewControllerDelegate> delegate;

- (id)initWithPasscodeType:(PasscodeType)type withDelegate:(id<PasscodeViewControllerDelegate>)delegate;

@end
