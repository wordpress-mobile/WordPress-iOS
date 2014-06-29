#import "ReaderPostAttributionView.h"
#import "WPStyleGuide.h"
#import "ContentActionButton.h"

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
    [followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, 2, 0, 0)];
    [followButton setContentEdgeInsets:UIEdgeInsetsMake(0, -3, 0, 0)];
    [followButton addTarget:self action:@selector(attributionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    return followButton;
}

@end
