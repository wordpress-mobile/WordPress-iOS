//
//  NewWPWalkthroughOverlayView.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NewWPWalkthroughOverlayViewOverlayMode) {
    NewWPWalkthroughGrayOverlayViewOverlayModeTapToDismiss,
    NewWPWalkthroughGrayOverlayViewOverlayModeDoubleTapToDismiss,
    NewWPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode,
};

typedef NS_ENUM(NSUInteger, NewWPWalkthroughOverlayViewIcon) {
    NewWPWalkthroughGrayOverlayViewWarningIcon,
    NewWPWalkthroughGrayOverlayViewBlueCheckmarkIcon,
};

@interface NewWPWalkthroughOverlayView : UIView

@property (nonatomic, assign) NewWPWalkthroughOverlayViewOverlayMode overlayMode;
@property (nonatomic, assign) NewWPWalkthroughOverlayViewIcon icon;
@property (nonatomic, strong) NSString *overlayTitle;
@property (nonatomic, strong) NSString *overlayDescription;
@property (nonatomic, strong) NSString *footerDescription;
@property (nonatomic, strong) NSString *leftButtonText;
@property (nonatomic, strong) NSString *rightButtonText;
@property (nonatomic, assign) BOOL hideBackgroundView;

@property (nonatomic, copy) void (^singleTapCompletionBlock)(NewWPWalkthroughOverlayView *);
@property (nonatomic, copy) void (^doubleTapCompletionBlock)(NewWPWalkthroughOverlayView *);
@property (nonatomic, copy) void (^button1CompletionBlock)(NewWPWalkthroughOverlayView *);
@property (nonatomic, copy) void (^button2CompletionBlock)(NewWPWalkthroughOverlayView *);

- (void)dismiss;

@end
