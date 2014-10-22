#import "WPContentView.h"
#import "ContentActionButton.h"
#import "WPContentAttributionView.h"
#import "WPContentActionView.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

const CGFloat WPContentViewHorizontalInnerPadding = 12.0;
const CGFloat WPContentViewOuterMargin = 8.0;
const CGFloat WPContentViewAttributionVerticalPadding = 8.0;
const CGFloat WPContentViewVerticalPadding = 14.0;
const CGFloat WPContentViewTitleContentPadding = 6.0;
const CGFloat WPContentViewMaxImageHeightPercentage = 0.59;
const CGFloat WPContentViewAuthorAvatarSize = 32.0;
const CGFloat WPContentViewAuthorViewHeight = 32.0;
const CGFloat WPContentViewActionViewHeight = 48.0;
const CGFloat WPContentViewBorderHeight = 1.0;
const CGFloat WPContentViewLineHeightMultiple = 1.03;

@interface WPContentView()<WPContentAttributionViewDelegate>
// Stores a reference to the image height constraints for easy adjustment.
@property (nonatomic, strong) NSLayoutConstraint *featuredImageZeroHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *featuredImagePercentageHeightConstraint;
@property (nonatomic, strong) NSMutableArray *labelsNeedingPreferredMaxLayoutWidth;
@end

@implementation WPContentView

+ (UIFont *)titleFont
{
    return (IS_IPAD ? [UIFont fontWithName:@"Merriweather-Bold" size:24.0f] : [UIFont fontWithName:@"Merriweather-Bold" size:19.0f]);
}

+ (UIFont *)contentFont
{
    return (IS_IPAD ? [WPFontManager openSansRegularFontOfSize:16.0] : [WPFontManager openSansRegularFontOfSize:14.0]);
}

#pragma mark - Lifecycle

- (void)dealloc
{
    self.contentProvider = nil;
    self.delegate = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.labelsNeedingPreferredMaxLayoutWidth = [NSMutableArray array];
        [self constructSubviews];
        [self configureConstraints];
    }
    return self;
}

- (void)layoutSubviews
{
    [self refreshLabelPreferredMaxLayoutWidth];
    [super layoutSubviews];
}

#pragma mark - Public Methods

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (_contentProvider == contentProvider) {
        return;
    }

    _contentProvider = contentProvider;
    [self configureView];
}

- (void)reset
{
    [self setContentProvider:nil];
}

- (void)setFeaturedImage:(UIImage *)image
{
    self.featuredImageView.image = image;
}

- (void)setAvatarImage:(UIImage *)image
{
    [self.attributionView setAvatarImage:image];
}

- (BOOL)privateContent
{
    return NO;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat innerWidth = size.width - (WPContentViewOuterMargin * 2);
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);
    CGFloat height = 0;
    height += self.attributionView.intrinsicContentSize.height;
    height += self.actionView.intrinsicContentSize.height;
    if (!self.featuredImageView.hidden) {
        height += (size.width * WPContentViewMaxImageHeightPercentage);
    }
    height += [self.titleLabel sizeThatFits:innerSize].height;
    height += [self sizeThatFitsContent:innerSize].height;

    height += WPContentViewOuterMargin;
    height += WPContentViewAttributionVerticalPadding;
    height += WPContentViewTitleContentPadding;
    height += (WPContentViewVerticalPadding * 2);

    return CGSizeMake(size.width, ceil(height));
}

- (CGSize)sizeThatFitsContent:(CGSize)size
{
    return [self.contentView sizeThatFits:size];
}

- (CGFloat)horizontalMarginForContent
{
    return WPContentViewOuterMargin;
}

- (void)setAlwaysHidesFeaturedImage:(BOOL)alwaysHides
{
    if (_alwaysHidesFeaturedImage == alwaysHides) {
        return;
    }
    _alwaysHidesFeaturedImage = alwaysHides;
    [self configureFeaturedImageView];
}

#pragma mark - Private Methods

- (void)registerLabelForRefreshingPreferredMaxLayoutWidth:(UILabel *)label
{
    [self.labelsNeedingPreferredMaxLayoutWidth addObject:label];
}

- (void)refreshLabelPreferredMaxLayoutWidth
{
    CGFloat width = CGRectGetWidth(self.bounds) - (WPContentViewOuterMargin * 2);
    for (UILabel *label in self.labelsNeedingPreferredMaxLayoutWidth) {
        [label setPreferredMaxLayoutWidth:width];
    }
}

