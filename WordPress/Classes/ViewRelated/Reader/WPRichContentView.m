#import "WPRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>

@interface WPRichContentView()<WPRichTextViewDelegate>
// Convenience getter.
@property (nonatomic, readonly) WPRichTextView *richTextView;

@end

@implementation WPRichContentView

@dynamic delegate;

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    ((WPRichTextView *)self.contentView).delegate = nil;
}

#pragma mark - Private Methods

- (void)buildContentView
{
    WPRichTextView *richTextView = [[WPRichTextView alloc] init];
    richTextView.translatesAutoresizingMaskIntoConstraints = NO;
    richTextView.delegate = self;
    richTextView.edgeInsets = UIEdgeInsetsMake(0.0, WPContentViewHorizontalInnerPadding, 0.0, WPContentViewHorizontalInnerPadding);

    self.contentView = richTextView;
    [self addSubview:self.contentView];
}

- (void)configureContent
{
    self.richTextView.content = [self.contentProvider contentForDisplay];
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

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveImageLinkAction:imageControl];
    }
}

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadMediaBatch:)]) {
        [self.delegate richTextViewDidLoadMediaBatch:richTextView];
    }
}

@end
