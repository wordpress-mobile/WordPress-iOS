#import "WPUploadStatusButton.h"
#import <WordPressShared/WPFontManager.h>

@implementation WPUploadStatusButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.frame = frame;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [WPFontManager systemBoldFontOfSize:14.0];
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.adjustsFontSizeToFitWidth = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self setAccessibilityHint:NSLocalizedString(@"Tap to cancel uploading.", @"This is a status indicator on the editor")];
    [self setTitle:NSLocalizedString(@"Uploading", @"\"Uploading\" Status text") forState:UIControlStateNormal];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.autoresizingMask = UIViewAutoresizingNone;
    CGFloat halfButtonHeight = self.bounds.size.height / 2;
    CGFloat buttonWidth = self.bounds.size.width;
    indicator.center = CGPointMake(buttonWidth - halfButtonHeight , halfButtonHeight);
    [self addSubview:indicator];
    [indicator startAnimating];
    return self;
}

@end

