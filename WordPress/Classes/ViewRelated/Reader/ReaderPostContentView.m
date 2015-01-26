#import "ReaderPostContentView.h"
#import "ReaderPost.h"
#import "ContentActionButton.h"
#import "ReaderPostAttributionView.h"

@interface ReaderPostContentView()<WPContentAttributionViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic) BOOL shouldShowActionButtons;

@end

@implementation ReaderPostContentView

#pragma mark - LifeCycle Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _canShowActionButtons = YES;
        _shouldShowAttributionButton = YES;

        // Action buttons
        _reblogButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-reblog-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-reblog-done"]];
        [_reblogButton addTarget:self action:@selector(reblogAction:) forControlEvents:UIControlEventTouchUpInside];
        _reblogButton.accessibilityLabel = NSLocalizedString(@"Reblog", @"Accessibility  Label for the Reblog Button in the Reader. Tapping shows a screen that allows the user to reblog a post.");
        _reblogButton.accessibilityIdentifier = @"Reblog";
        
        _commentButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
        [_commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
        _commentButton.accessibilityLabel = NSLocalizedString(@"Comment", @"Accessibility  Label for the Comment Button in the Reader. Tapping shows a screen that allows the user to comment a post.");
        _commentButton.accessibilityIdentifier = @"Comment";
        
        _likeButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
        _likeButton.accessibilityLabel = NSLocalizedString(@"Like", @"Accessibility  Label for the Like Button in the Reader. Tapping this button makes the user like the related post.");
        _likeButton.accessibilityIdentifier = @"Like";

        // Optimistically set action buttons and prime constraints for scrolling performance.
        self.actionButtons = @[_likeButton, _commentButton, _reblogButton];
    }
    return self;
}

#pragma mark - Public Methods

- (void)configurePost:(ReaderPost *)post
{
    self.post = post;
    self.shouldShowActionButtons = (post.isWPCom && self.canShowActionButtons);
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
    if (!self.shouldShowActionButtons) {
        self.actionButtons = @[];
        return;
    }

    NSMutableArray *actionButtons = [NSMutableArray array];

    if (self.post.isLikesEnabled){
        [actionButtons addObject:self.likeButton];
    }

    if (self.post.commentsOpen && !self.shouldHideComments) {
        [actionButtons addObject:self.commentButton];
    }

    // Reblogging just for non private blogs
    if (![self privateContent]) {
        [actionButtons addObject:self.reblogButton];
    }

    self.actionButtons = actionButtons;

    [self updateActionButtons];
}

- (void)updateActionButtons
{
    if (!self.shouldShowActionButtons) {
        return;
    }

    // Update/show counts for likes and comments
    NSString *title;
    if ([self.post.likeCount integerValue] > 0) {
        title = [self.post.likeCount stringValue];
    }

    [self.likeButton setTitle:title forState:UIControlStateNormal];
    [self.likeButton setTitle:title forState:UIControlStateSelected];
    [self.likeButton setTitle:title forState:UIControlStateDisabled];
    [self.likeButton setTitle:title forState:UIControlStateHighlighted];
    [self.likeButton setNeedsLayout];

    title = nil;
    if ([self.post.commentCount integerValue] > 0) {
        title = [self.post.commentCount stringValue];
    }

    [self.commentButton setTitle:title forState:UIControlStateNormal];
    [self.commentButton setTitle:title forState:UIControlStateSelected];
    [self.commentButton setTitle:title forState:UIControlStateDisabled];
    [self.commentButton setTitle:title forState:UIControlStateHighlighted];
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

    [self.attributionView hideAttributionButton:!self.shouldShowAttributionButton];

    BOOL hide = (self.shouldShowAttributionMenu && self.post.isWPCom)? NO : YES;
    [self.attributionView hideAttributionMenu:hide];
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
