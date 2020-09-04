#import "WPBlogSelectorButton.h"
#import "WordPress-Swift.h"
@import WordPressUI;


@implementation WPBlogSelectorButton

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle
{
    WPBlogSelectorButton *button = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    button.buttonStyle = buttonStyle;
    button.frame = frame;

    button.titleLabel.textColor = [UIColor murielAppBarText];

    if ([Feature enabled:FeatureFlagNewNavBarAppearance]) {
        button.tintColor = [UIColor murielAppBarText];
        button.titleLabel.font = [WPStyleGuide navigationBarStandardFont];
    }

    button.titleLabel.adjustsFontSizeToFitWidth = NO;
    [button setImage:[UIImage imageNamed:@"icon-nav-chevron"] forState:UIControlStateNormal];
    [button setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", @"This is the blog picker in the editor")];

    [button invertLayout];

    BOOL isLayoutLeftToRight = [button userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight;
    switch (button.buttonStyle) {
        case WPBlogSelectorButtonTypeSingleLine:
            button.titleLabel.numberOfLines = 1;
            button.titleLabel.textAlignment = NSTextAlignmentNatural;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            if (isLayoutLeftToRight) {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 0)];
            } else {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 0)];
            }
            break;
        case WPBlogSelectorButtonTypeStacked:
            button.titleLabel.numberOfLines = 2;
            button.titleLabel.textAlignment = NSTextAlignmentNatural;
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            if (isLayoutLeftToRight) {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -4, 0, -10)];
            } else {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, -10)];
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
            }
            break;
    }
    
    return button;
}

/// Inverts the layout to show the image on the trailing side
///
- (void)invertLayout
{
    self.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.titleLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
}

- (void)setButtonMode:(WPBlogSelectorButtonMode)value
{
    _buttonMode = value;
    if (self.buttonMode == WPBlogSelectorButtonSingleSite) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 15), NO, 0.0);
        UIImage *blankFillerImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self setImage:blankFillerImage forState:UIControlStateNormal];
    } else {
        [self setImage:[UIImage imageNamed:@"icon-nav-chevron"] forState:UIControlStateNormal];
    }
}

@end
