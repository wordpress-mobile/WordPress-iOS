#import "PostCardTableViewCell.h"
#import <AFNetworking/UIKit+AFNetworking.h>
#import "PostCardActionBar.h"
#import "PostCardActionBarItem.h"
#import <WordPressShared/WordPressShared.h>
#import <WordPressUI/WordPressUI.h>
#import "WPStyleGuide+Posts.h"
#import "WordPress-Swift.h"

@import Gridicons;


static const UIEdgeInsets ActionbarButtonImageInsets = {0.0, 0.0, 0.0, 4.0};
static const CGFloat ActionbarButtonImageSize = 18.0;

typedef NS_ENUM(NSUInteger, ActionBarMode) {
    ActionBarModePublish = 1,
    ActionBarModeScheduled,
    ActionBarModeDraftWithFutureDate,
    ActionBarModeDraft,
    ActionBarModeTrash,
    ActionBarModeFailed,
};


@interface PostCardTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *authorBlogLabel;
@property (nonatomic, strong) IBOutlet UILabel *authorNameLabel;
@property (nonatomic, strong) IBOutlet CachedAnimatedImageView *postCardImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *snippetLabel;
@property (nonatomic, strong) IBOutlet UIView *dateView;
@property (nonatomic, strong) IBOutlet UIImageView *dateImageView;
@property (nonatomic, strong) IBOutlet UIImageView *stickyImageView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *stickyLabel;
@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UIImageView *statusImageView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIView *metaView;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonRight;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonLeft;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet PostCardActionBar *actionBar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewTopConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewLeftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *snippetLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dateViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postCardImageViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postCardImageViewHeightConstraint;

@property (nonatomic, weak) id<InteractivePostViewDelegate> delegate;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PostCardStatusViewModel *viewModel;
@property (nonatomic, strong) ImageLoader *imageLoader;
@property (nonatomic) CGFloat headerViewHeight;
@property (nonatomic) CGFloat headerViewLowerMargin;
@property (nonatomic) CGFloat titleViewLowerMargin;
@property (nonatomic) CGFloat snippetViewLowerMargin;
@property (nonatomic) CGFloat dateViewLowerMargin;
@property (nonatomic) CGFloat statusViewHeight;
@property (nonatomic) CGFloat statusViewLowerMargin;
@property (nonatomic) BOOL didPreserveStartingConstraintConstants;
@property (nonatomic) ActionBarMode currentActionBarMode;

@end

@implementation PostCardTableViewCell

#pragma mark - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self applyStyles];

    [self.metaButtonLeft flipInsetsForRightToLeftLayoutDirection];
    [self.metaButtonRight flipInsetsForRightToLeftLayoutDirection];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Don't respond to taps in margins.
    if (!CGRectContainsPoint(self.postContentView.frame, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    if (self.didPreserveStartingConstraintConstants) {
        return;
    }
    // When awakeFromNib is called, constraint constants have the default values for
    // any w, any h. The constant values for the correct size class are not applied until
    // the view is first moved to its superview. When this happens, it will override any
    // value that has been assigned in the interrum.
    // Preserve starting constraint constants once the view has been added to a window
    // (thus getting a layout pass) and flag that they've been preserved. Then configure
    // the cell if needed.
    [self preserveStartingConstraintConstants];
    if (self.post) {
        [self configureWithPost:self.post];
    }
}

#pragma mark - Accessors

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    BOOL previouslyHighlighted = self.highlighted;
    [super setHighlighted:highlighted animated:animated];

    if (previouslyHighlighted == highlighted) {
        return;
    }

    if (highlighted) {
        [self setHighlightedEffect:highlighted animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.selected) {
                [self setHighlightedEffect:highlighted animated:animated];
            }
        });
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setHighlightedEffect:selected animated:animated];
}

