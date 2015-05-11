#import "CommentContentView.h"
#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"

static const CGFloat CommentContentViewAvatarSize = 32.0;
static const CGFloat CommentContentViewContentViewOffsetTop = 36.0;
static const CGFloat CommentContentViewContentOffsetLeft = 40.0;
static const CGFloat CommentContentViewMetaHeight = 20.0;
static const CGFloat CommentContentViewButtonHeight = 16.0;
static const CGFloat CommentContentViewMetaStandardSpacing = 8.0;
static const CGFloat CommentContentViewMetaReplyButtonRightMargin = 20.0;
static const CGFloat CommentContentViewButtonSpacingTop = 2.0;
static const UIEdgeInsets AuthorButtonEdgeInsets = {-5.0f, 0.0f, 0.0f, 0.0f};
static const UIEdgeInsets ReplyAndLikeButtonEdgeInsets = {0.0f, 4.0f, 0.0f, -4.0f};

@interface CommentContentView()<WPRichTextViewDelegate>

@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UIButton *authorButton;
@property (nonatomic, strong) UIButton *timeButton;
@property (nonatomic, strong) WPRichTextView *textContentView;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *numberOfLikesLabel;
@property (nonatomic, strong) UIView *commentMeta;
@property (nonatomic, strong) NSLayoutConstraint *commentMetaHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *likeButtonLeftMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *numberOfLikesLabelLeftMarginConstraint;

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

- (void)setContentProvider:(id<WPCommentContentViewProvider>)contentProvider
{
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
    CGFloat height = [self.textContentView sizeThatFits:size].height;
    height += CommentContentViewContentViewOffsetTop;
    height += CommentContentViewButtonSpacingTop;
    height += self.commentMetaHeightConstraint.constant;

    return CGSizeMake(size.width, ceil(height));
}

- (void)refreshMediaLayout
{
    [self.textContentView refreshMediaLayout];
}

- (void)preventPendingMediaLayout:(BOOL)prevent
{
    [self.textContentView preventPendingMediaLayout:prevent];
}


#pragma mark - Private Methods

- (void)configureConstraints
{
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _authorButton, _timeButton, _textContentView, _commentMeta, _replyButton, _likeButton, _numberOfLikesLabel);
    NSDictionary *metrics = @{@"avatarSize": @(CommentContentViewAvatarSize),
                              @"offsetTop" : @(CommentContentViewContentViewOffsetTop),
                              @"offsetLeft" : @(CommentContentViewContentOffsetLeft),
                              @"buttonMarginTop" : @(CommentContentViewButtonSpacingTop),
                              @"buttonHeight" : @(CommentContentViewButtonHeight)
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
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-offsetLeft-[_authorButton]-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-offsetLeft-[_timeButton]-|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_authorButton(buttonHeight)]-3-[_timeButton(buttonHeight)]"
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

    // Meta
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_commentMeta]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textContentView]-(buttonMarginTop@200)-[_commentMeta]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    // Meta Content
    [self.commentMeta addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_replyButton]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];

    [self.commentMeta addConstraint:[NSLayoutConstraint constraintWithItem:self.replyButton
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.commentMeta
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0.0]];


    self.likeButtonLeftMarginConstraint = [NSLayoutConstraint constraintWithItem:self.likeButton
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.commentMeta
                                                                       attribute:NSLayoutAttributeLeftMargin
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.commentMeta addConstraint:self.likeButtonLeftMarginConstraint];
    [self.commentMeta addConstraint:[NSLayoutConstraint constraintWithItem:self.likeButton
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.commentMeta
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0.0]];

    self.numberOfLikesLabelLeftMarginConstraint = [NSLayoutConstraint constraintWithItem:self.numberOfLikesLabel
                                                                               attribute:NSLayoutAttributeLeading
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.commentMeta
                                                                               attribute:NSLayoutAttributeLeftMargin
                                                                              multiplier:1.0
                                                                                constant:0];
    [self.commentMeta addConstraint:self.numberOfLikesLabelLeftMarginConstraint];
    [self.commentMeta addConstraint:[NSLayoutConstraint constraintWithItem:self.numberOfLikesLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.commentMeta
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0.0]];

    self.commentMetaHeightConstraint = [NSLayoutConstraint constraintWithItem:self.commentMeta
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:nil
                                                                   multiplier:1.0
                                                                     constant:CommentContentViewMetaHeight];
    [self addConstraint:self.commentMetaHeightConstraint];
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

    self.commentMeta = [self viewForCommentMeta];
    [self addSubview:self.commentMeta];

    self.replyButton = [self buttonForReplyButton];
    [self.commentMeta addSubview:self.replyButton];

    self.likeButton = [self buttonForLikeButton];
    [self.commentMeta addSubview:self.likeButton];

    self.numberOfLikesLabel = [self labelForNumberOfLikes];
    [self.commentMeta addSubview:self.numberOfLikesLabel];

    [self sendSubviewToBack:self.textContentView];
}


