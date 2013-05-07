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

@class WPWalkthroughGrayOverlayView;
typedef void(^WPWalkthroughGrayOverlayViewCompletionBlock)(WPWalkthroughGrayOverlayView*);

@interface WPWalkthroughGrayOverlayView : UIView

@property (nonatomic, assign) WPWalkthroughGrayOverlayViewOverlayMode overlayMode;

@property (nonatomic, assign) WPWalkthroughGrayOverlayViewIcon icon;
@property (nonatomic, strong) NSString *overlayTitle;
@property (nonatomic, strong) NSString *overlayDescription;
@property (nonatomic, strong) NSString *footerDescription;
@property (nonatomic, strong) NSString *button1Text;
@property (nonatomic, strong) NSString *button2Text;
@property (nonatomic, assign) BOOL hideBackgroundView;

@property (nonatomic, copy) WPWalkthroughGrayOverlayViewCompletionBlock singleTapCompletionBlock;
@property (nonatomic, copy) WPWalkthroughGrayOverlayViewCompletionBlock doubleTapCompletionBlock;
@property (nonatomic, copy) WPWalkthroughGrayOverlayViewCompletionBlock button1CompletionBlock;
@property (nonatomic, copy) WPWalkthroughGrayOverlayViewCompletionBlock button2CompletionBlock;

- (void)dismiss;

@end