- (void)configureConstraints
{
    CGFloat contentViewOuterMargin = [self horizontalMarginForContent];
    NSDictionary *views = NSDictionaryOfVariableBindings(_attributionView, _attributionBorderView, _featuredImageView, _titleLabel, _contentView, _actionView);
    NSDictionary *metrics = @{@"outerMargin": @(WPContentViewOuterMargin),
                              @"contentViewOuterMargin": @(contentViewOuterMargin),
                              @"verticalPadding": @(WPContentViewVerticalPadding),
                              @"attributionVerticalPadding": @(WPContentViewAttributionVerticalPadding),
                              @"titleContentPadding": @(WPContentViewTitleContentPadding),
                              @"borderHeight": @(WPContentViewBorderHeight),
                              @"priority":@900
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[_attributionView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[_titleLabel]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(contentViewOuterMargin)-[_contentView]-(contentViewOuterMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[_actionView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_featuredImageView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[_attributionBorderView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(outerMargin@priority)-[_attributionView]-(attributionVerticalPadding@priority)-[_featuredImageView]-(verticalPadding@priority)-[_titleLabel]-(titleContentPadding@priority)-[_contentView]-(verticalPadding@priority)-[_actionView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Positions the border below the attribution view. Featured image should appear above it.
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_attributionView]-(attributionVerticalPadding@priority)-[_attributionBorderView(borderHeight)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
}

- (void)configureFeaturedImageHeightConstraint
{
    if (!self.featuredImagePercentageHeightConstraint) {
        self.featuredImagePercentageHeightConstraint = [NSLayoutConstraint constraintWithItem:self.featuredImageView
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:self.featuredImageView
                                                                                    attribute:NSLayoutAttributeWidth
                                                                                   multiplier:WPContentViewMaxImageHeightPercentage
                                                                                     constant:0];
    }

    if (!self.featuredImageZeroHeightConstraint) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_featuredImageView);
        self.featuredImageZeroHeightConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_featuredImageView(0)]"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:views] firstObject];

    }

    NSLayoutConstraint *constraintToAdd;
    NSLayoutConstraint *constraintToRemove;

    if (self.featuredImageView.hidden) {
        constraintToRemove = self.featuredImagePercentageHeightConstraint;
        constraintToAdd = self.featuredImageZeroHeightConstraint;
    } else {
        // configure percentage height constraint
        constraintToAdd = self.featuredImagePercentageHeightConstraint;
        constraintToRemove = self.featuredImageZeroHeightConstraint;
    }

    // Remove the old constraint if necessary.
    if ([self.constraints indexOfObject:constraintToRemove] != NSNotFound) {
        [self removeConstraint:constraintToRemove];
    }

    // Add the new constraint and update if necessary.
    if ([self.constraints indexOfObject:constraintToAdd] == NSNotFound) {
        [self addConstraint:constraintToAdd];
        [self setNeedsUpdateConstraints];
    }
}

- (void)constructSubviews
{
    self.attributionView = [self viewForAttributionView];
    [self addSubview:self.attributionView];

    self.attributionBorderView = [self viewForBorder];
    [self addSubview:self.attributionBorderView];

    self.featuredImageView = [self imageViewForFeaturedImage];
    [self addSubview:self.featuredImageView];

    self.titleLabel = [self viewForTitle];
    [self addSubview:self.titleLabel];

    self.contentView = [self viewForContent];
    [self addSubview:self.contentView];

    self.actionView = [self viewForActionView];
    [self addSubview:self.actionView];
}

#pragma mark - Subview factories

- (WPContentAttributionView *)viewForAttributionView
{
    WPContentAttributionView *attrView = [[WPContentAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    attrView.delegate = self;
    return attrView;
}

- (UIView *)viewForBorder
{
    UIView *borderView = [[UIView alloc] init];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:240.0/255.0 blue:245.0/255.0 alpha:1.0];
    return borderView;
}

- (UIImageView *)imageViewForFeaturedImage
{
    UIImageView *featuredImageView = [[UIImageView alloc] init];
    featuredImageView.translatesAutoresizingMaskIntoConstraints = NO;
    featuredImageView.backgroundColor = [WPStyleGuide readGrey];
    featuredImageView.contentMode = UIViewContentModeScaleAspectFill;
    featuredImageView.clipsToBounds = YES;
    featuredImageView.hidden = YES;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
    [featuredImageView addGestureRecognizer:tgr];

    return featuredImageView;
}

- (UILabel *)viewForTitle
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textColor = [WPStyleGuide littleEddieGrey];
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.opaque = YES;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.numberOfLines = 4;
    [self registerLabelForRefreshingPreferredMaxLayoutWidth:titleLabel];

    return titleLabel;
}

- (UIView *)viewForContent
{
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    contentLabel.textColor = [WPStyleGuide littleEddieGrey];
    contentLabel.backgroundColor = [UIColor whiteColor];
    contentLabel.opaque = YES;
    contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    contentLabel.numberOfLines = 4;
    [self registerLabelForRefreshingPreferredMaxLayoutWidth:contentLabel];

    return contentLabel;
}

- (WPContentActionView *)viewForActionView
{
    WPContentActionView *actionView = [[WPContentActionView alloc] init];
    actionView.translatesAutoresizingMaskIntoConstraints = NO;
    return actionView;
}

#pragma mark - Configuration

- (void)configureView
{
    [self configureAttributionView];
    [self configureFeaturedImageView];
    [self configureTitleView];
    [self configureContentView];
    [self configureActionView];
    [self configureActionButtons];
    [self setAvatarImage:nil];
    [self setFeaturedImage:nil];

    [self setNeedsUpdateConstraints];
}

- (void)configureAttributionView
{
    self.attributionView.contentProvider = self.contentProvider;
}

- (void)configureFeaturedImageView
{
    if (self.contentProvider) {
        NSURL *featuredImageURL = [self.contentProvider featuredImageURLForDisplay];
        self.featuredImageView.hidden = ([[featuredImageURL absoluteString] length] == 0) || self.alwaysHidesFeaturedImage;
        [self configureFeaturedImageHeightConstraint];
    } else {
        self.featuredImageView.image = nil;
    }
}

- (void)configureTitleView
{
    self.titleLabel.attributedText = [self attributedStringForTitle:[self.contentProvider titleForDisplay]];
    // Reassign line break mode after setting attributed text, else we never see an ellipsis.
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
}

- (void)configureContentView
{
    UILabel *label = (UILabel *)self.contentView;
    label.attributedText = [self attributedStringForContent:[self.contentProvider contentPreviewForDisplay]];
    // Reassign line break mode after setting attributed text, else we never see an ellipsis.
    label.lineBreakMode = NSLineBreakByTruncatingTail;
}

- (void)configureActionView
{
    self.actionView.contentProvider = self.contentProvider;
}

- (void)configureActionButtons
{
    // noop. Subclasses should override.
}

- (UIButton *)createActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage
{
    ContentActionButton *button = [ContentActionButton buttonWithType:UIButtonTypeCustom];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:selectedButtonImage forState:UIControlStateSelected];
    [button.titleLabel setFont:[WPStyleGuide labelFontNormal]];
    [button setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 6.0, 0.0, -6.0);
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 12.0);
    button.drawLabelBubble = YES;

    return button;
}

- (NSArray *)actionButtons
{
    if (!self.actionView) {
        return nil;
    }
    return self.actionView.actionButtons;
}

- (void)setActionButtons:(NSArray *)actionButtons
{
    if (!self.actionView) {
        return;
    }
    self.actionView.actionButtons = actionButtons;
}

- (void)updateActionButtons
{
    // Subclasses should override
}

/**
 Returns an attributed string for the specified `title`, formatted for the title view.

 @param title The string to convert to an attriubted string.
 @return An attributed string formatted to display in the title view.
 */
- (NSAttributedString *)attributedStringForTitle:(NSString *)title
{
    title = [title trim];
    if (title == nil) {
        title = @"";
    }

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:WPContentViewLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [[self class] titleFont]};

    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title
                                                                                    attributes:attributes];
    return titleString;
}

