#import "BlogDetailHeaderView.h"
#import "Blog.h"
#import "WordPress-Swift.h"


const CGFloat BlogDetailHeaderViewBlavatarSize = 40.0;
const CGFloat BlogDetailHeaderViewLabelHorizontalPadding = 10.0;

@interface BlogDetailHeaderView () <UIDropInteractionDelegate>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIActivityIndicatorView *blavatarUpdateActivityIndicatorView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UIView *blavatarDropTarget;

@end

@implementation BlogDetailHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self performSetup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self performSetup];
    }
    return self;
}

- (void)performSetup
{
    self.preservesSuperviewLayoutMargins = YES;
    [self setupStackView];
    [self setupBlavatarImageView];
    [self setupBlavatarDropTarget];
    [self setupLabelsStackView];
    [self setupTitleLabel];
    [self setupSubtitleLabel];
}

#pragma mark - Public Methods

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
    [self refreshIconImage];

    // if the blog name is missing, we want to show the blog displayURL instead
    NSString *blogName = blog.settings.name;
    NSString *title = (blogName && !blogName.isEmpty) ? blogName : blog.displayURL;
    [self setTitleText:title];
    [self setSubtitleText:blog.displayURL];
    [self.labelsStackView setNeedsLayout];
    
    if (@available(iOS 11.0, *)) {
        if ([self.delegate siteIconShouldAllowDroppedImages]) {
            UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
            [self.blavatarDropTarget addInteraction:dropInteraction];
        }
    }
}

- (void)setTitleText:(NSString *)title
{
    [self.titleLabel setText:title];
    [self.labelsStackView setNeedsLayout];
}

- (void)setSubtitleText:(NSString *)subtitle
{
    [self.subtitleLabel setText:subtitle];
    [self.labelsStackView setNeedsLayout];
}

- (void)loadImageAtPath:(NSString *)imagePath
{
    [self.blavatarImageView downloadSiteIconAt:imagePath];
}

- (void)refreshIconImage
{
    if (self.blog.hasIcon) {
        [self.blavatarImageView downloadSiteIconFor:self.blog placeholderImage:nil];
    } else {
        self.blavatarImageView.image = [UIImage siteIconPlaceholderImage];
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

    [_stackView addArrangedSubview:imageView];

    NSLayoutConstraint *heightConstraint = [imageView.heightAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize];
    heightConstraint.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.widthAnchor constraintEqualToConstant:BlogDetailHeaderViewBlavatarSize],
                                              heightConstraint
                                              ]];

    _blavatarImageView = imageView;
}

- (void)setupBlavatarDropTarget
{
    self.blavatarDropTarget = [UIView new];
    [self.blavatarDropTarget setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.blavatarDropTarget.backgroundColor = [UIColor clearColor];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(blavatarImageTapped)];
    singleTap.numberOfTapsRequired = 1;
    [self.blavatarDropTarget addGestureRecognizer:singleTap];

    [self addSubview:self.blavatarDropTarget];
    [self.blavatarDropTarget pinSubviewToAllEdgeMargins:self.blavatarImageView];
}

- (UIActivityIndicatorView *)blavatarUpdateActivityIndicatorView {
    if (!_blavatarUpdateActivityIndicatorView) {
        _blavatarUpdateActivityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
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

#pragma mark - Drop Interaction Handler
- (void)dropInteraction:(UIDropInteraction *)interaction
        sessionDidEnter:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.blavatarImageView depressSpringAnimation:nil];
}

- (BOOL)dropInteraction:(UIDropInteraction *)interaction
       canHandleSession:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    BOOL isAnImage = [session canLoadObjectsOfClass:[UIImage self]];
    BOOL isSingleImage = [session.items count] == 1;
    return (isAnImage && isSingleImage);
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction
                   sessionDidUpdate:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    CGPoint dropLocation = [session locationInView:self.blavatarDropTarget];

    UIDropOperation dropOperation = UIDropOperationCancel;
    
    if (CGRectContainsPoint(self.blavatarDropTarget.bounds, dropLocation)) {
        dropOperation = UIDropOperationCopy;
    }

    UIDropProposal *dropProposal = [[UIDropProposal alloc] initWithDropOperation:dropOperation];
    
    return  dropProposal;
}

- (void)dropInteraction:(UIDropInteraction *)interaction
            performDrop:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self setUpdatingIcon:YES];
    [session loadObjectsOfClass:[UIImage self] completion:^(NSArray *images) {
        UIImage *image = [images firstObject];
        [self.delegate siteIconReceivedDroppedImage:image];
    }];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
           concludeDrop:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.blavatarImageView normalizeSpringAnimation:nil];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
         sessionDidExit:(id<UIDropSession>)session  API_AVAILABLE(ios(11.0))
{
    [self.blavatarImageView normalizeSpringAnimation:nil];
}

- (void)dropInteraction:(UIDropInteraction *)interaction
         sessionDidEnd:(id<UIDropSession>)session API_AVAILABLE(ios(11.0))
{
    [self.blavatarImageView normalizeSpringAnimation:nil];
}

@end