#pragma mark - Subview factories

- (CircularImageView *)imageViewForAvatar
{
    CGRect avatarFrame = CGRectMake(0.0f, 0.0f, CommentContentViewAvatarSize, CommentContentViewAvatarSize);
    CircularImageView *imageView = [[CircularImageView alloc] initWithFrame:avatarFrame];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    return imageView;
}

- (UIButton *)buttonForAuthorButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide commentTitleFont];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    button.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    [button addTarget:self action:@selector(handleAuthorTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.contentEdgeInsets = AuthorButtonEdgeInsets;

    return button;
}

- (UIButton *)buttonForTimeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide commentBodyFont];

    button.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];
    [button setEnabled:NO];

    [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    return button;
}

- (WPRichTextView *)viewForContent
{
    // Needs an initial frame
    WPRichTextView *textContentView = [[WPRichTextView alloc] initWithFrame:self.bounds];
    textContentView.translatesAutoresizingMaskIntoConstraints = NO;
    textContentView.delegate = self;
    textContentView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    textContentView.textOptions = [WPStyleGuide commentDTCoreTextOptions];

    return textContentView;
}

- (UIView *)viewForCommentMeta
{
    // The initial frame width is arbitrary. Constraints will size as appropriate.
    // The height is the same as the constraint for context.
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, CommentContentViewMetaHeight)];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    view.clipsToBounds = YES;
    return view;
}

