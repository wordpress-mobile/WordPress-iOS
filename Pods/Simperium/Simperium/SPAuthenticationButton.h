//
//  SPAuthenticationButton.h
//  Simperium
//
//  Created by Tom Witkin on 8/4/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPAuthenticationButton : UIButton {
    UIView *errorView;
    UILabel *errorLabel;
    
    UIColor *backgroundColor;
    UIColor *backgroundHighlightColor;
    
    NSTimer *clearErrorTimer;
}

@property (nonatomic, strong) UIColor *backgroundHighlightColor;
@property (nonatomic, strong) UILabel *detailTitleLabel;

- (void)showErrorMessage:(NSString *)errorMessage;
- (void)clearErrorMessage;

@end
