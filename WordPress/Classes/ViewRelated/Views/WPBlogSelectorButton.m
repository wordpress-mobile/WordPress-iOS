#import "WPBlogSelectorButton.h"

@interface WPBlogSelectorButton()
    @property (nonatomic, strong) UIImage *selectorImage;
@end

@implementation WPBlogSelectorButton

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle
{
    WPBlogSelectorButton *button = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    button.buttonStyle = buttonStyle;
    button.frame = frame;
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.adjustsFontSizeToFitWidth = NO;
    button.selectorImage = [UIImage imageNamed:@"icon-nav-chevron"];
    [button setImage:button.selectorImage forState:UIControlStateNormal];
    [button setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", @"This is the blog picker in the editor")];
    
    switch (button.buttonStyle) {
        case WPBlogSelectorButtonTypeSingleLine:
            button.titleLabel.numberOfLines = 1;
            button.titleLabel.textAlignment = NSTextAlignmentLeft;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            [button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            break;
        case WPBlogSelectorButtonTypeStacked:
        default:
            button.titleLabel.numberOfLines = 2;
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [button setImageEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 10)];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
            break;
    }
    
    return button;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleLabel.frame = [self titleRectForContentRect:self.bounds];
    self.imageView.frame = [self imageRectForContentRect:self.bounds];
    self.imageView.hidden = NO;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super imageRectForContentRect:contentRect];
    CGRect titleContentRect = [self titleRectForContentRect:contentRect];
    frame.origin.x = CGRectGetMaxX(titleContentRect) + self.imageEdgeInsets.left;
    CGSize imageSize = self.selectorImage.size;
    frame.origin.y = CGRectGetMidY(titleContentRect) - (imageSize.height / 2);
    frame.size.height = imageSize.height;
    frame.size.width = imageSize.width;
    return frame;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    CGRect frame = [super titleRectForContentRect:contentRect];
    frame.size.width = MIN(frame.size.width, CGRectGetWidth(contentRect) - CGRectGetWidth([super imageRectForContentRect:contentRect]) - self.imageEdgeInsets.right);
    switch (self.buttonStyle) {
        case WPBlogSelectorButtonTypeSingleLine:
            frame.origin.x = 0.0;
            break;
        case WPBlogSelectorButtonTypeStacked:
        default:
            frame.origin.x = CGRectGetMidX(contentRect) - CGRectGetWidth(frame) / 2.0;
            break;
    }

    return frame;
}

- (void)setButtonMode:(WPBlogSelectorButtonMode)value
{
    _buttonMode = value;
    if (self.buttonMode == WPBlogSelectorButtonSingleSite) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), NO, 0.0);
        UIImage *blankFillerImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.selectorImage = blankFillerImage;
    } else {
        self.selectorImage = [UIImage imageNamed:@"icon-nav-chevron"];
    }
    [self setImage:self.selectorImage forState:UIControlStateNormal];
}

@end
