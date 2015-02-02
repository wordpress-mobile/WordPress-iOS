#import "ReaderPostHeaderView.h"
#import "WordPress-Swift.h"

const CGFloat PostHeaderDisclosureButtonWidth = 8.0f;
const CGFloat PostHeaderDisclosureButtonHeight = 13.0f;

@interface ReaderPostHeaderView()

@property (nonatomic, strong) UITapGestureRecognizer *tapsRegoznier;
@property (nonatomic, strong) UIButton *disclosureButton;

@end

@implementation ReaderPostHeaderView

#pragma mark - Public Methods

- (void)setShowsDisclosureIndicator:(BOOL)showsDisclosure
{
    _showsDisclosureIndicator = showsDisclosure;
    [self refreshDisclosureButton];
}

#pragma mark - Private Methods

- (void)buildSubviews
{
    [super buildSubviews];

    _tapsRegoznier = [self newTapGestureRecognizer];
    [self addGestureRecognizer:_tapsRegoznier];

    _disclosureButton = [self newDisclosureButton];
    [self addSubview:_disclosureButton];
}

- (void)refreshDisclosureButton
{
    // TODO: iOS 7 doesn't allow us to simply disable a constraint. Let's improve this once the deploymentTarget is updated!
    CGFloat targetWidth = self.showsDisclosureIndicator ? PostHeaderDisclosureButtonWidth : 0.0f;
    [self.disclosureButton updateConstraint:NSLayoutAttributeWidth constant:targetWidth];
    self.disclosureButton.hidden = !self.showsDisclosureIndicator;
}

- (void)configureConstraints
{
    // Do not call super.

    UIImageView *avatarImageView = self.avatarImageView;
    UILabel *titleLabel = self.titleLabel;
    UILabel *subtitleLabel = self.subtitleLabel;
    NSDictionary *views   = NSDictionaryOfVariableBindings(avatarImageView, titleLabel, subtitleLabel, _disclosureButton);
    NSDictionary *metrics = @{
        @"avatarSize"       : @(ReaderHeaderViewAvatarSize),
        @"labelHeight"      : @(ReaderHeaderViewLabelHeight),
        @"disclosureWidth"  : @(PostHeaderDisclosureButtonWidth),
        @"disclosureHeight" : @(PostHeaderDisclosureButtonHeight)
    };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[avatarImageView(avatarSize)]|"
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
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[avatarImageView]-[titleLabel]-[_disclosureButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[avatarImageView]-[subtitleLabel]-[_disclosureButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[subtitleLabel(labelHeight)][titleLabel(labelHeight)]-(-2)-|"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_disclosureButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:avatarImageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    [self setNeedsUpdateConstraints];
}


#pragma mark - Subview factories

- (UITapGestureRecognizer *)newTapGestureRecognizer
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewTapped:)];
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
