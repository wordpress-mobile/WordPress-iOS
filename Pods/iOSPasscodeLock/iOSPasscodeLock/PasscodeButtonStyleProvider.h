/*
 *  PasscodeButtonStyleProvider.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@interface PasscodeButtonStyle : NSObject

@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *titleColor;
@property (strong, nonatomic) UIColor *fillColor;
@property (strong, nonatomic) UIColor *selectedLineColor;
@property (strong, nonatomic) UIColor *selectedTitleColor;
@property (strong, nonatomic) UIColor *selectedFillColor;
@property (strong, nonatomic) UIFont *titleFont;

@end

typedef enum PasscodeButtonType : NSUInteger {
    PasscodeButtonTypeZero,
    PasscodeButtonTypeOne,
    PasscodeButtonTypeTwo,
    PasscodeButtonTypeThree,
    PasscodeButtonTypeFour,
    PasscodeButtonTypeFive,
    PasscodeButtonTypeSix,
    PasscodeButtonTypeSeven,
    PasscodeButtonTypeEight,
    PasscodeButtonTypeNine,
    PasscodeButtonTypeAll
} PasscodeButtonType;

@interface PasscodeButtonStyleProvider : NSObject

@property (strong, nonatomic) PasscodeButtonStyle *defaultButtonStyle;

- (void)addStyle:(PasscodeButtonStyle *)passcodeStyle forButton:(PasscodeButtonType)buttonType;
- (PasscodeButtonStyle *)styleForButtonType:(PasscodeButtonType)buttonType;
- (BOOL)customStyleExistsForButtonType:(PasscodeButtonType)buttonType;
@end


