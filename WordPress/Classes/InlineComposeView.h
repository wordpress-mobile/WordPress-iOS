//
//  InlineComposeView.h
//  WordPress
//

#import <UIKit/UIKit.h>

@class InlineComposeView;

@protocol InlineComposeViewDelegate <UITextViewDelegate>

- (void)composeView:(InlineComposeView *)view didSendText:(NSString *)text;

@end

@interface InlineComposeView : UIView

@property (nonatomic, weak) id <InlineComposeViewDelegate> delegate;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic) NSString *text;
@property (nonatomic) NSAttributedString *attributedText;

@end