/**
 Returns an attributed string for the specified `string`, formatted for the content view.

 @param title The string to convert to an attriubted string.
 @return An attributed string formatted to display in the title view.
 */
- (NSAttributedString *)attributedStringForContent:(NSString *)string
{
    string = [string trim];
    if (string == nil) {
        string = @"";
    }

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:WPContentViewLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [[self class] contentFont]};
    NSMutableAttributedString *attributedSummary = [[NSMutableAttributedString alloc] initWithString:string
                                                                                          attributes:attributes];
    return attributedSummary;
}

#pragma mark - WPContentView Delegate Methods

/**
 Receives the notification that the user has tapped the featured image, and informs
 the delegate of the interaction.

 @param sender A reference to the featured image.
 */
- (void)featuredImageAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveFeaturedImageAction:)]) {
        [self.delegate contentView:self didReceiveFeaturedImageAction:sender];
    }
}

#pragma mark - Attribution Delegate Methods

/**
 Receives the notification from the attribution view that its button was pressed and informs the
 delegate of the interaction.
 */
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveAttributionLinkAction:)]) {
        [self.delegate contentView:self didReceiveAttributionLinkAction:sender];
    }
}

/**
 Receives the notification from the attribution view that its menu button was pressed and informs the
 delegate of the interaction.
 */
- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionMenuAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveAttributionMenuAction:)]) {
        [self.delegate contentView:self didReceiveAttributionMenuAction:sender];
    }
}

@end
