//
//  WPKeyboardToolbar.h
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "WPKeyboardToolbarButtonItem.h"

@protocol WPKeyboardToolbarDelegate <NSObject>
- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem;
@end

@interface WPKeyboardToolbar : UIView {
    CAGradientLayer *_gradient;
    UIView *mainView, *extendedView;
    WPKeyboardToolbarButtonItem *boldButton, *italicsButton, *linkButton, *quoteButton, *delButton;
    WPKeyboardToolbarButtonItem *ulButton, *olButton, *liButton, *codeButton, *moreButton;
    WPKeyboardToolbarButtonItem *doneButton, *toggleButton;
}
@property (nonatomic, assign) id<WPKeyboardToolbarDelegate> delegate;

@end
