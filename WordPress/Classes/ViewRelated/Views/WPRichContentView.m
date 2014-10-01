#import "WPRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>

@interface WPRichContentView()<WPRichTextViewDelegate>
// Convenience getter.
@property (nonatomic, readonly) WPRichTextView *richTextView;

@end

@implementation WPRichContentView

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    ((WPRichTextView *)self.contentView).delegate = nil;
}

#pragma mark - Private Methods

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

- (CGSize)sizeThatFitsContent:(CGSize)size
{
    return self.richTextView.intrinsicContentSize;
}

- (CGFloat)horizontalMarginForContent
{
    return 0;
}

#pragma mark - WPRichText View Methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveLinkAction:linkURL];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImageControl *)imageControl
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveImageLinkAction:imageControl];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(WPRichTextVideoControl *)videoControl
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveVideoLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveVideoLinkAction:videoControl];
    }
}

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
        [self.delegate richTextViewDidLoadMediaBatch:richTextView];
    }
}

@end
