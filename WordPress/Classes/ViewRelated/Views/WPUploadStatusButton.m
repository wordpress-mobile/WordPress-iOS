#import "WPUploadStatusButton.h"
#import <WordPressShared/WPFontManager.h>
#import "WordPress-Swift.h"
@import WordPressUI;


@implementation WPUploadStatusButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.frame = frame;
    [self setTitleColor: [UIColor murielAppBarText] forState: UIControlStateNormal];
    self.titleLabel.font = [WPFontManager systemRegularFontOfSize:14.0];
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.adjustsFontSizeToFitWidth = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self setAccessibilityHint:NSLocalizedString(@"Tap to cancel uploading.", @"This is a status indicator on the editor")];
    [self setTitle:NSLocalizedString(@"Uploading", @"\"Uploading\" Status text") forState:UIControlStateNormal];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    indicator.autoresizingMask = UIViewAutoresizingNone;
    CGFloat halfButtonHeight = self.bounds.size.height / 2;
    CGFloat buttonWidth = self.bounds.size.width;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight) {
        indicator.center = CGPointMake(buttonWidth - halfButtonHeight , halfButtonHeight);
    } else { // Position the loading indicator to the left of the button
        indicator.center = CGPointMake(-halfButtonHeight , halfButtonHeight);
    }
    [self addSubview:indicator];
    [indicator startAnimating];
    return self;
}

@end

