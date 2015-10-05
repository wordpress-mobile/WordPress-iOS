#import "WPContentAttributionView.h"

const CGFloat WPContentAttributionViewAvatarSize = 32.0;
const CGFloat WPContentAttributionLabelHeight = 18.0;
const CGFloat WPContentAttributionMenuSize = 30.0;

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
        _avatarImageView = [self imageViewForAvatar];
        [self addSubview:_avatarImageView];

        _attributionNameLabel = [self labelForAttributionName];
        [self addSubview:self.attributionNameLabel];

        _attributionLinkButton = [self buttonForAttributionLink];
        [self addSubview:self.attributionLinkButton];

        _attributionMenuButton = [self buttonForAttributionMenu];
        [self addSubview:self.attributionMenuButton];


        [self configureConstraints];
    }
    return self;
}

#pragma mark - Public Methods

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(WPContentAttributionViewAvatarSize, WPContentAttributionViewAvatarSize);
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (_contentProvider == contentProvider) {
        return;
    }

    _contentProvider = contentProvider;
    [self configureView];
}

- (void)setAvatarImage:(UIImage *)image
{
    self.avatarImageView.image = image;
}

- (void)hideAttributionButton:(BOOL)hide
{
    self.attributionLinkButton.hidden = hide;
}

- (void)selectAttributionButton:(BOOL)select
{
    [self.attributionLinkButton setSelected:select];
}

- (void)hideAttributionMenu:(BOOL)hide
{
    self.attributionMenuButton.hidden = hide;
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _attributionNameLabel, _attributionLinkButton, _attributionMenuButton);
    NSDictionary *metrics = @{@"avatarSize": @(WPContentAttributionViewAvatarSize),
                              @"labelHeight":@(WPContentAttributionLabelHeight),
                              @"menuSize":@(WPContentAttributionMenuSize)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[_attributionNameLabel][_attributionMenuButton(menuSize)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-40-[_attributionLinkButton(>=100)]-(>=10)-[_attributionMenuButton]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-2)-[_attributionNameLabel(labelHeight)][_attributionLinkButton(labelHeight)]"
                                                                 options:NSLayoutFormatAlignAllLeft
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_attributionMenuButton]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [super setNeedsUpdateConstraints];
}

- (void)configureView
{
    self.attributionNameLabel.text = [self.contentProvider authorForDisplay];
    [self configureAttributionButton];

}

- (void)configureAttributionButton
{
    [self.attributionLinkButton setTitle:[self.contentProvider blogNameForDisplay] forState:UIControlStateNormal];
    [self.attributionLinkButton setTitle:[self.contentProvider blogNameForDisplay] forState:UIControlStateHighlighted];
}

#pragma mark - Subview factories

- (UILabel *)labelForAttributionName
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

- (CircularImageView *)imageViewForAvatar
{
    CGRect avatarFrame = CGRectMake(0.0f, 0.0f, WPContentAttributionViewAvatarSize, WPContentAttributionViewAvatarSize);
    CircularImageView *imageView = [[CircularImageView alloc] initWithFrame:avatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.userInteractionEnabled = YES;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapped:)];
    tgr.cancelsTouchesInView = YES;
    [imageView addGestureRecognizer:tgr];

    return imageView;
}

- (UIButton *)buttonForAttributionLink
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide subtitleFont];
    [button setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];

    [button addTarget:self action:@selector(attributionButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIButton *)buttonForAttributionMenu
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImage:[UIImage imageNamed:@"icon-menu-ellipsis"] forState:UIControlStateNormal];
    button.hidden = YES; // Hidden by default.

    [button addTarget:self action:@selector(attributionMenuAction:) forControlEvents:UIControlEventTouchUpInside];

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

- (void)handleImageTapped:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(attributionViewDidReceiveAvatarAction:)]) {
        [self.delegate attributionViewDidReceiveAvatarAction:self];
    }
}

- (void)attributionButtonAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(attributionView:didReceiveAttributionLinkAction:)]) {
        [self.delegate attributionView:self didReceiveAttributionLinkAction:sender];
    }
}

- (void)attributionMenuAction:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(attributionView:didReceiveAttributionMenuAction:)]) {
        [self.delegate attributionView:self didReceiveAttributionMenuAction:sender];
    }
}

@end
