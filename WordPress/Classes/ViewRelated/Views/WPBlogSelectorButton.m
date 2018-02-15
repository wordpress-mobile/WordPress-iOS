#import "WPBlogSelectorButton.h"
#import "WordPress-Swift.h"

@implementation WPBlogSelectorButton

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(WPBlogSelectorButtonStyle)buttonStyle
{
    WPBlogSelectorButton *button = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    button.buttonStyle = buttonStyle;
    button.frame = frame;
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.adjustsFontSizeToFitWidth = NO;
    [button setImage:[UIImage imageNamed:@"icon-nav-chevron"] forState:UIControlStateNormal];
    [button setAccessibilityHint:NSLocalizedString(@"Tap to select which blog to post to", @"This is the blog picker in the editor")];

    // Show image always in the opposite direction than a normal UIButton
    BOOL isLayoutLeftToRight = [button userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight;
    if (isLayoutLeftToRight) {
        button.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        button.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }

    switch (button.buttonStyle) {
        case WPBlogSelectorButtonTypeSingleLine:
            button.titleLabel.numberOfLines = 1;
            button.titleLabel.textAlignment = NSTextAlignmentNatural;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            if (isLayoutLeftToRight) {
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 0)];
            } else {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 0)];
            }
            break;
        case WPBlogSelectorButtonTypeStacked:
            button.titleLabel.numberOfLines = 2;
            button.titleLabel.textAlignment = NSTextAlignmentNatural;
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            if (isLayoutLeftToRight) {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, -10)];
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
            } else {
                [button setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
                [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -4, 0, -10)];
            }
            break;
    }
    
    return button;
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
