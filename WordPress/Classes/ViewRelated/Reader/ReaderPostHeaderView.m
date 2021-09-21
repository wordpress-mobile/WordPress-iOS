#import "ReaderPostHeaderView.h"
#import "WordPress-Swift.h"

const CGFloat PostHeaderViewAvatarSize = 32.0;
const CGFloat PostHeaderViewLabelHeight = 18.0;
const CGFloat PostHeaderDisclosureButtonWidth = 8.0;
const CGFloat PostHeaderDisclosureButtonHeight = 13.0;
const CGFloat PostHeaderViewFollowConversationButtonHeight = 32.0;

@interface ReaderPostHeaderView()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *followConversationButton;
@property (nonatomic, strong) UIButton *disclosureButton;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

@end

@implementation ReaderPostHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.preservesSuperviewLayoutMargins = YES;
        self.backgroundColor = [UIColor murielListForeground];

        [self setupStackView];
        [self setupAvatarImageView];
        [self setupLabelsStackView];
        [self setupSubtitleLabel];
        [self setupTitleLabel];
        [self setupFollowConversationButton];
        [self setupDisclosureButton];
        [self setupTapGesture];
    }
    return self;
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentTop;
    stackView.spacing = 8.0;

    [self addSubview:stackView];
    self.stackView = stackView;

    UILayoutGuide *readableGuide = self.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [stackView.topAnchor constraintEqualToAnchor:readableGuide.topAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:readableGuide.bottomAnchor]
                                              ]];
}

- (void)setupAvatarImageView
{
    NSAssert(self.stackView != nil, @"stackView was nil");

    CircularImageView *imageView = [[CircularImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
                                             [imageView.widthAnchor constraintEqualToConstant:PostHeaderViewAvatarSize],
                                             [imageView.heightAnchor constraintEqualToConstant:PostHeaderViewAvatarSize]
                                             ]];

    [self.stackView addArrangedSubview:imageView];
    self.avatarImageView = imageView;
}

- (void)setupLabelsStackView
{
    NSAssert(self.stackView != nil, @"stackView was nil");

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.layoutMarginsRelativeArrangement = YES;
    stackView.preservesSuperviewLayoutMargins = YES;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentLeading;

    [self.stackView addArrangedSubview:stackView];
    self.labelsStackView = stackView;

    [stackView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setupSubtitleLabel
{
    NSAssert(self.labelsStackView != nil, @"labelsStackView was nil");

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = [UIColor murielListForeground];
    label.opaque = YES;
    label.textColor = [UIColor murielTextSubtle];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontForContentSizeCategory = YES;

    [self.labelsStackView addArrangedSubview:label];
    self.subtitleLabel = label;
}

- (void)setupTitleLabel
{
    NSAssert(self.labelsStackView != nil, @"labelsStackView was nil");

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = [UIColor murielListForeground];
    label.opaque = YES;
    label.textColor = [UIColor murielText];
    label.font = [WPStyleGuide subtitleFont];
    label.adjustsFontForContentSizeCategory = YES;

    [self.labelsStackView addArrangedSubview:label];
    self.titleLabel = label;
}

- (void)setupFollowConversationButton
{
    NSAssert(self.labelsStackView != nil, @"labelsStackView was nil");

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    [button addTarget:self
               action:@selector(followConversationButtonTapped)
     forControlEvents:UIControlEventTouchUpInside];

    [WPStyleGuide applyReaderFollowConversationButtonStyle:button];

    NSString *normalText = NSLocalizedString(@"Follow conversation by email", @"Verb. Button title. Follow the comments on a post.");
    NSString *selectedText = NSLocalizedString(@"Following conversation by email", @"Verb. Button title. The user is following the comments on a post.");

    [button setTitle:normalText forState:UIControlStateNormal];
    [button setTitle:selectedText forState:UIControlStateSelected];
    [button setTitle:selectedText forState:UIControlStateHighlighted];

    // Default accessibility label and hint.
    button.accessibilityLabel = button.isSelected ? selectedText : normalText;
    button.accessibilityHint = NSLocalizedString(@"Follows the comments on a post by email.", @"VoiceOver accessibility hint, informing the user the button can be used to follow the comments a post.");
    
    NSLayoutConstraint *height = [button.heightAnchor constraintEqualToConstant:PostHeaderViewFollowConversationButtonHeight];
    [NSLayoutConstraint activateConstraints:@[height]];
    
    [self.labelsStackView addArrangedSubview:button];
    self.followConversationButton = button;
}

- (void)setupDisclosureButton
{
    NSAssert(self.stackView != nil, @"stackView was nil");

    UIImage *chevronImage = [[UIImage imageNamed:@"disclosure-chevron"] imageFlippedForRightToLeftLayoutDirection];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setBackgroundImage:chevronImage forState:UIControlStateNormal];

    NSLayoutConstraint *width = [button.widthAnchor constraintEqualToConstant:chevronImage.size.width];
    width.priority = 999;
    NSLayoutConstraint *height = [button.heightAnchor constraintEqualToConstant:chevronImage.size.height];

    [NSLayoutConstraint activateConstraints:@[
                                              width,
                                              height
                                              ]];

    [self.stackView addArrangedSubview:button];
    self.disclosureButton = button;
}

- (void)setupTapGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleViewTapped:)];
    [self addGestureRecognizer:tapGesture];
    self.tapRecognizer = tapGesture;
}

#pragma mark - Public Methods

- (void)setShowsDisclosureIndicator:(BOOL)showsDisclosure
{
    _showsDisclosureIndicator = showsDisclosure;
    self.disclosureButton.hidden = !showsDisclosure;
}

- (void)setShowsFollowConversationButton:(BOOL)showsFollowConversationButton
{
    _showsFollowConversationButton = showsFollowConversationButton;
    self.followConversationButton.hidden = !showsFollowConversationButton;
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

- (void)setSubscribedToPost:(BOOL)isSubscribedToPost
{
    _isSubscribedToPost = isSubscribedToPost;
    [self.followConversationButton setSelected:isSubscribedToPost];
}

#pragma mark - Button Action Helpers

- (void)followConversationButtonTapped
{
    if (self.onFollowConversationClick) {
        self.onFollowConversationClick();
    }
}

#pragma mark - Recognizer Helpers

- (void)handleViewTapped:(UITapGestureRecognizer *)recognizer
{
    if (self.onClick) {
        self.onClick();
    }
}

@end
