#import "ReaderPostAttributionView.h"
#import "WPStyleGuide.h"
#import "ContentActionButton.h"

const CGFloat RPAVButtonTitleLeftEdgeInset = 2.0;
const CGFloat RPAVButtonContentLeftEdgeInset = -3.0;

@implementation ReaderPostAttributionView

- (void)configureAttributionButton
{
    //noop.
}

- (UIButton *)buttonForAttributionLink
{
    ContentActionButton *followButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
    followButton.translatesAutoresizingMaskIntoConstraints = NO;
    [WPStyleGuide configureFollowButton:followButton];
    [followButton setTitleEdgeInsets: UIEdgeInsetsMake(0.0, RPAVButtonTitleLeftEdgeInset, 0.0, 0.0)];
    [followButton setContentEdgeInsets:UIEdgeInsetsMake(0.0, RPAVButtonContentLeftEdgeInset, 0.0, 0.0)];
    [followButton addTarget:self action:@selector(attributionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    followButton.accessibilityIdentifier = @"Follow";
    return followButton;
}

@end
