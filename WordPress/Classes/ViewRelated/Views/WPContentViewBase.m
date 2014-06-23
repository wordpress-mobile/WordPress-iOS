#import "WPContentViewBase.h"

#import "ContentActionButton.h"
#import "WPContentAttributionView.h"
#import "WPContentActionView.h"

// TODO: Delete any of these that end up not being used.
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

const CGFloat WPContentViewFollowButtonWidth = 100.0f;
const CGFloat WPContentViewTitlePaddingBottom = 3.0f;
const CGFloat WPContentViewSmallButtonLeftPadding = 2; // Follow, tag


@interface WPContentViewBase()
@property (nonatomic, strong) NSLayoutConstraint *featuredImageHeightConstraint;
@end

@implementation WPContentViewBase

+ (UIFont *)titleFont {
    return (IS_IPAD ? [UIFont fontWithName:@"Merriweather-Bold" size:24.0f] : [UIFont fontWithName:@"Merriweather-Bold" size:19.0f]);
}

+ (UIFont *)contentFont {
    return (IS_IPAD ? [UIFont fontWithName:@"OpenSans" size:16.0f] : [UIFont fontWithName:@"OpenSans" size:14.0f]);
}

+ (NSAttributedString *)attributedStringForTitle:(NSString *)title {
    title = [title trim];
    if (title == nil) {
        title = @"";
    }

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:WPContentViewLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self titleFont]};

    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title
                                                                                    attributes:attributes];

//    if([title length] > 0)
//    {
//        CGFloat currentHeightOfTitle = [titleString
//                                        boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
//                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                        context:nil].size.height;
//
//
//        CGFloat heightOfSingleLine = [[titleString attributedSubstringFromRange:NSMakeRange(0,1)]
//                                      boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
//                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                      context:nil].size.height;
//
//        NSInteger numberOfLines = currentHeightOfTitle / heightOfSingleLine;
//
//        if(numberOfLines > maxLines)
//        {
//            NSInteger newLength = [ReaderPostView calculateTitleLengthWithSingleLineHeight:heightOfSingleLine
//                                                                         currentLineHeight:currentHeightOfTitle
//                                                                              currentTitle:titleString];
//
//
//            titleString = [[NSMutableAttributedString alloc]initWithString:[postTitle stringByEllipsizingWithMaxLength:newLength preserveWords:YES]
//                                                                attributes:attributes];
//
//        }
//    }

    return titleString;
}

+ (NSAttributedString *)attributedStringForContent:(NSString *)string {
    string = [string trim];
    if (string == nil) {
        string = @"";
    }

//    NSInteger newline = [string rangeOfString:@"\n"].location;
//
//    if (newline != NSNotFound) {
//        string = [string substringToIndex:newline];
//    }

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineHeightMultiple:WPContentViewLineHeightMultiple];
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : style,
                                 NSFontAttributeName : [self contentFont]};
    NSMutableAttributedString *attributedSummary = [[NSMutableAttributedString alloc] initWithString:string
                                                                                          attributes:attributes];
    return attributedSummary;
}


#pragma mark - Lifecycle

- (void)dealloc
{
    self.contentProvider = nil;
    self.delegate = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self constructSubviews];
        [self configureConstraints];
    }
    return self;
}


#pragma mark - Public Methods

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (_contentProvider == contentProvider)
        return;

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


