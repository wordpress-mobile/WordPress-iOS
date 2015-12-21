#import "MeHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"

const CGFloat MeHeaderViewHeight = 210;
const CGFloat MeHeaderViewGravatarSize = 120.0;
const CGFloat MeHeaderViewLabelHeight = 20.0;
const CGFloat MeHeaderViewVerticalMargin = 20.0;
const CGFloat MeHeaderViewVerticalSpacing = 10.0;

@interface MeHeaderView ()

@property (nonatomic, strong) UIImageView *gravatarImageView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;

@end

@implementation MeHeaderView

- (instancetype)init
{
    CGRect frame = CGRectMake(0, 0, 0, MeHeaderViewHeight);
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gravatarImageView = [self imageViewForGravatar];
        [self addSubview:_gravatarImageView];

        _displayNameLabel = [self labelForDisplayName];
        [self addSubview:_displayNameLabel];

        _usernameLabel = [self labelForUsername];
        [self addSubview:_usernameLabel];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, MeHeaderViewHeight);
}

- (void)setDisplayName:(NSString *)displayName
{
    self.displayNameLabel.text = displayName;
}

- (void)setUsername:(NSString *)username
{
    // If the username is an email, we don't want the preceding @ sign before it
    NSString *prefix = ([username rangeOfString:@"@"].location != NSNotFound) ? @"" : @"@";
    self.usernameLabel.text = [NSString stringWithFormat:@"%@%@", prefix, username];
}

- (void)setGravatarEmail:(NSString *)gravatarEmail
{
    // Since this view is only visible to the current user, we should show all ratings
    [self.gravatarImageView setImageWithGravatarEmail:gravatarEmail gravatarRating:GravatarRatingX];
}

#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_gravatarImageView, _displayNameLabel, _usernameLabel);
    NSDictionary *metrics = @{@"gravatarSize": @(MeHeaderViewGravatarSize),
                              @"labelHeight":@(MeHeaderViewLabelHeight),
                              @"verticalSpacing":@(MeHeaderViewVerticalSpacing),
                              @"verticalMargin":@(MeHeaderViewVerticalMargin)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-verticalMargin-[_gravatarImageView(gravatarSize)]-verticalSpacing-[_displayNameLabel(labelHeight)][_usernameLabel(labelHeight)]-verticalMargin-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_gravatarImageView(gravatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.gravatarImageView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.displayNameLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.usernameLabel
                                                    attribute:NSLayoutAttributeCenterX
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:self
                                                    attribute:NSLayoutAttributeCenterX
                                                   multiplier:1
                                                      constant:0]];
    [super setNeedsUpdateConstraints];
}

#pragma mark - Subview factories

- (UILabel *)labelForDisplayName
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide darkGrey];
    label.font = [WPStyleGuide regularTextFontSemiBold];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;

    return label;
}

- (UILabel *)labelForUsername
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide grey];
    label.font = [WPStyleGuide regularTextFont];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;

    return label;
}

- (UIImageView *)imageViewForGravatar
{
    CGRect gravatarFrame = CGRectMake(0.0f, 0.0f, MeHeaderViewGravatarSize, MeHeaderViewGravatarSize);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:gravatarFrame];
    imageView.layer.cornerRadius = MeHeaderViewGravatarSize / 2.0;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

@end
