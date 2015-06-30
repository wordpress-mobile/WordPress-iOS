#import "MeHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"

const CGFloat MeHeaderViewHeight = 175;
const CGFloat MeHeaderViewGravatarSize = 120.0;
const CGFloat MeHeaderViewLabelHeight = 20.0;
const CGFloat MeHeaderViewVerticalMargin = 10.0;

@interface MeHeaderView ()

@property (nonatomic, strong) UIImageView *gravatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;

@end

@implementation MeHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gravatarImageView = [self imageViewForGravatar];
        [self addSubview:_gravatarImageView];

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

- (void)setUsername:(NSString *)username
{
    // If the username is an email, we don't want the preceding @ sign before it
    NSString *prefix = ([username rangeOfString:@"@"].location != NSNotFound) ? @"" : @"@";
    self.usernameLabel.text = [NSString stringWithFormat:@"%@%@", prefix, username];;
}

- (void)setGravatarEmail:(NSString *)gravatarEmail
{
    // Since this view is only visible to the current user, we should show all ratings
    [self.gravatarImageView setImageWithGravatarEmail:gravatarEmail gravatarRating:GravatarRatingX];
}

#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_gravatarImageView, _usernameLabel);
    NSDictionary *metrics = @{@"gravatarSize": @(MeHeaderViewGravatarSize),
                              @"labelHeight":@(MeHeaderViewLabelHeight),
                              @"verticalMargin":@(MeHeaderViewVerticalMargin)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-verticalMargin-[_gravatarImageView(gravatarSize)]-verticalMargin-[_usernameLabel(labelHeight)]"
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

- (UILabel *)labelForUsername
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide wordPressBlue];
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
