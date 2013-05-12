//
//  WPWalkthroughGrayOverlayView.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPWalkthroughGrayOverlayViewOverlayMode) {
    WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss,
    WPWalkthroughGrayOverlayViewOverlayModeDoubleTapToDismiss,
    WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode,
};

typedef NS_ENUM(NSUInteger, WPWalkthroughGrayOverlayViewIcon) {
    WPWalkthroughGrayOverlayViewWarningIcon,
    WPWalkthroughGrayOverlayViewBlueCheckmarkIcon,
};

@interface WPWalkthroughGrayOverlayView : UIView

@property (nonatomic, assign) WPWalkthroughGrayOverlayViewOverlayMode overlayMode;

@property (nonatomic, assign) WPWalkthroughGrayOverlayViewIcon icon;
@property (nonatomic, strong) NSString *overlayTitle;
@property (nonatomic, strong) NSString *overlayDescription;
@property (nonatomic, strong) NSString *footerDescription;
@property (nonatomic, strong) NSString *button1Text;
@property (nonatomic, strong) NSString *button2Text;
@property (nonatomic, assign) BOOL hideBackgroundView;

@property (nonatomic, copy) void (^singleTapCompletionBlock)(WPWalkthroughGrayOverlayView *);
@property (nonatomic, copy) void (^doubleTapCompletionBlock)(WPWalkthroughGrayOverlayView *);
@property (nonatomic, copy) void (^button1CompletionBlock)(WPWalkthroughGrayOverlayView *);
@property (nonatomic, copy) void (^button2CompletionBlock)(WPWalkthroughGrayOverlayView *);

- (void)dismiss;

@end
