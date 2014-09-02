#import "ReaderCommentCell.h"
#import "Comment.h"
#import "CommentContentView.h"

static const NSInteger ReaderCommentCellMaxIndentationLevel = 5;
static const CGFloat ReaderCommentCellIndentationWidth = 16.0;
static const CGFloat ReaderCommentCellTopPadding = 12.0;
static const CGFloat ReaderCommentCellBottomPadding = 20.0;
static const CGFloat ReaderCommentCellSidePadding = 12.0;

@interface ReaderCommentCell()<CommentContentViewDelegate>

@property (nonatomic, strong) Comment *comment;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) CommentContentView *commentContentView;
@property (nonatomic, strong) NSLayoutConstraint *zeroTopMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *defaultTopMarginConstraint;

@end


@implementation ReaderCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // TODO: configure background
//        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"nested-comment-background"]];

        // configure top border
        _borderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), 1)];
        _borderView.translatesAutoresizingMaskIntoConstraints = NO;
        _borderView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        [self.contentView addSubview:_borderView];

        _commentContentView = [[CommentContentView alloc] init];
        _commentContentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_commentContentView];

        [self configureConstraints];
        [self configureCommentContentTopPadding];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize commentContentViewSize = [self.commentContentView sizeThatFits:size];
    CGFloat desiredHeight = commentContentViewSize.height + ReaderCommentCellBottomPadding;
    if (self.indentationLevel == 0) {
        desiredHeight += ReaderCommentCellTopPadding;
    }
    return CGSizeMake(size.width, desiredHeight);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.indentationLevel = 0;
    [self.commentContentView reset];
}

- (void)setAvatarImage:(UIImage *)avatarImage
{
    [self.commentContentView setAvatarImage:avatarImage];
}

- (void)configureCell:(Comment *)comment
{
    self.comment = comment;

    self.indentationWidth = ReaderCommentCellIndentationWidth;
//    self.indentationLevel = MIN(ReaderCommentCellMaxIndentationLevel, [comment.depth integerValue]);

    self.commentContentView.contentProvider = comment;
    [self configureCommentContentTopPadding];

    // Highlighting the author of the post
//    NSString *authorUrl = comment.author_url;
//    if ([authorUrl isEqualToString:comment.post.authorURL]) {
//        [self.commentContentView highlightAuthor:YES];
//    }
}


- (void)configureConstraints
{
    NSNumber *sidePadding = @(ReaderCommentCellSidePadding);
    NSNumber *bottomPadding = @(ReaderCommentCellBottomPadding);
    NSDictionary *metrics =  @{@"sidePadding":sidePadding,
                               @"bottomPadding":bottomPadding};

    UIView *contentView = self.contentView;
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView, _commentContentView, _borderView);
    // Border View
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(sidePadding)-[_borderView]-(sidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_borderView(12)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];


    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(sidePadding)-[_commentContentView]-(sidePadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_commentContentView]-(bottomPadding)-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
}

- (void)configureCommentContentTopPadding
{
    if (!self.zeroTopMarginConstraint) {
        self.zeroTopMarginConstraint = [NSLayoutConstraint constraintWithItem:self.commentContentView
                                                                    attribute:NSLayoutAttributeTopMargin
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0];
    }

    if (!self.defaultTopMarginConstraint) {
        self.defaultTopMarginConstraint = [NSLayoutConstraint constraintWithItem:self.commentContentView
                                                                       attribute:NSLayoutAttributeTopMargin
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentView
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1.0
                                                                        constant:ReaderCommentCellTopPadding];
    }

    NSLayoutConstraint *constraintToAdd;
    NSLayoutConstraint *constraintToRemove;

    if (self.indentationLevel == 0) {
        constraintToAdd = self.defaultTopMarginConstraint;
        constraintToRemove = self.zeroTopMarginConstraint;
    } else {
        constraintToRemove = self.defaultTopMarginConstraint;
        constraintToAdd = self.zeroTopMarginConstraint;
    }

    // Remove the old constraint if necessary.
    if ([self.constraints indexOfObject:constraintToRemove] != NSNotFound) {
        [self removeConstraint:constraintToRemove];
    }

    // Add the new constraint and update if necessary.
    if ([self.constraints indexOfObject:constraintToAdd] == NSNotFound) {
        [self addConstraint:constraintToAdd];
    }
    [self setNeedsUpdateConstraints];
}


#pragma mark - Actions

- (void)handleLinkTapped:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(commentCell:linkTapped:)]) {
        [self.delegate commentCell:self linkTapped:url];
    }
}

- (void)handleReplyTapped:(id<WPContentViewProvider>)contentProvider
{
    if ([self.delegate respondsToSelector:@selector(commentCell:replyToComment:)]) {
        [self.delegate commentCell:self replyToComment:self.comment];
    }
}

@end
