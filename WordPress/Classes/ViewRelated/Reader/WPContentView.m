#import "WPContentView.h"
#import "ContentActionButton.h"
#import "WPContentAttributionView.h"
#import "WPContentActionView.h"
#import "OriginalAttributionView.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

const CGFloat WPContentViewHorizontalInnerPadding = 12.0;
const CGFloat WPContentViewOuterMargin = 8.0;
const CGFloat WPContentViewAttributionVerticalPadding = 16.0;
const CGFloat WPContentViewVerticalPadding = 14.0;
const CGFloat WPContentViewTitleContentPadding = 6.0;
const CGFloat WPContentViewMaxImageHeightPercentage = 0.59;
const CGFloat WPContentViewAuthorAvatarSize = 32.0;
const CGFloat WPContentViewAuthorViewHeight = 32.0;
const CGFloat WPContentViewActionViewHeight = 48.0;
const CGFloat WPContentViewBorderHeight = 1.0;

@interface WPContentView()<WPContentAttributionViewDelegate>
// Stores a reference to the image height constraints for easy adjustment.
@property (nonatomic, strong) NSLayoutConstraint *featuredImageZeroHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *featuredImagePercentageHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *discoverAttriubtionZeroHeightConstraint;
@property (nonatomic, strong) NSMutableArray *labelsNeedingPreferredMaxLayoutWidth;
@end

@implementation WPContentView

#pragma mark - Lifecycle

