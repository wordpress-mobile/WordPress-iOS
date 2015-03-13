#import "ReaderCommentCell.h"
#import "Comment.h"
#import "CommentContentView.h"

static const NSInteger ReaderCommentCellMaxIndentationLevel = 4;
static const CGFloat ReaderCommentCellIndentationWidth = 16.0;
static const CGFloat ReaderCommentCellSidePadding = 12.0;
static const CGFloat ReaderCommentCellTopPadding = 12.0;
static const CGFloat ReaderCommentCellBottomPadding = -8.0;
static const CGFloat ReaderCommentCellBottomPaddingMore = -20.0;

@interface ReaderCommentCell()

@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIView *nestingView;
@property (nonatomic, strong) UIView *nestingOverlayView;
@property (nonatomic, strong) CommentContentView *commentContentView;
@property (nonatomic, strong) NSLayoutConstraint *bottomMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *leftIndentationConstraint;

@end


@implementation ReaderCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
        selectedBackgroundView.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = selectedBackgroundView;

        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        _nestingView = [[UIView alloc] initWithFrame:self.bounds];
        _nestingView.translatesAutoresizingMaskIntoConstraints = NO;
        _nestingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-comment-nesting"]];
        [self.contentView addSubview:_nestingView];

        _nestingOverlayView = [[UIView alloc] initWithFrame:self.bounds];
        _nestingOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _nestingOverlayView.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        [self.contentView addSubview:_nestingOverlayView];

        // configure top border
        _borderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), 1)];
        _borderView.translatesAutoresizingMaskIntoConstraints = NO;
        _borderView.backgroundColor = [WPStyleGuide readGrey];
        [self.contentView addSubview:_borderView];

        _commentContentView = [[CommentContentView alloc] initWithFrame:self.bounds];
        _commentContentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_commentContentView];

        [self configureConstraints];
    }

    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    // Adjust width for indentation and padding
    CGFloat adjustedWidth = size.width - (ReaderCommentCellSidePadding * 2);
    adjustedWidth -= (self.indentationWidth * self.indentationLevel);

    CGSize commentContentViewSize = [self.commentContentView sizeThatFits:CGSizeMake(adjustedWidth, size.height)];
    CGFloat desiredHeight = commentContentViewSize.height + ReaderCommentCellTopPadding;
    if (self.needsExtraPadding) {
        desiredHeight += fabs(ReaderCommentCellBottomPaddingMore);
    } else {
        desiredHeight += fabs(ReaderCommentCellBottomPadding);
    }
    CGSize desiredSize = CGSizeMake(size.width, desiredHeight);
    return desiredSize;
}

- (void)setAvatarImage:(UIImage *)avatarImage
{
    [self.commentContentView setAvatarImage:avatarImage];
}

- (void)configureCell:(Comment *)comment
{
    self.comment = comment;

    self.indentationWidth = ReaderCommentCellIndentationWidth;
    self.indentationLevel = MIN(ReaderCommentCellMaxIndentationLevel, [comment.depth integerValue]);

    self.nestingOverlayView.hidden = !self.isFirstNestedComment;
    self.borderView.hidden = (self.hidesBorder || self.indentationLevel != 0);
    self.leftIndentationConstraint.constant = ReaderCommentCellSidePadding + (self.indentationLevel * self.indentationWidth);
    self.bottomMarginConstraint.constant = (self.needsExtraPadding) ? ReaderCommentCellBottomPaddingMore : ReaderCommentCellBottomPadding;

    self.commentContentView.contentProvider = comment;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat x = MAX(0, self.indentationLevel - 1) * self.indentationWidth;
    self.nestingOverlayView.frame = CGRectMake(x, 0.0, ReaderCommentCellIndentationWidth, ReaderCommentCellTopPadding - 4);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.hidesBorder = NO;
    self.isFirstNestedComment = NO;
    self.needsExtraPadding = NO;
}

- (void)configureConstraints
{
    NSNumber *sidePadding = @(ReaderCommentCellSidePadding);
    NSNumber *topPadding = @(ReaderCommentCellTopPadding);
    NSDictionary *metrics =  @{@"sidePadding":sidePadding,
                               @"topPadding":topPadding};

    UIView *contentView = self.contentView;
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView, _commentContentView, _borderView, _nestingView, _nestingOverlayView);

    // Comment Nesting Lines View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_nestingView][_commentContentView]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_nestingView]|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    // Border View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(sidePadding)-[_borderView]-(sidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_borderView(1)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    // Content Positioning
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_commentContentView]-(sidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topPadding-[_commentContentView]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    self.leftIndentationConstraint = [NSLayoutConstraint constraintWithItem:self.commentContentView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.contentView
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:ReaderCommentCellSidePadding];
    [self.contentView addConstraint:self.leftIndentationConstraint];

    self.bottomMarginConstraint = [NSLayoutConstraint constraintWithItem:self.commentContentView
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentView
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant:-ReaderCommentCellBottomPadding];
    [self.contentView addConstraint:self.bottomMarginConstraint];
}

- (id<CommentContentViewDelegate>)delegate
{
    return self.commentContentView.delegate;
}

- (void)setDelegate:(id<CommentContentViewDelegate>)delegate
{
    self.commentContentView.delegate = delegate;
}

- (BOOL)shouldEnableLoggedinFeatures
{
    return self.commentContentView.shouldEnableLoggedinFeatures;
}

- (void)setShouldEnableLoggedinFeatures:(BOOL)shouldEnableLoggedinFeatures
{
    self.commentContentView.shouldEnableLoggedinFeatures = shouldEnableLoggedinFeatures;
}

- (BOOL)shouldShowReply
{
    return self.commentContentView.shouldShowReply;
}

- (void)setShouldShowReply:(BOOL)shouldShowReply
{
    self.commentContentView.shouldShowReply = shouldShowReply;
}

- (void)refreshMediaLayout
{
    [self.commentContentView refreshMediaLayout];
}

- (void)preventPendingMediaLayout:(BOOL)prevent
{
    [self.commentContentView preventPendingMediaLayout:prevent];
}

@end