#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_attributionView, _attributionBorderView, _featuredImageView, _titleLabel, _contentView, _actionView);
    NSDictionary *metrics = @{@"outerMargin": @(WPContentViewOuterMargin),
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

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(outerMargin)-[_contentView]-(outerMargin)-|"
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
    if (self.featuredImageHeightConstraint) {
        [self removeConstraint:self.featuredImageHeightConstraint];
        self.featuredImageHeightConstraint = nil;
    }

    NSLayoutConstraint *constraint;
    if ([self.contentProvider featuredImageURLForDisplay]) {
        constraint = [NSLayoutConstraint constraintWithItem:self.featuredImageView
                                                  attribute:NSLayoutAttributeHeight
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.featuredImageView
                                                  attribute:NSLayoutAttributeWidth
                                                 multiplier:WPContentViewMaxImageHeightPercentage
                                                   constant:0];
        constraint.priority = 900;
    } else {
        NSDictionary *views = NSDictionaryOfVariableBindings(_featuredImageView);
        constraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_featuredImageView(0)]"
                                                              options:0
                                                              metrics:nil
                                                                views:views] firstObject];
    }
    self.featuredImageHeightConstraint = constraint;
    [self addConstraint:self.featuredImageHeightConstraint];

    [self setNeedsUpdateConstraints];
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
    WPContentAttributionView *attrView = [[WPContentAttributionView alloc] initWithFrame:CGRectZero];
    return attrView;
}

- (UIView *)viewForBorder
{
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectZero];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];
    return borderView;
}

- (UIImageView *)imageViewForFeaturedImage
{
    UIImageView *featuredImageView = [[UIImageView alloc] init];
    featuredImageView.translatesAutoresizingMaskIntoConstraints = NO;
    featuredImageView.backgroundColor = [WPStyleGuide readGrey];
    featuredImageView.contentMode = UIViewContentModeScaleAspectFill;
    featuredImageView.clipsToBounds = YES;

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(featuredImageAction:)];
    featuredImageView.userInteractionEnabled = YES;
    [featuredImageView addGestureRecognizer:tgr];

    return featuredImageView;
}

- (UILabel *)viewForTitle
{
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.textColor = [WPStyleGuide littleEddieGrey];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 0;

    return titleLabel;
}

- (UIView *)viewForContent
{
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    contentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.textColor = [WPStyleGuide littleEddieGrey];
    contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    contentLabel.numberOfLines = 0;

    return contentLabel;
}

- (WPContentActionView *)viewForActionView
{
    WPContentActionView *actionView = [[WPContentActionView alloc]initWithFrame:CGRectZero];
    return actionView;
}


#pragma mark - Configuration

/**

 */
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

/**

 */
- (void)configureAttributionView
{
    self.attributionView.contentProvider = self.contentProvider;
}

/**

 */
- (void)configureFeaturedImageView
{
    [self configureFeaturedImageHeightConstraint];
    NSURL *featuredImageURL = [self.contentProvider featuredImageURLForDisplay];
    self.featuredImageView.hidden = (featuredImageURL == nil);
}

/**
 
 */
- (void)configureTitleView
{
    self.titleLabel.attributedText = [[self class] attributedStringForTitle:[self.contentProvider titleForDisplay]];
}

/**
 
 */
- (void)configureContentView
{
    UILabel *label = (UILabel *)self.contentView;
    label.attributedText = [[self class] attributedStringForContent:[self.contentProvider contentPreviewForDisplay]];
}

/**

 */
- (void)configureActionView
{
    self.actionView.contentProvider = self.contentProvider;
}

/**
 
 */
- (void)configureActionButtons
{
    AssertSubclassMethod();
}

/**

 */
- (UIButton *)addActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage
{
    ContentActionButton *button = [ContentActionButton buttonWithType:UIButtonTypeCustom];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:selectedButtonImage forState:UIControlStateSelected];
    [button.titleLabel setFont:[WPStyleGuide labelFontNormal]];
    [button setTitleColor:[WPStyleGuide newKidOnTheBlockBlue] forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 6.0, 0.0, -6.0);
    button.drawLabelBubble = YES;

    [self.actionView addActionButton:button];

    return button;
}

/**

 */
- (void)removeAllActionButtons
{
    [self.actionView removeAllActionButtons];
}

/**

 */
- (void)updateActionButtons
{
    AssertSubclassMethod();
}


#pragma mark - Actions

/**

 */
- (void)featuredImageAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveFeaturedImageAction:)]) {
        [self.delegate contentView:self didReceiveFeaturedImageAction:sender];
    }
}

/**

 */
- (void)authorLinkAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveAuthorLinkAction:)]) {
        [self.delegate contentView:self didReceiveAuthorLinkAction:sender];
    }
}


@end