- (void)setHighlightedEffect:(BOOL)highlighted animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? .1f : 0.f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.postContentView.layer.borderColor = highlighted ? [[UIColor clearColor] CGColor] : [[WPStyleGuide postCardBorderColor] CGColor];
                         self.alpha = highlighted ? .7f : 1.f;
                         if (highlighted) {
                             CGFloat perspective = IS_IPAD ? -0.00005 : -0.0001;
                             CATransform3D transform = CATransform3DIdentity;
                             transform.m24 = perspective;
                             transform = CATransform3DScale(transform, .98f, .98f, 1);
                             self.contentView.layer.transform = transform;
                             self.contentView.layer.shouldRasterize = YES;
                             self.contentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
                         } else {
                             self.contentView.layer.shouldRasterize = NO;
                             self.contentView.layer.transform = CATransform3DIdentity;
                         }
                     } completion:nil];
}

- (ImageLoader *)imageLoader
{
    if (!_imageLoader && self.postCardImageView) {
        _imageLoader = [[ImageLoader alloc] initWithImageView:self.postCardImageView gifStrategy:GIFStrategyMediumGIFs];
    }

    return _imageLoader;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (self.imageLoader) {
        [self.imageLoader prepareForReuse];
    }
    [self setNeedsDisplay];
}

#pragma mark - Configuration

- (void)preserveStartingConstraintConstants
{
    self.headerViewHeight = self.headerViewHeightConstraint.constant;
    self.headerViewLowerMargin = self.headerViewLowerConstraint.constant;
    self.titleViewLowerMargin = self.titleLowerConstraint.constant;
    self.snippetViewLowerMargin = self.snippetLowerConstraint.constant;
    self.dateViewLowerMargin = self.dateViewLowerConstraint.constant;
    self.statusViewHeight = self.statusHeightConstraint.constant;
    self.statusViewLowerMargin = self.statusViewLowerConstraint.constant;

    self.didPreserveStartingConstraintConstants = YES;
}

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyPostAuthorSiteStyle:self.authorBlogLabel];
    [WPStyleGuide applyPostAuthorNameStyle:self.authorNameLabel];
    [WPStyleGuide applyPostTitleStyle:self.titleLabel];
    [WPStyleGuide applyPostSnippetStyle:self.snippetLabel];
    [WPStyleGuide applyPostDateStyle:self.dateLabel];
    [WPStyleGuide applyPostDateStyle:self.stickyLabel];
    [WPStyleGuide applyPostStatusStyle:self.statusLabel];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonRight];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonLeft];
    [WPStyleGuide applyPostProgressViewStyle:self.progressView];

    self.dateImageView.tintColor = self.dateLabel.textColor;
    self.stickyImageView.image = [self.stickyImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.stickyImageView.tintColor = self.stickyLabel.textColor;
    self.actionBar.backgroundColor = [WPStyleGuide lightGrey];
    self.postContentView.layer.borderColor = [[WPStyleGuide postCardBorderColor] CGColor];
    self.postContentView.layer.borderWidth = 1.0;
    
    self.stickyLabel.text = NSLocalizedString(@"Sticky", @"Label text that defines a post marked as sticky");
}

#pragma mark - ConfigurablePostView

- (void)configureWithPost:(Post *)post
{
    if (post != self.post) {
        self.viewModel = [[PostCardStatusViewModel alloc] initWithPost:post];
    }

    self.post = post;

    if (!self.didPreserveStartingConstraintConstants) {
        return;
    }

    [self configureHeader];
    [self configureCardImage];
    [self configureTitle];
    [self configureSnippet];
    [self configureDate];
    [self configureStatusView];
    [self configureMetaButtons];
    [self configureProgressView];
    [self configureActionBar];
    [self configureStickyPost];

    [self setNeedsUpdateConstraints];
}

#pragma mark - InteractivePostView

- (void)setInteractionDelegate:(id<InteractivePostViewDelegate>)delegate
{
    self.delegate = delegate;
}

#pragma mark - Configuration

- (void)configureHeader
{
    if (![self.post isMultiAuthorBlog]) {
        self.headerViewHeightConstraint.constant = 0;
        // Move the next element up to where the header was.
        self.headerViewLowerConstraint.constant = self.headerViewTopConstraint.constant;
        // If not visible, just return and don't bother setting the text or loading the avatar.
        self.headerView.hidden = YES;
        return;
    }

    self.headerView.hidden = NO;
    self.headerViewHeightConstraint.constant = self.headerViewHeight;
    self.headerViewLowerConstraint.constant = self.headerViewLowerMargin;
    self.authorBlogLabel.text = [self.post blogNameForDisplay];
    self.authorNameLabel.text = [self.post authorNameForDisplay];

    UIImage *placeholder = [UIImage imageNamed:@"post-blavatar-placeholder"];
    [self.avatarImageView downloadSiteIconFor:self.post.blog placeholderImage:placeholder];
}

