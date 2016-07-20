#import "BlogDetailHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"
#import <WordPressShared/WPFontManager.h>
#import "WordPress-Swift.h"


const CGFloat BlogDetailHeaderViewBlavatarSize = 40.0;
const CGFloat BlogDetailHeaderViewLabelHorizontalPadding = 10.0;

@interface BlogDetailHeaderView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation BlogDetailHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupStackView];
        [self setupBalavatarImageView];
        [self setupLabelsStackView];
        [self setupTitleLabel];
        [self setupSubtitleLabel];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setBlog:(Blog *)blog
{
    [self.blavatarImageView setImageWithSiteIcon:blog.icon];

    // if the blog name is missing, we want to show the blog displayURL instead
    NSString *blogName = blog.settings.name;
    [self.titleLabel setText:((blogName && !blogName.isEmpty) ? blogName : blog.displayURL)];
    [self.subtitleLabel setText:blog.displayURL];
    [self.labelsStackView setNeedsLayout];
}

#pragma mark - Subview setup

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = BlogDetailHeaderViewLabelHorizontalPadding;
    [self addSubview:stackView];

    NSLayoutConstraint *leadingConstraint;
    NSLayoutConstraint *trailingConstraint;

    if ([WPDeviceIdentification isiPhone]) {
        // On iPhone, the readable content guide seems to be accurately aligned with the cell's content margins.
        UILayoutGuide *readableGuide = self.readableContentGuide;
        leadingConstraint = [stackView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor];
        trailingConstraint = [stackView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor];
    } else {
        // On iPad, the correct readable margins seem to already be inherited via the tableHeaderView
        // so following this view's readable content guide is not necessary.
        leadingConstraint = [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
        trailingConstraint = [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
    }

    [NSLayoutConstraint activateConstraints:@[
                                              leadingConstraint,
                                              trailingConstraint,
                                              [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              [stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                                              [stackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
                                              ]];
    _stackView = stackView;
}

- (void)setupBalavatarImageView
{
    NSAssert(_stackView != nil, @"stackView was nil");

    CGRect blavatarFrame = CGRectMake(0.0f, 0.0f, BlogDetailHeaderViewBlavatarSize, BlogDetailHeaderViewBlavatarSize);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:blavatarFrame];
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    imageView.layer.borderWidth = 1.0;
    [_stackView addArrangedSubview:imageView];

    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.widthAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize],
                                              [imageView.heightAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize]
                                              ]];
    _blavatarImageView = imageView;
}

- (void)setupLabelsStackView
{
    NSAssert(_stackView != nil, @"stackView was nil");

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;

    [_stackView addArrangedSubview:stackView];

    [stackView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [stackView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    _labelsStackView = stackView;
}

- (void)setupTitleLabel
{
    NSAssert(_labelsStackView != nil, @"labelsStackView was nil");

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.font = [WPFontManager systemRegularFontOfSize:16.0];
    label.adjustsFontSizeToFitWidth = NO;

    [_labelsStackView addArrangedSubview:label];

    _titleLabel = label;
}

- (void)setupSubtitleLabel
{
    NSAssert(_labelsStackView != nil, @"labelsStackView was nil");

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    label.font = [WPFontManager systemItalicFontOfSize:12.0];
    label.adjustsFontSizeToFitWidth = NO;

    [_labelsStackView addArrangedSubview:label];

    _subtitleLabel = label;
}

@end
