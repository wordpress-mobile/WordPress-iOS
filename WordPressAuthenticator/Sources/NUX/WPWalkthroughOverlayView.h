#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPWalkthroughOverlayViewOverlayMode) {
    WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss,
    WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode,
    WPWalkthroughGrayOverlayViewOverlayModePrimaryButton
};

typedef NS_ENUM(NSUInteger, WPWalkthroughOverlayViewIcon) {
    WPWalkthroughGrayOverlayViewWarningIcon,
    WPWalkthroughGrayOverlayViewBlueCheckmarkIcon,
};

@interface WPWalkthroughOverlayView : UIView

@property (nonatomic, assign) WPWalkthroughOverlayViewOverlayMode overlayMode;
@property (nonatomic, assign) WPWalkthroughOverlayViewIcon icon;
@property (nonatomic, strong) NSString *overlayTitle;
@property (nonatomic, strong) NSString *overlayDescription;
@property (nonatomic, strong) NSString *footerDescription;
@property (nonatomic, strong) NSString *secondaryButtonText;
@property (nonatomic, strong) NSString *primaryButtonText;
@property (nonatomic, assign) BOOL hideBackgroundView;

@property (nonatomic, copy) void (^dismissCompletionBlock)(WPWalkthroughOverlayView *);
@property (nonatomic, copy) void (^secondaryButtonCompletionBlock)(WPWalkthroughOverlayView *);
@property (nonatomic, copy) void (^primaryButtonCompletionBlock)(WPWalkthroughOverlayView *);

- (void)dismiss;

@end
