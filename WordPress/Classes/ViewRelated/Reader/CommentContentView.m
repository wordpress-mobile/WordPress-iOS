#import "CommentContentView.h"
#import <DTCoreText/DTCoreText.h>
#import "DTTiledLayerWithoutFade.h"
#import "NSDate+StringFormatting.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

static const CGFloat CommentContentViewAvatarSize = 32.0;
static const CGFloat CommentContentViewContentViewOffsetTop = 36.0;
static const CGFloat CommentContentViewContentViewOffsetBottom = 19.0;
static const CGFloat CommentContentViewContentOffsetLeft = 40.0;

@interface CommentContentView()<DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIButton *authorButton;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) UIButton *replyButton;

@end

@implementation CommentContentView

#pragma mark - Public Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        [self constructSubviews];
        [self configureConstraints];
    }
    return self;
}

- (void)layoutSubviews
{
    // Redraw text if necessary.
    CGFloat contentHeight = CGRectGetHeight(self.textContentView.frame);
    [super layoutSubviews];
    if (contentHeight != CGRectGetHeight(self.textContentView.frame)) {
        [self relayoutTextContentView];
    }
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
    [self.avatarImageView setImage:image];
}

- (void)reset
{
    [self setContentProvider:nil];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:size.width].height;
    height = height + CommentContentViewContentViewOffsetTop + CommentContentViewContentViewOffsetBottom;
    return CGSizeMake(size.width, ceil(height));
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _authorButton, _timeButton, _textContentView, _replyButton);
    NSDictionary *metrics = @{@"avatarSize": @(CommentContentViewAvatarSize),
                              @"offsetTop" : @(CommentContentViewContentViewOffsetTop),
                              @"offsetBottom" : @(CommentContentViewContentViewOffsetBottom),
                              @"offsetLeft" : @(CommentContentViewContentOffsetLeft)
                              };

    // Avatar
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_avatarImageView(avatarSize)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Author and date
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-offsetLeft-[_authorButton]-(>=1)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-offsetLeft-[_timeButton]-(>=1)-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_authorButton(16)]-3-[_timeButton(16)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Content
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_textContentView]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-offsetTop-[_textContentView(>=1)]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_replyButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textContentView][_replyButton(16)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
}

- (void)constructSubviews
{
    self.avatarImageView = [self imageViewForAvatar];
    [self addSubview:self.avatarImageView];

    self.authorButton = [self buttonForAuthorButton];
    [self addSubview:self.authorButton];

    self.timeButton = [self buttonForTimeButton];
    [self addSubview:self.timeButton];

    self.textContentView = [self viewForContent];
    [self addSubview:self.textContentView];

    self.replyButton = [self buttonForReplyButton];
    [self addSubview:self.replyButton];

    [self sendSubviewToBack:self.textContentView];
}


#pragma mark - Subview factories

- (UIImageView *)imageViewForAvatar
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

- (UIButton *)buttonForAuthorButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
// TODO : Create a comment font and add it to WPStyleGuide
    button.titleLabel.font = [WPFontManager openSansBoldFontOfSize:14.0];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    button.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    [button addTarget:self action:@selector(handleAuthorTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setContentEdgeInsets:UIEdgeInsetsMake(-5, 0, 0, 0)];
    return button;
}

- (UIButton *)buttonForTimeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPFontManager openSansRegularFontOfSize:14.0];
    button.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];
    [button setEnabled:NO];

    [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    return button;
}

- (DTAttributedTextContentView *)viewForContent
{
    [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];

    // Needs an initial frame
    DTAttributedTextContentView *textContentView = [[DTAttributedTextContentView alloc] initWithFrame:self.bounds];
    textContentView.translatesAutoresizingMaskIntoConstraints = NO;
    textContentView.delegate = self;
    textContentView.shouldDrawImages = NO;
    textContentView.shouldDrawLinks = NO;
    textContentView.relayoutMask = DTAttributedTextContentViewRelayoutOnWidthChanged | DTAttributedTextContentViewRelayoutOnHeightChanged;
    textContentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    return textContentView;
}

