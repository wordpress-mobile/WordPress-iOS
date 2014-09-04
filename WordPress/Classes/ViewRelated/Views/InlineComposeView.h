#import <UIKit/UIKit.h>

@class InlineComposeView;
@protocol MentionDelegate;

@protocol InlineComposeViewDelegate <UITextViewDelegate>

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text;

@end

@interface InlineComposeView : UIView

@property (nonatomic, weak) id <InlineComposeViewDelegate> delegate;
@property (nonatomic, weak) id <MentionDelegate> mentionDelegate;
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
