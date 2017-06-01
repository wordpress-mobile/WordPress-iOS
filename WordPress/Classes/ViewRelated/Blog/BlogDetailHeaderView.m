#import "BlogDetailHeaderView.h"
#import "Blog.h"
#import "UIImageView+Gravatar.h"
#import "WordPress-Swift.h"


const CGFloat BlogDetailHeaderViewBlavatarSize = 40.0;
const CGFloat BlogDetailHeaderViewLabelHorizontalPadding = 10.0;

@interface BlogDetailHeaderView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, strong) UIActivityIndicatorView *blavatarUpdateActivityIndicatorView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end

@implementation BlogDetailHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.preservesSuperviewLayoutMargins = YES;

        [self setupStackView];
        [self setupBlavatarImageView];
        [self setupLabelsStackView];
        [self setupTitleLabel];
        [self setupSubtitleLabel];
    }
    return self;
}

#pragma mark - Public Methods

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    [self refreshIconImage];

    // if the blog name is missing, we want to show the blog displayURL instead
    NSString *blogName = blog.settings.name;
    [self.titleLabel setText:((blogName && !blogName.isEmpty) ? blogName : blog.displayURL)];
    [self.subtitleLabel setText:blog.displayURL];
    [self.labelsStackView setNeedsLayout];
}

- (void)refreshIconImage
{
    if (self.blog.hasIcon) {
        [self.blavatarImageView setImageWithSiteIcon:self.blog.icon placeholderImage:nil];
    } else {
        [self.blavatarImageView setDeafultSiteIconImage];
    }
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

    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              ]];
    _stackView = stackView;
}

- (void)setupBlavatarImageView
{
    NSAssert(_stackView != nil, @"stackView was nil");

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    imageView.layer.borderWidth = 1.0;
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(blavatarImageTapped)];
    singleTap.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:singleTap];

    [_stackView addArrangedSubview:imageView];

    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.widthAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize],
                                              [imageView.heightAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize]
                                              ]];
    _blavatarImageView = imageView;
}

- (UIActivityIndicatorView *)blavatarUpdateActivityIndicatorView {
    if (!_blavatarUpdateActivityIndicatorView) {
        _blavatarUpdateActivityIndicatorView = [[UIActivityIndicatorView alloc]init];
        _blavatarUpdateActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.blavatarImageView addSubview:_blavatarUpdateActivityIndicatorView];
        [self.blavatarImageView pinSubviewAtCenter:_blavatarUpdateActivityIndicatorView];
    }
    return _blavatarUpdateActivityIndicatorView;
}

-(void)blavatarImageTapped
{
    [self.delegate siteIconTapped];
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
    label.adjustsFontSizeToFitWidth = NO;
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleCallout];

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
    label.adjustsFontSizeToFitWidth = NO;
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleCaption1 symbolicTraits:UIFontDescriptorTraitItalic];

    [_labelsStackView addArrangedSubview:label];

    _subtitleLabel = label;
}

- (void)setUpdatingIcon:(BOOL)updatingIcon
{
    _updatingIcon = updatingIcon;
    if (updatingIcon) {
        [self.blavatarUpdateActivityIndicatorView startAnimating];
    } else {
        [self.blavatarUpdateActivityIndicatorView stopAnimating];
    }
}

@end