- (UIButton *)buttonForReplyButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPFontManager openSansRegularFontOfSize:14.0];

    NSString *title = NSLocalizedString(@"Reply", @"Title of the reply button.");
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateHighlighted];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];

    [button setImage:[UIImage imageNamed:@"icon-reader-comment-reply"] forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);

    [button addTarget:self action:@selector(handleReplyTapped:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}


#pragma mark - Configuration

- (void)configureView
{
    [self setAvatarImage:nil];
    [self configureAuthorButton];
    [self configureTimeButton];
    [self configureContentView];
}

- (void)configureAuthorButton
{
    [self highlightAuthor:NO];
    [self.authorButton setTitle:[self.contentProvider authorForDisplay] forState:UIControlStateNormal];
    [self.authorButton setTitle:[self.contentProvider authorForDisplay] forState:UIControlStateHighlighted];
    [self.authorButton setTitle:[self.contentProvider authorForDisplay] forState:UIControlStateDisabled];

    if ([self.contentProvider respondsToSelector:@selector(authorURL)] && [self.contentProvider authorURL]) {
        self.authorButton.enabled = ([[[self.contentProvider authorURL] absoluteString] length] > 0);
    }
}

- (void)highlightAuthor:(BOOL)highlight
{
    if (highlight) {
        [self.authorButton setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateNormal];
        [self.authorButton setTitleColor:[WPStyleGuide littleEddieGrey] forState:UIControlStateHighlighted];
        [self.authorButton setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateDisabled];
    } else {
        [self.authorButton setTitleColor:[WPStyleGuide littleEddieGrey] forState:UIControlStateNormal];
        [self.authorButton setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateHighlighted];
        [self.authorButton setTitleColor:[WPStyleGuide littleEddieGrey] forState:UIControlStateDisabled];
    }
}

- (void)configureTimeButton
{
    NSString *title = [[self.contentProvider dateForDisplay] shortString];
    [self.timeButton setTitle:title forState:UIControlStateNormal | UIControlStateDisabled];
}

- (void)configureContentView
{
    self.textContentView.attributedString = [self attributedStringForContent:[self.contentProvider contentForDisplay]];
    [self relayoutTextContentView];
}

- (void)relayoutTextContentView
{
    // need to reset the layouter because otherwise we get the old framesetter or
    self.textContentView.layouter = nil;

    // layout might have changed due to image sizes
    [self.textContentView relayoutText];
    [self invalidateIntrinsicContentSize];
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

    // remove trailing br tags
    NSRange prng = [string rangeOfString:@"/p>" options:NSBackwardsSearch];
    if (prng.location != NSNotFound) {
        string = [string substringToIndex:prng.location + 3];
    }

    NSString *defaultStyles = @"blockquote {width: 100%; display: block; font-style: italic;}";
    DTCSSStylesheet *cssStylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:defaultStyles];
    NSDictionary *options = @{
             DTDefaultFontFamily:@"Open Sans",
             DTDefaultLineHeightMultiplier:@1.52,
             DTDefaultFontSize:@14.0,
             DTDefaultTextColor:[WPStyleGuide littleEddieGrey],
             DTDefaultLinkColor:[WPStyleGuide baseLighterBlue],
             DTDefaultLinkHighlightColor:[WPStyleGuide midnightBlue],
             DTDefaultLinkDecoration:@NO,
             DTDefaultStyleSheet:cssStylesheet
             };

    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                              options:options
                                                                   documentAttributes:nil];
    return attributedString;
}


#pragma mark - Actions

- (void)handleAuthorTapped:(id)sender
{
    NSURL *url = [self.contentProvider authorURL];
    if ([self.delegate respondsToSelector:@selector(handleLinkTapped:)]) {
        [self.delegate handleLinkTapped:url];
    }
}

- (void)handleLinkTapped:(id)sender
{
    NSURL *url = ((DTLinkButton *)sender).URL;
    if ([self.delegate respondsToSelector:@selector(handleLinkTapped:)]) {
        [self.delegate handleLinkTapped:url];
    }
}

- (void)handleReplyTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(handleReplyTapped:)]) {
        [self.delegate handleReplyTapped:self.contentProvider];
    }
}


#pragma mark - DTAttributedTextContentView Delegate Methods

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame
{
    if (CGRectGetWidth(frame) == 0 || CGRectGetHeight(frame) == 0) {
        return nil;
    }

    NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];

    NSURL *URL = [attributes objectForKey:DTLinkAttribute];

    // get image with normal link text
    UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];

    if (!URL || !normalImage) {
        return nil;
    }

    // get image for highlighted link text
    UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
    if (!highlightImage) {
        highlightImage = normalImage;
    }

    DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
    button.clipsToBounds = YES;
    button.URL = URL;
    button.minimumHitSize = CGSizeMake(25.0, 25.0); // adjusts it's bounds so that button is always large enough
    button.GUID = [attributes objectForKey:DTGUIDAttribute];
    [button setImage:normalImage forState:UIControlStateNormal];
    [button setImage:highlightImage forState:UIControlStateHighlighted];
    // use normal push action for opening URL
    [button addTarget:self action:@selector(handleLinkTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

@end
