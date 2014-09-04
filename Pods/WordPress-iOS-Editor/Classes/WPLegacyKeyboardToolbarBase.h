#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "WPLegacyKeyboardToolbarButtonItem.h"

#define WPKT_HEIGHT_IPHONE_PORTRAIT 40.0f
#define WPKT_HEIGHT_IPHONE_LANDSCAPE 33.0f
#define WPKT_HEIGHT_IPAD_PORTRAIT 65.0f
#define WPKT_HEIGHT_IPAD_LANDSCAPE 65.0f
#define WPKT_HEIGHT_PORTRAIT (IS_IPAD ? WPKT_HEIGHT_IPAD_PORTRAIT : WPKT_HEIGHT_IPHONE_PORTRAIT)
#define WPKT_HEIGHT_LANDSCAPE (IS_IPAD ? WPKT_HEIGHT_IPAD_LANDSCAPE : WPKT_HEIGHT_IPHONE_LANDSCAPE)

@protocol WPLegacyKeyboardToolbarDelegate <NSObject>
- (void)keyboardToolbarButtonItemPressed:(WPLegacyKeyboardToolbarButtonItem *)buttonItem;
@end

@interface WPLegacyKeyboardToolbarBase : UIView<UIInputViewAudioFeedback>

@property (nonatomic, weak) id<WPLegacyKeyboardToolbarDelegate> delegate;
@property (nonatomic, strong) UIView *formatView;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *boldButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *italicsButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *underlineButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *delButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *linkButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *quoteButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *moreButton;
@property (nonatomic, strong) WPLegacyKeyboardToolbarButtonItem *doneButton;

- (void)setupView;
- (void)setupFormatView;

@end
