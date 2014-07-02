#import "WPSimpleContentAttributionView.h"

@implementation WPSimpleContentAttributionView

- (void)configureConstraints
{
    UIView *avatarImageView = self.avatarImageView;
    UIView *attributionNameLabel = self.attributionNameLabel;
    UIView *attributionLinkButton = self.attributionLinkButton;

    NSDictionary *views = NSDictionaryOfVariableBindings(avatarImageView, attributionNameLabel, attributionLinkButton);
    NSDictionary *metrics = @{@"avatarSize": @(WPContentAttributionViewAvatarSize)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[avatarImageView(avatarSize)]"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarImageView(avatarSize)]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[attributionNameLabel]|"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[attributionNameLabel]|"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [super setNeedsUpdateConstraints];
}

- (void)configureAttributionButton
{
    [self hideAttributionButton:YES];
}

@end
