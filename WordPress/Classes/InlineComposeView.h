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

@end