- (void)configureCardImage
{
    if (!self.imageLoader) {
        return;
    }

    AbstractPost *post = [self.post latest];
    NSURL *url = [post featuredImageURLForDisplay];
    if (url == nil) {
        // no feature image available.
        return;
    }

    CGFloat desiredWidth = [UIApplication  sharedApplication].keyWindow.frame.size.width;
    CGFloat desiredHeight = self.postCardImageViewHeightConstraint.constant;
    CGSize imageSize = CGSizeMake(desiredWidth, desiredHeight);

    [self.imageLoader loadImageWithURL:url fromPost:post andPreferredSize:imageSize];
}

- (void)configureTitle
{
    AbstractPost *post = [self.post latest];
    NSString *str = [post titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str.stringByStrippingHTML attributes:[WPStyleGuide postCardTitleAttributes]];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLowerConstraint.constant = ([str length] > 0) ? self.titleViewLowerMargin : 0.0;
}

- (void)configureSnippet
{
    AbstractPost *post = [self.post latest];
    NSString *str = [post contentPreviewForDisplay] ?: [NSString string];
    self.snippetLabel.attributedText = [[NSAttributedString alloc] initWithString:str.stringByStrippingHTML attributes:[WPStyleGuide postCardSnippetAttributes]];
    self.snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.snippetLowerConstraint.constant = ([str length] > 0) ? self.snippetViewLowerMargin : 0.0;
}

- (void)configureDate
{
    AbstractPost *post = [self.post latest];
    self.dateLabel.text = [post dateStringForDisplay];
    self.dateImageView.image = [Gridicon iconOfType:GridiconTypeTime];
}

- (void)configureStatusView
{
    self.statusView.hidden = self.viewModel.shouldHideStatusView;
    if (self.statusView.hidden) {
        self.dateViewLowerConstraint.constant = 0.0;
        self.statusHeightConstraint.constant = 0.0;
    } else {
        self.dateViewLowerConstraint.constant = self.dateViewLowerMargin;
        self.statusHeightConstraint.constant = self.statusViewHeight;
    }

    self.statusLabel.text = self.viewModel.status;
    self.statusImageView.image = self.viewModel.statusImage;
    self.statusImageView.tintColor = self.viewModel.statusColor;
    self.statusLabel.textColor = self.viewModel.statusColor;

    [self.statusView setNeedsUpdateConstraints];
}

- (void)configureStickyPost
{
    self.stickyLabel.hidden = !self.post.isStickyPost;
    self.stickyImageView.hidden = self.stickyLabel.hidden;
}


#pragma mark - Configure Meta

- (void)configureMetaButtons
{
    [self resetMetaButton:self.metaButtonRight];
    [self resetMetaButton:self.metaButtonLeft];

    NSMutableArray *mButtons = [NSMutableArray arrayWithObjects:self.metaButtonLeft, self.metaButtonRight, nil];
    if ([self.post numberOfComments] > 0) {
        UIButton *button = [mButtons lastObject];
        [mButtons removeLastObject];
        NSString *title = [NSString stringWithFormat:@"%d", [(Post *)(self.post) numberOfComments]];
        [self configureMetaButton:button withTitle:title andImage:[UIImage imageNamed:@"icon-postmeta-comment"]];
    }

    if ([self.post numberOfLikes] > 0) {
        UIButton *button = [mButtons lastObject];
        [mButtons removeLastObject];
        NSString *title = [NSString stringWithFormat:@"%d", [(Post *)(self.post) numberOfLikes]];
        [self configureMetaButton:button withTitle:title andImage:[UIImage imageNamed:@"icon-postmeta-like"]];
    }
}

