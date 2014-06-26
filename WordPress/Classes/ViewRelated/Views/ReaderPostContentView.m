#import "ReaderPostContentView.h"
#import "ReaderPost.h"
#import "ContentActionButton.h"

@interface ReaderPostContentView()

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;

@end

@implementation ReaderPostContentView

- (id)init
{
    self = [super init];
    if (self) {
// TODO: How to wrangle this guy?
        self.followButton = [ContentActionButton buttonWithType:UIButtonTypeCustom];
        [WPStyleGuide configureFollowButton:self.followButton];
        [self.followButton setTitleEdgeInsets: UIEdgeInsetsMake(0, 2, 0, 0)];
        [self.followButton addTarget:self action:@selector(followAction:) forControlEvents:UIControlEventTouchUpInside];

        // Action buttons
        self.reblogButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-reblog-done"]];
        [self.reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];

        self.commentButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
        [self.commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];

        self.likeButton = [super addActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
        [self.likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)configurePost:(ReaderPost *)post
{
    self.post = post;
    self.contentProvider = post;
}

- (void)reset
{
    [super reset];
    [self.followButton setSelected:NO];
}

- (void)configureActionButtons
{
    if (!self.shouldShowActions) {
        return;
    }

    [self.actionView removeAllActionButtons];

    // Don't reblog private blogs
    if (![self privateContent]) {
        [self.actionView addActionButton:self.reblogButton];
    }

    if (self.post.commentsOpen) {
        [self.actionView addActionButton:self.commentButton];
    }

    [self.actionView addActionButton:self.likeButton];

    [self updateActionButtons];
}

- (void)updateActionButtons
{
    if (!self.shouldShowActions) {
        return;
    }

    // Update/show counts for likes and comments
    NSString *title;
    if ([self.post.likeCount integerValue] > 0) {
        title = [self.post.likeCount stringValue];
    } else {
        title = @"";
    }
    [self.likeButton setTitle:title forState:UIControlStateNormal];
    [self.likeButton setTitle:title forState:UIControlStateSelected];

    if ([self.post.commentCount integerValue] > 0) {
        title = [self.post.commentCount stringValue];
    } else {
        title = @"";
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
    [self.commentButton setTitle:title forState:UIControlStateSelected];

    // Show highlights
    [self.likeButton setSelected:self.post.isLiked];
    [self.reblogButton setSelected:self.post.isReblogged];

    // You can only reblog once.
    self.reblogButton.userInteractionEnabled = !self.post.isReblogged;
}

- (void)setAvatarImage:(UIImage *)image
{
    if (!image) {
        if (self.post.isWPCom) {
            image = [UIImage imageNamed:@"wpcom_blavatar"];
        } else {
            image = [UIImage imageNamed:@"gravatar-reader"];
        }
    }
    [self.attributionView setAvatarImage:image];
}

- (BOOL)privateContent
{
    return self.post.isPrivate;
}


#pragma mark - Action Methods

- (void)reblogAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveReblogAction:)]) {
        [self.delegate postView:self didReceiveReblogAction:sender];
    }
}

- (void)commentAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveCommentAction:)]) {
        [self.delegate postView:self didReceiveCommentAction:sender];
    }
}

- (void)likeAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveLikeAction:)]) {
        [self.delegate postView:self didReceiveLikeAction:sender];
    }
}

- (void)followAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(contentView:didReceiveFollowAction:)]) {
        [self.delegate postView:self didReceiveFollowAction:sender];
    }
}

@end
