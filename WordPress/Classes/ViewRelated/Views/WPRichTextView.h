#import <UIKit/UIKit.h>
#import "DTAttributedTextContentView.h"

@class ReaderImageView;
@class ReaderVideoView;
@class WPRichTextView;

@protocol WPRichTextViewDelegate <NSObject>
@optional
- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL;
- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(ReaderImageView *)readerImageView;
- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(ReaderVideoView *)readerVideoView;
- (void)richTextViewDidLoadAllMedia:(WPRichTextView *)richTextView;
@end

@interface WPRichTextView : UIView

@property (nonatomic, weak) id<WPRichTextViewDelegate> delegate;
@property (nonatomic) BOOL privateContent;
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic) UIEdgeInsets edgeInsets;

- (void)refreshMediaLayout;

@end