- (void)resetMetaButton:(UIButton *)metaButton
{
    [metaButton setTitle:nil forState:UIControlStateNormal];
    [metaButton setImage:nil forState:UIControlStateNormal];
    [metaButton setImage:nil forState:UIControlStateHighlighted];
    metaButton.selected = NO;
    metaButton.hidden = YES;
}

- (void)configureMetaButton:(UIButton *)metaButton withTitle:(NSString *)title andImage:(UIImage *)image
{
    [metaButton setTitle:title forState:UIControlStateNormal];
    [metaButton setImage:image forState:UIControlStateNormal];
    [metaButton setImage:image forState:UIControlStateHighlighted];
    metaButton.selected = NO;
    metaButton.hidden = NO;
}

#pragma mark - Configure Progress View

- (void)configureProgressView
{
    BOOL shouldHide = self.viewModel.shouldHideProgressView;

    if (self.progressView.isHidden != shouldHide) {
        self.progressView.hidden = shouldHide;
    }

    self.progressView.progress = self.viewModel.progress;

    if (!shouldHide && !self.viewModel.progressBlock) {
        __weak __typeof(self) weakSelf = self;
        self.viewModel.progressBlock = ^(double progress){
            weakSelf.progressView.progress = progress;
            if (progress >= 1.0) {
                [weakSelf configureWithPost:weakSelf.post];
            }
        };
    }
}

#pragma mark - Configure Actionbar

- (void)configureActionBar
{
    NSString *status = [self.post status];
    if (self.post.isFailed) {
        [self configureFailedActionBar];
    } else if ([status isEqualToString:PostStatusPublish] || [status isEqualToString:PostStatusPrivate]) {
        [self configurePublishedActionBar];
    } else if ([status isEqualToString:PostStatusTrash]) {
        // trashed
        [self configureTrashedActionBar];
    } else if ([status isEqualToString:PostStatusScheduled]) {
        // scheduled
        [self configureScheduledActionBar];
    } else {
        if (self.post.hasFuturePublishDate) {
            [self configureDraftWithFutureDateActionBar];
        } else {
            // anything else (draft, something custom) treat as draft
            [self configureDraftActionBar];
        }
    }
    [self.actionBar reset];
}

