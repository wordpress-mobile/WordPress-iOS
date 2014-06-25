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

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveLinkAction:)]) {
        [self.delegate contentView:self didReceiveLinkAction:sender];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveImageLinkAction:)]) {
        [self.delegate contentView:self didReceiveImageLinkAction:sender];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveVideoLinkAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveVideoLinkAction:)]) {
        [self.delegate contentView:self didReceiveVideoLinkAction:sender];
    }
}

@end
