#import <UIKit/UIKit.h>

@class InlineComposeView;

@protocol InlineComposeViewDelegate <UITextViewDelegate>

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text;

@optional
/**
 Tells the delegate the user has typed @ sign. It will NOT work if the user replaces text.
 */
- (void)composeViewDidStartAtMention:(InlineComposeView *)view;

@end

@interface InlineComposeView : UIView

@property (nonatomic, weak) id <InlineComposeViewDelegate> delegate;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, weak) NSString *text;
@property (nonatomic, weak) NSAttributedString *attributedText;
@property (nonatomic, getter = isEnabled) BOOL enabled;
@property (nonatomic) BOOL shouldDeleteTagWithBackspace;

- (void)setButtonTitle:(NSString *)title;
- (void)clearText;
- (BOOL)isDisplayed;
- (void)toggleComposer;
- (void)dismissComposer;
- (void)displayComposer;

@end