- (void)configureFailedActionBar
{
    if (self.currentActionBarMode == ActionBarModeFailed) {
        return;
    }
    self.currentActionBarMode = ActionBarModeFailed;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editActionBarItemWithInsets:imageInsets]];
    [items addObject:[self retryActionBarItemWithInsets:imageInsets]];
    [items addObject:[self trashActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (void)configurePublishedActionBar
{
    if (self.currentActionBarMode == ActionBarModePublish) {
        return;
    }
    self.currentActionBarMode = ActionBarModePublish;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editActionBarItemWithInsets:imageInsets]];
    [items addObject:[self viewActionBarItemWithInsets:imageInsets]];
    if ([self.post supportsStats]) {
        [items addObject:[self statsActionBarItemWithInsets:imageInsets]];
    }
    [items addObject:[self trashActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (void)configureScheduledActionBar
{
    if (self.currentActionBarMode == ActionBarModeScheduled) {
        return;
    }
    self.currentActionBarMode = ActionBarModeScheduled;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editActionBarItemWithInsets:imageInsets]];
    [items addObject:[self previewActionBarItemWithInsets:imageInsets]];
    [items addObject:[self trashActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (void)configureDraftWithFutureDateActionBar
{
    if (self.currentActionBarMode == ActionBarModeDraftWithFutureDate) {
        return;
    }
    self.currentActionBarMode = ActionBarModeDraftWithFutureDate;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editActionBarItemWithInsets:imageInsets]];
    [items addObject:[self previewActionBarItemWithInsets:imageInsets]];
    [items addObject:[self scheduleActionBarItemWithInsets:imageInsets]];
    [items addObject:[self trashActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (void)configureDraftActionBar
{
    if (self.currentActionBarMode == ActionBarModeDraft) {
        return;
    }
    self.currentActionBarMode = ActionBarModeDraft;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editActionBarItemWithInsets:imageInsets]];
    [items addObject:[self previewActionBarItemWithInsets:imageInsets]];
    [items addObject:[self publishActionBarItemWithInsets:imageInsets]];
    [items addObject:[self trashActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (void)configureTrashedActionBar
{
    if (self.currentActionBarMode == ActionBarModeTrash) {
        return;
    }
    self.currentActionBarMode = ActionBarModeTrash;

    UIEdgeInsets imageInsets = ActionbarButtonImageInsets;
    if ([self userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft) {
        imageInsets = [InsetsHelper flipForRightToLeftLayoutDirection:imageInsets];
    }

    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self restoreActionBarItemWithInsets:imageInsets]];
    [items addObject:[self deleteActionBarItemWithInsets:imageInsets]];
    [self.actionBar setItems:items];
}

- (PostCardActionBarItem *)editActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Edit", @"Label for the edit post button. Tapping displays the editor.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-edit"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf editPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)viewActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"View", @"Label for the view post button. Tapping displays the post as it appears on the web.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-view"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf viewPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)retryActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Retry", @"Label for the retry post upload button. Tapping attempts to upload the post again.")
                                                         image:[Gridicon iconOfType:GridiconTypeRefresh withSize:CGSizeMake(ActionbarButtonImageSize, ActionbarButtonImageSize)]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [PostCoordinator.shared retrySaveOf:self.post];
                                                   }];
    item.tintColor = self.viewModel.statusColor;
    return item;
}

- (PostCardActionBarItem *)statsActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Stats", @"Label for the view stats button. Tapping displays statistics for a post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-stats"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf statsPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)trashActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Trash", @"Label for the trash post button. Tapping moves a post to the trash bin.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-trash"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf trashPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)previewActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Preview", @"Label for the preview post button. Tapping shows a preview of the post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-view"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf viewPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)publishActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Publish", @"Label for the publish (verb) button. Tapping publishes a draft post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-publish"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf publishPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)scheduleActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Schedule", @"Label for the schedule button. Tapping publishes a draft post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-publish"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf schedulePostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)restoreActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Restore", @"Label for restoring a trashed post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-restore"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf restorePostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)deleteActionBarItemWithInsets:(UIEdgeInsets)imageInsets
{
    __weak __typeof(self) weakSelf = self;
    PostCardActionBarItem *item = [self actionBarItemWithTitle:NSLocalizedString(@"Delete", @"Label for the delete post buton. Tapping permanently deletes a post.")
                                                         image:[UIImage imageNamed:@"icon-post-actionbar-trash"]
                                                   imageInsets:imageInsets
                                                   andCallback:^{
                                                       [weakSelf trashPostAction];
                                                   }];
    return item;
}

- (PostCardActionBarItem *)actionBarItemWithTitle:(NSString *)title
                                            image:(UIImage *)image
                                      imageInsets:(UIEdgeInsets)imageInsets
                                      andCallback:(PostCardActionBarItemCallback)callback
{
    PostCardActionBarItem *item = [PostCardActionBarItem itemWithTitle:title
                                                                 image:image
                                                      highlightedImage:nil];
    item.callback = callback;
    item.imageInsets = imageInsets;
    return item;
}

#pragma mark - Actions

- (void)editPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleEditPost:)]) {
        [self.delegate cell:self handleEditPost:self.post];
    }
}

- (void)viewPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleViewPost:)]) {
        [self.delegate cell:self handleViewPost:self.post];
    }
}

- (void)publishPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handlePublishPost:)]) {
        [self.delegate cell:self handlePublishPost:self.post];
    }
}

- (void)schedulePostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleSchedulePost:)]) {
        [self.delegate cell:self handleSchedulePost:self.post];
    }
}

- (void)trashPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleTrashPost:)]) {
        [self.delegate cell:self handleTrashPost:self.post];
    }
}

- (void)restorePostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleRestorePost:)]) {
        [self.delegate cell:self handleRestorePost:self.post];
    }
}

- (void)statsPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:handleStatsForPost:)]) {
        [self.delegate cell:self handleStatsForPost:self.post];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (previousTraitCollection.preferredContentSizeCategory != self.traitCollection.preferredContentSizeCategory) {
        [self applyStyles];
    }
}

@end
