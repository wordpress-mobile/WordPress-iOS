#import "ReaderPostRichContentView.h"
#import "WPRichTextView.h"
#import <DTCoreText/DTCoreText.h>

@interface ReaderPostRichContentView()<WPRichTextViewDelegate>

@property (nonatomic, readonly) WPRichTextView *richTextView;

@end


@implementation ReaderPostRichContentView

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    ((WPRichTextView *)self.contentView).delegate = nil;
}


#pragma mark - Public Methods

- (void)refreshMediaLayout
{
    [self.richTextView refreshMediaLayout];
}


#pragma mark - Private Methods

- (UILabel *)viewForTitle
{
    UILabel *label = [super viewForTitle];
    label.numberOfLines = 0;
    return label;
}

- (UIView *)viewForContent
{
    // Minimal frame so internal DTAttriutedTextContentView gets layout.
    CGRect frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), 1.0);
    CGFloat horizontalInnerPadding = WPContentViewHorizontalInnerPadding - 4.0;
    WPRichTextView *richTextView = [[WPRichTextView alloc] initWithFrame:frame];
    richTextView.translatesAutoresizingMaskIntoConstraints = NO;
    richTextView.delegate = self;
    richTextView.edgeInsets = UIEdgeInsetsMake(0.0, horizontalInnerPadding, 0.0, horizontalInnerPadding);
    return richTextView;
}

- (void)configureContentView
{
    NSString *content = [self.contentProvider contentForDisplay];
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    self.richTextView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                   documentAttributes:nil];
    self.richTextView.privateContent = [self privateContent];
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


#pragma mark - Action Methods

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

- (void)richTextViewDidLoadAllMedia:(WPRichTextView *)richTextView
{
    if ([self.delegate respondsToSelector:@selector(richTextViewDidLoadAllMedia:)]) {
        [self.delegate richTextViewDidLoadAllMedia:richTextView];
    }
}

@end
