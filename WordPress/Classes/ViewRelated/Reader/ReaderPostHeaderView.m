#import "ReaderPostHeaderView.h"
#import "WordPress-Swift.h"

const CGFloat PostHeaderViewAvatarSize = 32.0;
const CGFloat PostHeaderViewLabelHeight = 18.0;
const CGFloat PostHeaderDisclosureButtonWidth = 8.0;
const CGFloat PostHeaderDisclosureButtonHeight = 13.0;

@interface ReaderPostHeaderView()

@property (nonatomic, strong) UITapGestureRecognizer *tapsRegoznier;
@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *disclosureButton;

@end

@implementation ReaderPostHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _avatarImageView = [self newImageViewForAvatar];
        [self addSubview:_avatarImageView];

        _titleLabel = [self newLabelForTitle];
        [self addSubview:_titleLabel];

        _subtitleLabel = [self newLabelForSubtitle];
        [self addSubview:_subtitleLabel];

        _tapsRegoznier = [self newTapGestureRecognizer];
        [self addGestureRecognizer:_tapsRegoznier];

        _disclosureButton = [self newDisclosureButton];
        [self addSubview:_disclosureButton];

        [self configureConstraints];
    }
    return self;
}


#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
}

- (void)setShowsDisclosureIndicator:(BOOL)showsDisclosure
{
    _showsDisclosureIndicator = showsDisclosure;
    [self refreshDisclosureButton];
}

- (UIImage *)avatarImage
{
    return self.avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)image
{
    self.avatarImageView.image = image;
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

- (void)setSubtitle:(NSString *)title
{
    self.subtitleLabel.text = title;
}


#pragma mark - Private Methods

- (void)refreshDisclosureButton
{
    // TODO: iOS 7 doesn't allow us to simply disable a constraint. Let's improve this once the deploymentTarget is updated!
    CGFloat targetWidth = self.showsDisclosureIndicator ? PostHeaderDisclosureButtonWidth : 0.0f;
    [self.disclosureButton updateConstraint:NSLayoutAttributeWidth constant:targetWidth];
    self.disclosureButton.hidden = !self.showsDisclosureIndicator;
}

- (void)configureConstraints
{
    NSDictionary *views   = NSDictionaryOfVariableBindings(_avatarImageView, _titleLabel, _subtitleLabel, _disclosureButton);
    NSDictionary *metrics = @{
                              @"avatarSize"       : @(PostHeaderViewAvatarSize),
                              @"labelHeight"      : @(PostHeaderViewLabelHeight),
                              @"disclosureWidth"  : @(PostHeaderDisclosureButtonWidth),
                              @"disclosureHeight" : @(PostHeaderDisclosureButtonHeight)
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_avatarImageView(avatarSize)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_disclosureButton(disclosureWidth)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_disclosureButton(disclosureHeight)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_avatarImageView]-[_titleLabel]-[_disclosureButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_avatarImageView]-[_subtitleLabel]-[_disclosureButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[_subtitleLabel(labelHeight)][_titleLabel(labelHeight)]-(-2)-|"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_disclosureButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_avatarImageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    [super setNeedsUpdateConstraints];
}


#pragma mark - Subview factories

- (UILabel *)newLabelForTitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (UILabel *)newLabelForSubtitle
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (CircularImageView *)newImageViewForAvatar
{
    CGRect avatarFrame = CGRectMake(0.0f, 0.0f, PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
    CircularImageView *imageView = [[CircularImageView alloc] initWithFrame:avatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

- (UITapGestureRecognizer *)newTapGestureRecognizer
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped:)];
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.numberOfTapsRequired = 1;
    return tapGesture;
}

- (UIButton *)newDisclosureButton
{
    UIImage *chevronImage = [UIImage imageNamed:@"disclosure-chevron"];
    UIButton *disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [disclosureButton setBackgroundImage:chevronImage forState:UIControlStateNormal];
    disclosureButton.translatesAutoresizingMaskIntoConstraints = NO;
    return disclosureButton;
}


#pragma mark - Recognizer Helpers

- (void)handleViewTapped:(UITapGestureRecognizer *)recognizer
{
    if (self.onClick) {
        self.onClick();
    }
}

@end
