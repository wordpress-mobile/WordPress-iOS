/*
 *  PasscodeButtonStyleProvider.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@interface PasscodeStyle : NSObject

@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *titleColor;
@property (strong, nonatomic) UIColor *fillColor;
@property (strong, nonatomic) UIColor *selectedLineColor;
@property (strong, nonatomic) UIColor *selectedTitleColor;
@property (strong, nonatomic) UIColor *selectedFillColor;
@property (strong, nonatomic) UIFont *titleFont;

@end

@interface PasscodeButtonStyleProvider : NSObject

typedef enum PasscodeButton : NSUInteger {
    PasscodeButtonZero,
    PasscodeButtonOne,
    PasscodeButtonTwo,
    PasscodeButtonThree,
    PasscodeButtonFour,
    PasscodeButtonFive,
    PasscodeButtonSix,
    PasscodeButtonSeven,
    PasscodeButtonEight,
    PasscodeButtonNine,
    PasscodeButtonAll
} PasscodeButton;

- (void) addStyleForButton:(PasscodeButton)button stye:(PasscodeStyle *)passcodeStyle;
- (PasscodeStyle *) styleForButton:(PasscodeButton)button;
- (BOOL) styleExistsForButton:(PasscodeButton)button; 
@end


