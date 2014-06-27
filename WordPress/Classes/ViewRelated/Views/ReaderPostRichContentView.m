#import "ReaderPostRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>

@interface ReaderPostRichContentView()<WPRichTextViewDelegate>

@property (nonatomic, readonly) WPRichTextView *richTextView;

@end


@implementation ReaderPostRichContentView

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

- (void)configureContentView
{
    NSString *content = [self.contentProvider contentForDisplay];
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    self.richTextView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                   documentAttributes:nil];
}

- (WPRichTextView *)richTextView
{
    return (WPRichTextView *)self.contentView;
}

- (void)refreshMediaLayout
{
    [self.richTextView refreshMediaLayout];
}

- (CGSize)sizeThatFitsContent:(CGSize)size
{
    return self.richTextView.intrinsicContentSize;
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
