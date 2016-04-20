#import "WPUploadStatusButton.h"
#import <WordPressShared/WPFontManager.h>

@implementation WPUploadStatusButton

+ (id)buttonWithFrame:(CGRect)frame
{
    WPUploadStatusButton *button = [WPUploadStatusButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = [WPFontManager systemBoldFontOfSize:14.0];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.adjustsFontSizeToFitWidth = NO;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button setAccessibilityHint:NSLocalizedString(@"Tap to cancel uploading.", nil)];
    [button setTitle:NSLocalizedString(@"Uploading...", @"\"Uploading...\" Status text") forState:UIControlStateNormal];
    [button setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", @"This is the blog picker in the editor")];
    button.titleLabel.numberOfLines = 1;
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.autoresizingMask = UIViewAutoresizingNone;
    CGFloat halfButtonHeight = button.bounds.size.height / 2;
    CGFloat buttonWidth = button.bounds.size.width;
    indicator.center = CGPointMake(buttonWidth - halfButtonHeight , halfButtonHeight);
    [button addSubview:indicator];
    [indicator startAnimating];
    return button;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleLabel.frame = [self titleRectForContentRect:self.bounds];
    self.imageView.frame = [self imageRectForContentRect:self.bounds];
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super imageRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX([self titleRectForContentRect:contentRect]) + self.imageEdgeInsets.left;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super titleRectForContentRect:contentRect];
    frame.size.width = MIN(frame.size.width, CGRectGetWidth(contentRect) - CGRectGetWidth([super imageRectForContentRect:contentRect]) - self.imageEdgeInsets.left - self.imageEdgeInsets.right);
    frame.origin.x = 0.0;
    return frame;
}

@end