- (void)dealloc
{
    _contentProvider = nil;
    _delegate = nil;
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

- (void)setContentProvider:(id<ReaderPostContentProvider>)contentProvider
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
    CGFloat innerWidth = size.width - (WPContentViewOuterMargin * 2.0);
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);
    CGFloat height = 0;
    height += self.attributionView.intrinsicContentSize.height;
    height += self.actionView.intrinsicContentSize.height;
    if (!self.featuredImageView.hidden) {
        height += (size.width * WPContentViewMaxImageHeightPercentage);
    }
    height += [self.titleLabel sizeThatFits:innerSize].height;
    height += [self sizeThatFitsContent:innerSize].height;

    if ([self.contentProvider sourceAttributionStyle] != SourceAttributionStyleNone) {
        height += [self.discoverPostAttributionView sizeThatFits:innerSize].height;
        height += WPContentViewAttributionVerticalPadding;
    }
    height += WPContentViewOuterMargin;
    height += WPContentViewAttributionVerticalPadding;
    height += WPContentViewTitleContentPadding;
    height += (WPContentViewVerticalPadding * 2.0);

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
    UIView *attributionView = self.attributionView;
    UIView *attributionBorderView = self.attributionBorderView;
    UIView *featuredImageView = self.featuredImageView;
    UIView *titleLabel = self.titleLabel;
    UIView *contentView = self.contentView;
    UIView *discoverAttributionView = self.discoverPostAttributionView;
    UIView *discoverAttributionSpacer = self.discoverAttributionSpacerView;
    UIView *actionView = self.actionView;

    CGFloat contentViewOuterMargin = [self horizontalMarginForContent];
    NSDictionary *views = NSDictionaryOfVariableBindings(attributionView,
                                                         attributionBorderView,
                                                         featuredImageView,
                                                         titleLabel,
                                                         contentView,
                                                         discoverAttributionView,
                                                         discoverAttributionSpacer,
                                                         actionView);

    NSDictionary *metrics = @{@"outerMargin": @(WPContentViewOuterMargin),
                              @"contentViewOuterMargin": @(contentViewOuterMargin),
                              @"verticalPadding": @(WPContentViewVerticalPadding),
                              @"attributionVerticalPadding": @(WPContentViewAttributionVerticalPadding),
                              @"titleContentPadding": @(WPContentViewTitleContentPadding),
                              @"borderHeight": @(WPContentViewBorderHeight),
                              @"priority":@900
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[attributionView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[attributionBorderView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[featuredImageView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[titleLabel]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(contentViewOuterMargin)-[contentView]-(contentViewOuterMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[actionView]-(outerMargin)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin@priority)-[discoverAttributionView]-(outerMargin@priority)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin@priority)-[discoverAttributionSpacer]-(outerMargin@priority)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(outerMargin@priority)-[attributionView]-(attributionVerticalPadding@priority)-[featuredImageView]-(verticalPadding@priority)-[titleLabel]-(titleContentPadding@priority)-[contentView]-(verticalPadding@priority)-[discoverAttributionView][discoverAttributionSpacer][actionView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Positions the border below the attribution view. Featured image should appear above it.
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attributionView]-(attributionVerticalPadding@priority)-[attributionBorderView(borderHeight)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Create a constraint to wrangle height of the original attribution spacer view
    self.discoverAttributionBottomPaddingHeightConstraint = [NSLayoutConstraint constraintWithItem:self.discoverAttributionSpacerView
                                                                                         attribute:NSLayoutAttributeHeight
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:nil
                                                                                         attribute:nil
                                                                                        multiplier:1.0
                                                                                          constant:0];
    [self addConstraint:self.discoverAttributionBottomPaddingHeightConstraint];
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

/**
 Wrangles the constraints that control the height of the original attriubtion view
 and its bottom padding.
 */
- (void)configureConstraintsForDiscoverAttributionView
{
    // Create a constraint to zero out original attribution height when its not needed
    if (!self.discoverAttriubtionZeroHeightConstraint) {
        self.discoverAttriubtionZeroHeightConstraint = [NSLayoutConstraint constraintWithItem:self.discoverPostAttributionView
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:nil
                                                                                   multiplier:1
                                                                                     constant:0];
    }

    // Zeros the height of the original attribution view and its spacer
    if (![self.contentProvider sourceAttributionStyle] != SourceAttributionStyleNone) {
       // Add the height constraint if necessasry
        if ([self.constraints indexOfObject:self.discoverAttriubtionZeroHeightConstraint] == NSNotFound) {
            [self addConstraint:self.discoverAttriubtionZeroHeightConstraint];
        }

        self.discoverAttributionBottomPaddingHeightConstraint.constant = 0;

    } else {
        // Shows the discoverAttributionView
        // Remove the height constraint if necessary
        if ([self.constraints indexOfObject:self.discoverAttriubtionZeroHeightConstraint] != NSNotFound) {
            [self removeConstraint:self.discoverAttriubtionZeroHeightConstraint];
        }

        self.discoverAttributionBottomPaddingHeightConstraint.constant = WPContentViewAttributionVerticalPadding;
    }

    [self setNeedsUpdateConstraints];
}

- (void)constructSubviews
{
    [self buildAttributionView];
    [self buildAttributionBorderView];
    [self buildFeaturedImageview];
    [self buildTitleLabel];
    [self buildContentView];
    [self buildActionView];
    [self buildDiscoverAttributionView];
    [self buildDiscoverAttributionSpacerView];
}

#pragma mark - Subview factories

- (void)buildAttributionView
{
    WPContentAttributionView *attrView = [[WPContentAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    attrView.delegate = self;

    self.attributionView = attrView;
    [self addSubview:self.attributionView];
}

- (void)buildAttributionBorderView
{
    UIView *borderView = [[UIView alloc] init];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:232.0/255.0 green:240.0/255.0 blue:245.0/255.0 alpha:1.0];
    self.attributionBorderView = borderView;
    [self addSubview:self.attributionBorderView];
}

- (void)buildFeaturedImageview
{
    UIImageView *featuredImageView = [[UIImageView alloc] init];
    featuredImageView.translatesAutoresizingMaskIntoConstraints = NO;
    featuredImageView.backgroundColor = [WPStyleGuide readGrey];
    featuredImageView.contentMode = UIViewContentModeScaleAspectFill;
    featuredImageView.clipsToBounds = YES;
    featuredImageView.hidden = YES;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
    [featuredImageView addGestureRecognizer:tgr];

    self.featuredImageView = featuredImageView;
    [self addSubview:self.featuredImageView];
}

- (void)buildTitleLabel
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textColor = [WPStyleGuide littleEddieGrey];
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.opaque = YES;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.numberOfLines = 4;
    [self registerLabelForRefreshingPreferredMaxLayoutWidth:titleLabel];

    self.titleLabel = titleLabel;
    [self addSubview:self.titleLabel];
}

- (void)buildContentView
{
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    contentLabel.textColor = [WPStyleGuide littleEddieGrey];
    contentLabel.backgroundColor = [UIColor whiteColor];
    contentLabel.opaque = YES;
    contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    contentLabel.numberOfLines = 4;
    [self registerLabelForRefreshingPreferredMaxLayoutWidth:contentLabel];

    self.contentView = contentLabel;
    [self addSubview:self.contentView];
}

- (void)buildActionView
{
    WPContentActionView *actionView = [[WPContentActionView alloc] init];
    actionView.translatesAutoresizingMaskIntoConstraints = NO;

    self.actionView = actionView;
    [self addSubview:self.actionView];
}

- (void)buildDiscoverAttributionView
{
    OriginalAttributionView *originalAttributionView = (OriginalAttributionView *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([OriginalAttributionView class]) owner:nil options:nil] firstObject];
    originalAttributionView.translatesAutoresizingMaskIntoConstraints = NO;

    // RichTextView relies on frame width for calculating intrinsic content size.
    // Set the starting width so the initial intrinsic size is correct.
    CGRect frame = originalAttributionView.frame;
    frame.size.width = CGRectGetWidth(self.frame) - (WPContentViewOuterMargin * 2.0);
    originalAttributionView.frame = frame;

    self.discoverPostAttributionView = originalAttributionView;
    [self addSubview:self.discoverPostAttributionView];
}

- (void)buildDiscoverAttributionSpacerView
{
    // A spacer view for providing some bottom padding because constraints are dumb.
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.hidden = YES;

    self.discoverAttributionSpacerView = view;
    [self addSubview:self.discoverAttributionSpacerView];
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
    [self configureDiscoverAttributionView];

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

- (void)configureDiscoverAttributionView
{
    if ([self.contentProvider sourceAttributionStyle] == SourceAttributionStylePost) {
        [self.discoverPostAttributionView setPostAttributionWithGravatar:[self.contentProvider sourceAvatarURLForDisplay]
                                                               forAuthor:[self.contentProvider sourceAuthorNameForDisplay]
                                                                    blog:[self.contentProvider sourceBlogNameForDisplay]];

    } else if ([self.contentProvider sourceAttributionStyle] == SourceAttributionStyleSite) {
        [self.discoverPostAttributionView setSiteAttributionWithBlavatar:[self.contentProvider sourceAvatarURLForDisplay]
                                                                 forBlog:[self.contentProvider sourceBlogNameForDisplay]];
    } else {
        [self.discoverPostAttributionView reset];
    }
    [self configureConstraintsForDiscoverAttributionView];
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

- (NSDictionary *)attributesForAttributedStringForTitle
{
    CGFloat fontSize = [UIDevice isPad] ? 24.0 : 16.0;
    UIFont *font = [WPFontManager merriweatherBoldFontOfSize:fontSize];

    CGFloat lineHeight = [UIDevice isPad] ? 32.0 : 21.0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    [paragraphStyle setMinimumLineHeight:lineHeight];

    return @{NSParagraphStyleAttributeName : paragraphStyle,
             NSFontAttributeName : font};
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

    NSDictionary *attributes = [self attributesForAttributedStringForTitle];

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

    CGFloat fontSize = [UIDevice isPad] ? 16.0 : 14.0;
    UIFont *font = [WPFontManager merriweatherRegularFontOfSize:fontSize];

    CGFloat lineHeight = [UIDevice isPad] ? 24.0 : 21.0;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    [paragraphStyle setMinimumLineHeight:lineHeight];

    NSDictionary *attributes = @{NSParagraphStyleAttributeName : paragraphStyle,
                                 NSFontAttributeName : font};

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

- (void)attributionViewDidReceiveAvatarAction:(WPContentAttributionView *)attributionView
{
    if ([self.delegate respondsToSelector:@selector(contentViewDidReceiveAvatarAction:)]) {
        [self.delegate contentViewDidReceiveAvatarAction:self];
    }
}

@end
