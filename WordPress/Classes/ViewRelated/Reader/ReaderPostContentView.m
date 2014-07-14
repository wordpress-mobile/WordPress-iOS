#import "ReaderPostContentView.h"
#import "ReaderPost.h"
#import "ContentActionButton.h"
#import "ReaderPostAttributionView.h"

@interface ReaderPostContentView()<WPContentAttributionViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;

@end

@implementation ReaderPostContentView

#pragma mark - LifeCycle Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Action buttons
        _reblogButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-reblog-done"]];
        [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];

        _commentButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
        [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];

        _likeButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];

        // Optimistically set action buttons and prime constraints for scrolling performance.
        self.actionButtons = @[_likeButton, _commentButton, _reblogButton];
    }
    return self;
}


#pragma mark - Public Methods

- (void)configurePost:(ReaderPost *)post
{
    self.post = post;
    self.shouldShowActions = post.isWPCom;
    self.contentProvider = post;
}

- (void)setAvatarImage:(UIImage *)image
{
    static UIImage *wpcomBlavatar;
    static UIImage *gravatarReader;
    if (!image) {
        if (self.post.isWPCom) {
            static dispatch_once_t blavatarOnceToken;
            dispatch_once(&blavatarOnceToken, ^{
                wpcomBlavatar = [UIImage imageNamed:@"wpcom_blavatar"];
            });
            image = wpcomBlavatar;
        } else {
            static dispatch_once_t gravatarOnceToken;
            dispatch_once(&gravatarOnceToken, ^{
                gravatarReader = [UIImage imageNamed:@"gravatar-reader"];
            });
            image = gravatarReader;
        }
    }
    [self.attributionView setAvatarImage:image];
}

- (BOOL)privateContent
{
    return self.post.isPrivate;
}


#pragma mark - Private Methods

- (void)configureActionButtons
{
    if (!self.shouldShowActions) {
        self.actionButtons = @[];
        return;
    }

    NSMutableArray *actionButtons = [NSMutableArray array];

    [actionButtons addObject:self.likeButton];

    if (self.post.commentsOpen) {
        [actionButtons addObject:self.commentButton];
    }

    // Don't reblog private blogs
    if (![self privateContent]) {
        [actionButtons addObject:self.reblogButton];
    }
    
    self.actionButtons = actionButtons;

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
    [self.likeButton setNeedsLayout];

    if ([self.post.commentCount integerValue] > 0) {
        title = [self.post.commentCount stringValue];
    } else {
        title = @"";
    }
    [self.commentButton setTitle:title forState:UIControlStateNormal];
    [self.commentButton setTitle:title forState:UIControlStateSelected];
    [self.commentButton setNeedsLayout];

    // Show highlights
    [self.likeButton setSelected:self.post.isLiked];
    [self.reblogButton setSelected:self.post.isReblogged];
    [self.reblogButton setNeedsLayout];

    // You can only reblog once.
    self.reblogButton.userInteractionEnabled = !self.post.isReblogged;
}

- (void)configureAttributionView
{
    [super configureAttributionView];
    [self.attributionView selectAttributionButton:self.post.isFollowing];
}

- (WPContentAttributionView *)viewForAttributionView
{
    ReaderPostAttributionView *attrView = [[ReaderPostAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    attrView.delegate = self;
    return attrView;
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

@end