- (UIButton *)buttonForReplyButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide commentBodyFont];

    NSString *title = NSLocalizedString(@"Reply", @"Title of the reply button.");
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateHighlighted];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];

    [button setImage:[UIImage imageNamed:@"icon-reader-comment-reply"] forState:UIControlStateNormal];
    button.titleEdgeInsets = ReplyAndLikeButtonEdgeInsets;

    [button addTarget:self action:@selector(handleReplyTapped:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UIButton *)buttonForLikeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleLabel.font = [WPStyleGuide commentBodyFont];

    NSString *title = NSLocalizedString(@"Like", @"Title of the like button.");
    NSString *selectedTitle = NSLocalizedString(@"Liked", @"Title of the like button seleced version.");
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:selectedTitle forState:UIControlStateSelected];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateHighlighted];
    [button setTitleColor:[WPStyleGuide jazzyOrange] forState:UIControlStateSelected];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateDisabled];

    [button setImage:[UIImage imageNamed:@"icon-reader-comment-like"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"icon-reader-comment-liked"] forState:UIControlStateSelected];
    [button setImage:[UIImage imageNamed:@"icon-reader-comment-liked"] forState:UIControlStateHighlighted];
    button.titleEdgeInsets = ReplyAndLikeButtonEdgeInsets;

    [button addTarget:self action:@selector(handleLikeTapped:) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (UILabel *)labelForNumberOfLikes
{
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [WPStyleGuide commentBodyFont];
    label.textColor = [WPStyleGuide allTAllShadeGrey];

    return label;
}


#pragma mark - Configuration

- (void)configureView
{
    [self setAvatarImage:nil];
    [self configureAuthorButton];
    [self configureTimeButton];
    [self configureContentView];
    [self configureLikeButton];
    [self configureNumberOfLikes];
    [self configureMetaView];
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

    [self highlightAuthor:[self.contentProvider authorIsPostAuthor]];
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

- (void)configureLikeButton
{
    self.likeButton.selected = [self.contentProvider isLiked];
}

- (void)configureNumberOfLikes
{
    NSInteger likeCount = [[self.contentProvider numberOfLikes] integerValue];
    if (likeCount == 0) {
        self.numberOfLikesLabel.text = @"";
        return;
    }

    NSString *likesString = @"";
    if (likeCount == 1) {
        likesString = [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"Like", nil)];
    } else {
        likesString = [NSString stringWithFormat:@"%d %@", likeCount, NSLocalizedString(@"Likes", nil)];
    }

    // Add the dot character if we're showing the like button.
    if (self.shouldEnableLoggedinFeatures) {
        likesString = [NSString stringWithFormat:@"\u00B7 %@", likesString];
    }
    self.numberOfLikesLabel.text = likesString;
}

// Position the Y offset of the various views.
- (void)configureMetaView
{
    CGFloat yPosition = 0;
    self.replyButton.hidden = !(self.shouldEnableLoggedinFeatures && self.shouldShowReply);

    if (!self.replyButton.hidden) {
        yPosition += (self.replyButton.intrinsicContentSize.width + CommentContentViewMetaReplyButtonRightMargin);
    }
    self.likeButtonLeftMarginConstraint.constant = yPosition;

    self.likeButton.hidden = !self.shouldEnableLoggedinFeatures;
    if (!self.likeButton.hidden) {
        yPosition += (self.likeButton.intrinsicContentSize.width + CommentContentViewMetaStandardSpacing);
    }
    self.numberOfLikesLabelLeftMarginConstraint.constant = yPosition;

    if (self.shouldEnableLoggedinFeatures || [self.numberOfLikesLabel.text length] > 0) {
        self.commentMetaHeightConstraint.constant = CommentContentViewMetaHeight;
    } else {
        self.commentMetaHeightConstraint.constant = 0;
    }
}

- (void)configureContentView
{
    self.textContentView.privateContent = [self.contentProvider isPrivateContent];
    self.textContentView.content = [self sanitizedContentStringForDisplay:[self.contentProvider contentForDisplay]];
}

/**
 Returns a string for the specified `string`, formatted for the content view.

 @param string The string to convert to an attriubted string.
 @return A string formatted to display in the comment view.
 */
- (NSString *)sanitizedContentStringForDisplay:(NSString *)string
{
    NSString *str = [string trim];
    if (str == nil) {
        str = @"";
    }

    // remove trailing br tags so we don't have a bunch of whitespace
    static NSRegularExpression *brRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        brRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\s*<br\\s*(/?)\\s*>\\s*)*$" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    NSArray *matches = [brRegex matchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, [str length])];
    if ([matches count]) {
        NSTextCheckingResult *match = [matches firstObject];
        str = [str substringToIndex:match.range.location];
    }

    return str;
}


#pragma mark - Actions

- (void)handleAuthorTapped:(id)sender
{
    // Just do a hand off to the rich text delegate
    NSURL *url = [self.contentProvider authorURL];
    [self richTextView:self.textContentView didReceiveLinkAction:url];
}

- (void)handleReplyTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(handleReplyTapped:)]) {
        [self.delegate handleReplyTapped:self.contentProvider];
    }
}

- (void)handleLikeTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(toggleLikeStatus:)]) {
        [self.delegate toggleLikeStatus:self.contentProvider];
    }
}


#pragma mark - WPRichTextView Delegate methods

- (void)richTextView:(WPRichTextView *)richTextView didReceiveLinkAction:(NSURL *)linkURL
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveLinkAction:linkURL];
    }
}

- (void)richTextView:(WPRichTextView *)richTextView didReceiveImageLinkAction:(WPRichTextImage *)imageControl
{
    if ([self.delegate respondsToSelector:@selector(richTextView:didReceiveImageLinkAction:)]) {
        [self.delegate richTextView:richTextView didReceiveImageLinkAction:imageControl];
    }
}

- (void)richTextViewDidLoadMediaBatch:(WPRichTextView *)richTextView
{
    [self.delegate commentView:self updatedAttachmentViewsForProvider:self.contentProvider];
}

@end
