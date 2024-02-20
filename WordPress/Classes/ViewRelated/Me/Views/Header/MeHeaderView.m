#import "MeHeaderView.h"
#import "Blog.h"
#import "WordPress-Swift.h"
#import "Gravatar-Swift.h"

const CGFloat MeHeaderViewHeight = 154;
const CGFloat MeHeaderViewGravatarSize = 64.0;
const CGFloat MeHeaderViewLabelHeight = 20.0;
const CGFloat MeHeaderViewVerticalMargin = 20.0;
const CGFloat MeHeaderViewVerticalSpacing = 10.0;

@interface MeHeaderView () <UIDropInteractionDelegate>

@property (nonatomic, strong) UIImageView *gravatarImageView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation MeHeaderView

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _gravatarImageView = [self newImageViewForGravatar];
        _displayNameLabel = [self newLabelForDisplayName];
        _usernameLabel = [self newLabelForUsername];

        _stackView = [self newStackView];
        [self addSubview:_stackView];

        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setDisplayName:(NSString *)displayName
{
    self.displayNameLabel.text = displayName;
}

- (NSString *)displayName
{
    return self.displayNameLabel.text;
}

- (void)setUsername:(NSString *)username
{
    // If the username is an email, we don't want the preceding @ sign before it
    NSString *prefix = ([username rangeOfString:@"@"].location != NSNotFound) ? @"" : @"@";
    self.usernameLabel.text = [NSString stringWithFormat:@"%@%@", prefix, username];
}

- (NSString *)username
{
    return self.usernameLabel.text;
}

- (void)setGravatarEmail:(NSString *)gravatarEmail
{    
    // Since this view is only visible to the current user, we should show all ratings
    [self.gravatarImageView downloadGravatarFor:gravatarEmail gravatarRating:GravatarRatingX];
    _gravatarEmail = gravatarEmail;
}

- (void)overrideGravatarImage:(UIImage *)gravatarImage
{
    self.gravatarImageView.image = gravatarImage;
    
    // Note:
    // We need to update the internal cache. Otherwise, any upcoming query to refresh the gravatar
    // might return the cached (outdated) image, and the UI will end up in an inconsistent state.
    //
    [self.gravatarImageView overrideGravatarImageCache:gravatarImage rating:GravatarRatingsX email:self.gravatarEmail];
    [self.gravatarImageView updateGravatarWithImage:gravatarImage email:self.gravatarEmail];
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    UIView *spaceView = [UIView new];
    [self.stackView addArrangedSubview:self.gravatarImageView];
    [self.stackView addArrangedSubview:spaceView];
    [self.stackView addArrangedSubview:self.displayNameLabel];
    [self.stackView addArrangedSubview:self.usernameLabel];
    NSLayoutConstraint *heightConstraint =  [self.gravatarImageView.heightAnchor constraintEqualToConstant:MeHeaderViewGravatarSize];
    heightConstraint.priority = 999;
    NSLayoutConstraint *spaceHeightConstraint =  [spaceView.heightAnchor constraintEqualToConstant:MeHeaderViewVerticalSpacing];
    heightConstraint.priority = 999;
    NSLayoutConstraint *stackViewTopConstraint =  [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:MeHeaderViewVerticalSpacing];
    stackViewTopConstraint.priority = 999;
    NSLayoutConstraint *stackViewBottomConstraint =  [self.bottomAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:MeHeaderViewVerticalSpacing];
    stackViewBottomConstraint.priority = 999;
    NSArray *constraints = @[
                             heightConstraint,
                             [self.gravatarImageView.widthAnchor constraintEqualToConstant:MeHeaderViewGravatarSize],
                             spaceHeightConstraint,
                             stackViewTopConstraint,
                             stackViewBottomConstraint,
                             [self.stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                             ];

    [NSLayoutConstraint activateConstraints:constraints];

    [super setNeedsUpdateConstraints];
}

#pragma mark - Subview factories

- (UIStackView *)newStackView
{
    UIStackView *stackView = [UIStackView new];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentCenter;
    return stackView;
}

- (UILabel *)newLabelForDisplayName
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [UIColor murielText];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.accessibilityIdentifier = @"Display Name";
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleHeadline
                      fontWeight:UIFontWeightSemibold];
    return label;
}

- (UILabel *)newLabelForUsername
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [UIColor murielTextSubtle];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.accessibilityIdentifier = @"Username";
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleCallout];

    return label;
}

- (UIImageView *)newImageViewForGravatar
{
    CGRect gravatarFrame = CGRectMake(0.0f, 0.0f, MeHeaderViewGravatarSize, MeHeaderViewGravatarSize);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:gravatarFrame];
    imageView.layer.cornerRadius = MeHeaderViewGravatarSize * 0.5;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.userInteractionEnabled = YES;
    return imageView;
}

@end
