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

#define WPKT_HEIGHT_IPHONE_PORTRAIT 42.0f
#define WPKT_HEIGHT_IPHONE_LANDSCAPE 37.0f
#define WPKT_HEIGHT_IPAD_PORTRAIT 72.0f
#define WPKT_HEIGHT_IPAD_LANDSCAPE 72.0f

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
