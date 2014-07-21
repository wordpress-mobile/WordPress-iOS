#import "PostAttributionView.h"
#import "WPStyleGuide.h"
#import "Post.h"

@interface PostAttributionView ()

@property(nonatomic, strong) UILabel *postStatusLabel;

@end

@implementation PostAttributionView

- (void)setupSubviews {
    [super setupSubviews];

    self.attributionNameLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];

    _postStatusLabel = [self labelForPostStatus];
    [self addSubview:_postStatusLabel];
}

- (void)configureConstraints
{
    UIImageView *avatarImageView = self.avatarImageView;
    UILabel *attributionNameLabel = self.attributionNameLabel;
    UILabel *postStatusLabel = self.postStatusLabel;

    NSDictionary *views = NSDictionaryOfVariableBindings(avatarImageView, attributionNameLabel, postStatusLabel);
    NSDictionary *metrics = @{@"avatarSize": @(WPContentAttributionViewAvatarSize),
                              @"labelHeight":@(WPContentAttributionLabelHeight)};
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
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[postStatusLabel]|"
                                                                 options:NSLayoutFormatAlignAllBottom
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[attributionNameLabel(labelHeight)][postStatusLabel(labelHeight)]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [super setNeedsUpdateConstraints];
}

- (void)configureView {
    [super configureView];
    self.postStatusLabel.text = [self.contentProvider statusForDisplay];
}

- (void)configureAttributionButton {
    [self hideAttributionButton:YES];
}

#pragma mark - Subview factories

- (UILabel *)labelForPostStatus
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide fireOrange];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

@end
