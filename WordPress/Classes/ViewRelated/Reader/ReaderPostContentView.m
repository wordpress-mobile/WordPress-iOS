#import "ReaderPostContentView.h"
#import "ReaderPost.h"
#import "ContentActionButton.h"
#import "ReaderPostAttributionView.h"

@interface ReaderPostContentView()<WPContentAttributionViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *likeButton;

@end

@implementation ReaderPostContentView

@dynamic delegate;

#pragma mark - LifeCycle Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildActionButtons];
    }
    return self;
}

#pragma mark - Public Methods

- (void)configurePost:(ReaderPost *)post
{
    self.post = post;
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

- (BOOL)shouldShowActionButtons
{
    // Do not show action buttons for source attributed posts.
    return self.post.isWPCom && !self.post.sourceAttribution;
}

- (void)buildActionButtons
{
    self.shouldShowAttributionButton = YES;

    // Action buttons
    self.commentButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-comment-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-comment-active"]];
    [self.commentButton addTarget:self action:@selector(commentAction:) forControlEvents:UIControlEventTouchUpInside];
    self.commentButton.accessibilityLabel = NSLocalizedString(@"Comment", @"Accessibility  Label for the Comment Button in the Reader. Tapping shows a screen that allows the user to comment a post.");
    self.commentButton.accessibilityIdentifier = @"Comment";

    self.likeButton = [super createActionButtonWithImage:[UIImage imageNamed:@"reader-postaction-like-blue"] selectedImage:[UIImage imageNamed:@"reader-postaction-like-active"]];
    [self.likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
    self.likeButton.accessibilityLabel = NSLocalizedString(@"Like", @"Accessibility  Label for the Like Button in the Reader. Tapping this button makes the user like the related post.");
    self.likeButton.accessibilityIdentifier = @"Like";

    // Optimistically set action buttons and prime constraints for scrolling performance.
    self.actionButtons = @[self.likeButton, self.commentButton];
}

- (void)configureActionButtons
{
    if (![self shouldShowActionButtons]) {
        self.actionButtons = @[];
        return;
    }

    NSMutableArray *actionButtons = [NSMutableArray array];

    if (self.post.isLikesEnabled){
        [actionButtons addObject:self.likeButton];
    }

    if (!self.shouldHideComments && (self.post.commentsOpen || [self.post.commentCount integerValue] > 0)) {
        [actionButtons addObject:self.commentButton];
    }

    self.actionButtons = actionButtons;

    [self updateActionButtons];
}

- (void)updateActionButtons
{
    if (![self shouldShowActionButtons]) {
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

    // Enable/Disable like button. Set userInteractionEnabled to avoid the default disabled tint. 
    self.likeButton.userInteractionEnabled = self.shouldEnableLoggedinFeatures;
}

- (void)configureAttributionView
{
    [super configureAttributionView];
    [self.attributionView selectAttributionButton:self.post.isFollowing];

    [self.attributionView hideAttributionButton:!self.shouldShowAttributionButton];

    BOOL hide = (self.shouldShowAttributionMenu && self.post.isWPCom)? NO : YES;
    [self.attributionView hideAttributionMenu:hide];
}

- (void)buildAttributionView
{
    ReaderPostAttributionView *attrView = [[ReaderPostAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    attrView.delegate = self;

    self.attributionView = attrView;
    [self addSubview:self.attributionView];
}


#pragma mark - Action Methods

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
