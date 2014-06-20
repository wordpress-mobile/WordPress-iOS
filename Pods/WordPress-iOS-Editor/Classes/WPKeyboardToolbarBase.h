#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "WPKeyboardToolbarButtonItem.h"

#define WPKT_HEIGHT_IPHONE_PORTRAIT 40.0f
#define WPKT_HEIGHT_IPHONE_LANDSCAPE 33.0f
#define WPKT_HEIGHT_IPAD_PORTRAIT 65.0f
#define WPKT_HEIGHT_IPAD_LANDSCAPE 65.0f
#define WPKT_HEIGHT_PORTRAIT (IS_IPAD ? WPKT_HEIGHT_IPAD_PORTRAIT : WPKT_HEIGHT_IPHONE_PORTRAIT)
#define WPKT_HEIGHT_LANDSCAPE (IS_IPAD ? WPKT_HEIGHT_IPAD_LANDSCAPE : WPKT_HEIGHT_IPHONE_LANDSCAPE)

@protocol WPKeyboardToolbarDelegate <NSObject>
- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem;
@end

@interface WPKeyboardToolbarBase : UIView<UIInputViewAudioFeedback>

@property (nonatomic, weak) id<WPKeyboardToolbarDelegate> delegate;
@property (nonatomic, strong) UIView *formatView;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *boldButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *italicsButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *underlineButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *delButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *linkButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *quoteButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *moreButton;
@property (nonatomic, strong) WPKeyboardToolbarButtonItem *doneButton;

- (void)setupView;
- (void)setupFormatView;

@end
