/*
 *  PasscodeButtonStyleProvider.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "PasscodeButtonStyleProvider.h"

@implementation PasscodeButtonStyle

@end

@interface PasscodeButtonStyleProvider ()

@property (strong, nonatomic) NSMutableDictionary *buttonStyles;

@end


@implementation PasscodeButtonStyleProvider

- (id)init {
    self = [super init];
     if(self)
     {
         _buttonStyles = [NSMutableDictionary new];
         
         _defaultButtonStyle = [[PasscodeButtonStyle alloc]init];
         _defaultButtonStyle.titleColor = [UIColor blackColor];
         _defaultButtonStyle.lineColor = [UIColor blackColor];
         _defaultButtonStyle.fillColor = [UIColor clearColor];
         _defaultButtonStyle.selectedFillColor = [UIColor blackColor];
         _defaultButtonStyle.selectedLineColor = [UIColor whiteColor];
         _defaultButtonStyle.selectedTitleColor = [UIColor whiteColor];
         
     }
     return self;
}

- (void)addStyle:(PasscodeButtonStyle *)passcodeStyle forButton:(PasscodeButtonType)buttonType {
    [self.buttonStyles setObject:passcodeStyle forKey:[NSNumber numberWithInt:buttonType]];
}

- (PasscodeButtonStyle *)styleForButtonType:(PasscodeButtonType)buttonType {
    if([self.buttonStyles objectForKey:@(buttonType)] != nil){
        return [self.buttonStyles objectForKey:@(buttonType)];
    }else{
        return self.defaultButtonStyle;
        
    }
}

- (BOOL)customStyleExistsForButtonType:(PasscodeButtonType)buttonType {
   return self.buttonStyles[@(buttonType)] != nil;
}

@end
