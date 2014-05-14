#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPAlertViewOverlayMode) {
    WPAlertViewOverlayModeTapToDismiss,                 // Not implemented
    WPAlertViewOverlayModeDoubleTapToDismiss,           // Not implemented
    WPAlertViewOverlayModeTwoButtonMode,                // Not implemented
    WPAlertViewOverlayModeOneTextFieldTwoButtonMode,    // Not implemented
    WPAlertViewOverlayModeTwoTextFieldsTwoButtonMode,
    WPAlertViewOverlayModeTwoTextFieldsSideBySideTwoButtonMode
};

@interface WPAlertView : UIView <UITextFieldDelegate>

@property (nonatomic, strong) NSString *overlayTitle;
@property (nonatomic, strong) NSString *overlayDescription;
@property (nonatomic, strong) NSString *footerDescription;
@property (nonatomic, strong) NSString *firstTextFieldPlaceholder;
@property (nonatomic, strong) NSString *firstTextFieldValue;
@property (nonatomic, strong) NSString *firstTextFieldLabelText;
@property (nonatomic, strong) NSString *secondTextFieldPlaceholder;
@property (nonatomic, strong) NSString *secondTextFieldValue;
@property (nonatomic, strong) NSString *secondTextFieldLabelText;
@property (nonatomic, strong) NSString *leftButtonText;
@property (nonatomic, strong) NSString *rightButtonText;
@property (nonatomic, assign) BOOL hideBackgroundView;

// Provided for convenience to alter keyboard behavior
@property (nonatomic, weak) IBOutlet UITextField *firstTextField;
@property (nonatomic, weak) IBOutlet UITextField *secondTextField;

@property (nonatomic, weak) IBOutlet UILabel *firstTextFieldLabel;
@property (nonatomic, weak) IBOutlet UILabel *secondTextFieldLabel;

@property (nonatomic, copy) void (^singleTapCompletionBlock)(WPAlertView *);
@property (nonatomic, copy) void (^doubleTapCompletionBlock)(WPAlertView *);
@property (nonatomic, copy) void (^button1CompletionBlock)(WPAlertView *);
@property (nonatomic, copy) void (^button2CompletionBlock)(WPAlertView *);

- (id)initWithFrame:(CGRect)frame andOverlayMode:(WPAlertViewOverlayMode)overlayMode;
- (void)dismiss;

/**
 Hides or shows the title and description fields and updates relevant layout 
 constraints.  When the title and description are hidden the y offset of the rest
 of the form is shifted upward.
 
 @param hide `YES` to hide the title and description fields, `NO` to show them.
 */
- (void)hideTitleAndDescription:(BOOL)hide;

@end
