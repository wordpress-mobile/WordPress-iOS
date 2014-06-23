#import <UIKit/UIKit.h>
#import "DTAttributedTextContentView.h"

@class WPRichTextView;

@protocol WPRichTextViewDelegate <NSObject>
@optional
- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(id)sender;
- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(id)sender;
- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(id)sender;
- (void)contentViewDidLoadAllMedia:(WPRichTextView *)richTextView;
@end

@interface WPRichTextView : UIView

@property (nonatomic, weak) id<WPRichTextViewDelegate>delegate;
@property (nonatomic) BOOL privateContent;
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;

@end
