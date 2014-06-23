#import "WPContentAttributionView.h"

@interface WPContentAttributionView()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UIButton *authorSiteButton;
@property (nonatomic, strong) UIView *borderView;

@end

@implementation WPContentAttributionView

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    self.delegate = nil;
    self.contentProvider = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        self.avatarImageView = [self imageViewForAvatar];
        [self addSubview:self.avatarImageView];

        self.authorNameLabel = [self labelForAuthorName];
        [self addSubview:self.authorNameLabel];

        self.authorSiteButton = [self buttonForAuthorSite];
        [self addSubview:self.authorSiteButton];

        [self configureConstraints];
    }
    return self;
}

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _authorNameLabel, _authorSiteButton);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_avatarImageView(32.0)]"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_avatarImageView(32.0)]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[_authorNameLabel]|"
                                                                 options:NSLayoutFormatAlignAllTop
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[_authorSiteButton]|"
                                                                 options:NSLayoutFormatAlignAllBottom
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[_authorNameLabel(18.0)][_authorSiteButton(18.0)]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:nil
                                                                   views:views]];
    [super setNeedsUpdateConstraints];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(200.0, 32.0);
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (_contentProvider == contentProvider)
        return;

    _contentProvider = contentProvider;
    [self configureView];
}

- (void)setAvatarImage:(UIImage *)image
{
    self.avatarImageView.image = image;
}


#pragma mark - Private Methods

- (void)configureView
{
    self.authorNameLabel.text = [self.contentProvider authorForDisplay];
    [self.authorSiteButton setTitle:[self.contentProvider blogNameForDisplay] forState:UIControlStateNormal];
    [self.authorSiteButton setTitle:[self.contentProvider blogNameForDisplay] forState:UIControlStateHighlighted];
}


#pragma mark - Subview factories

- (UILabel *)labelForAuthorName
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.textColor = [UIColor colorWithHexString:@"333"];
    label.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    label.adjustsFontSizeToFitWidth = NO;

    return label;
}

- (UIImageView *)imageViewForAvatar
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

- (UIButton *)buttonForAuthorSite
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
    [button setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];

    [button addTarget:self action:@selector(authorLinkAction:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIView *)viewForBorderView
{
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectZero];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];
    return borderView;
}


#pragma mark - Actions

- (void)authorButtonAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(attributionView:didReceiveAuthorLinkAction:)]) {
        [self.delegate attributionView:self didReceiveAuthorLinkAction:sender];
    }
}

@end
