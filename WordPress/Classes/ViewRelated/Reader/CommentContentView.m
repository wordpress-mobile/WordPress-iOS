#import "CommentContentView.h"
#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"

static const CGFloat CommentContentViewAvatarSize = 32.0;
static const CGFloat CommentContentViewContentViewOffsetTop = 36.0;
static const CGFloat CommentContentViewContentViewOffsetBottom = 19.0;
static const CGFloat CommentContentViewContentOffsetLeft = 40.0;
static const CGFloat CommentContentViewButtonHeight = 16.0;
static const CGFloat CommentContnetViewButtonSpacingTop = 4.0;
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
    height = height + CommentContentViewContentViewOffsetTop + CommentContentViewContentViewOffsetBottom;
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
    NSDictionary *views = NSDictionaryOfVariableBindings(_avatarImageView, _authorButton, _timeButton, _textContentView, _replyButton, _likeButton, _numberOfLikesLabel);
    NSDictionary *metrics = @{@"avatarSize": @(CommentContentViewAvatarSize),
                              @"offsetTop" : @(CommentContentViewContentViewOffsetTop),
                              @"offsetBottom" : @(CommentContentViewContentViewOffsetBottom),
                              @"offsetLeft" : @(CommentContentViewContentOffsetLeft),
                              @"buttonMarginTop" : @(CommentContnetViewButtonSpacingTop),
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

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_replyButton]-20-[_likeButton]-[_numberOfLikesLabel]"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textContentView]-(buttonMarginTop@200)-[_replyButton(buttonHeight)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textContentView]-(buttonMarginTop@200)-[_likeButton(buttonHeight)]|"
                                                                 options:0
                                                                 metrics:metrics
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textContentView]-(buttonMarginTop@200)-[_numberOfLikesLabel(buttonHeight)]|"
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

    self.likeButton = [self buttonForLikeButton];
    [self addSubview:self.likeButton];

    self.numberOfLikesLabel = [self labelForNumberOfLikes];
    [self addSubview:self.numberOfLikesLabel];

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
    } else if (likeCount == 1) {
        self.numberOfLikesLabel.text = [NSString stringWithFormat:@"\u00B7 1 %@", NSLocalizedString(@"Like", nil)];
    } else {
        self.numberOfLikesLabel.text = [NSString stringWithFormat:@"\u00B7 %d %@", likeCount, NSLocalizedString(@"Likes", nil)];
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
