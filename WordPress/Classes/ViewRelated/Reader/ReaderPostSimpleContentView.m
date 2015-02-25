#import "ReaderPostSimpleContentView.h"
#import "WPSimpleContentAttributionView.h"

@implementation ReaderPostSimpleContentView

#pragma mark - Public Methods

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat innerWidth = size.width - (WPContentViewOuterMargin * 2);
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);
    CGFloat height = 0;
    height += self.attributionView.intrinsicContentSize.height;
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

#pragma mark - Private Methods

- (void)configureConstraints
{
    UIView *attributionView = self.attributionView;
    UIView *attributionBorderView = self.attributionBorderView;
    UIView *featuredImageView = self.featuredImageView;
    UIView *titleLabel = self.titleLabel;
    UIView *contentView = self.contentView;

    CGFloat contentViewOuterMargin = [self horizontalMarginForContent];
    NSDictionary *views = NSDictionaryOfVariableBindings(attributionView, attributionBorderView, featuredImageView, titleLabel, contentView);
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

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(outerMargin@priority)-[attributionView]-(attributionVerticalPadding@priority)-[featuredImageView]-(verticalPadding@priority)-[titleLabel]-(titleContentPadding@priority)-[contentView]-(verticalPadding@priority)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Positions the border below the attribution view. Featured image should appear above it.
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[attributionView]-(attributionVerticalPadding@priority)-[attributionBorderView(borderHeight)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
}

- (void)buildAttributionView
{
    WPSimpleContentAttributionView *attrView = [[WPSimpleContentAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    self.attributionView = attrView;
    [self addSubview:self.attributionView];
}

- (void)buildActionView
{
    //noop
}

- (void)configureActionView
{
    // noop
}

@end
