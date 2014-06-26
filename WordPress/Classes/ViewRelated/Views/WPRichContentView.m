#import "WPRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>

@interface WPRichContentView()<WPRichTextViewDelegate>

@property (nonatomic, readonly) WPRichTextView *richTextView;

@end

@implementation WPRichContentView

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    ((WPRichTextView *)self.contentView).delegate = nil;
}

- (UIView *)viewForContent
{
    WPRichTextView *richTextView = [[WPRichTextView alloc] init];
    richTextView.translatesAutoresizingMaskIntoConstraints = NO;
    richTextView.delegate = self;
    richTextView.edgeInsets = UIEdgeInsetsMake(0.0, WPContentViewHorizontalInnerPadding, 0.0, WPContentViewHorizontalInnerPadding);

    return richTextView;
}

- (void)configureContent
{
    NSData *data = [[self.contentProvider contentForDisplay] dataUsingEncoding:NSUTF8StringEncoding];
    self.richTextView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                   documentAttributes:nil];
}

- (WPRichTextView *)richTextView
{
    return (WPRichTextView *)self.contentView;
}


#pragma mark - Action Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveLinkAction:linkURL];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(ReaderImageView *)readerImageView
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveImageLinkAction:readerImageView];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(ReaderVideoView *)readerVideoView
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveVideoLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveVideoLinkAction:readerVideoView];
    }
}

- (void)richTextViewDidLoadAllMedia:(WPRichTextView *)richTextView
{
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadAllMedia:)]) {
        [self.delegate richTextViewDidLoadAllMedia:richTextView];
    }
}

@end
