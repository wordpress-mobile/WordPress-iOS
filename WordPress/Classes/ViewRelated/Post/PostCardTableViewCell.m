#import "PostCardTableViewCell.h"
#import <AFNetworking/UIKit+AFNetworking.h>
#import "BasePost.h"
#import "PhotonImageURLHelper.h"
#import "PostCardActionBar.h"
#import "PostCardActionBarItem.h"
#import "UIImageView+Gravatar.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WPStyleGuide+Posts.h"
#import "Wordpress-Swift.h"

static const UIEdgeInsets ActionbarButtonImageInsets = {0.0, 0.0, 0.0, 4.0};

typedef NS_ENUM(NSUInteger, ActionBarMode) {
    ActionBarModePublish = 1,
    ActionBarModeDraft,
    ActionBarModeTrash,
};


@interface PostCardTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *innerContentView;
@property (nonatomic, strong) IBOutlet UIView *shadowView;
@property (nonatomic, strong) IBOutlet UIView *postContentView;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *authorBlogLabel;
@property (nonatomic, strong) IBOutlet UILabel *authorNameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *postCardImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *snippetLabel;
@property (nonatomic, strong) IBOutlet UIView *dateView;
@property (nonatomic, strong) IBOutlet UIImageView *dateImageView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UIImageView *statusImageView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIView *metaView;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonRight;
@property (nonatomic, strong) IBOutlet UIButton *metaButtonLeft;
@property (nonatomic, strong) IBOutlet PostCardActionBar *actionBar;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewLeftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headerViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *snippetLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dateViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *statusViewLowerConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postContentBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *maxIPadWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postCardImageViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *postCardImageViewHeightConstraint;

@property (nonatomic, weak) id<WPPostContentViewProvider>contentProvider;
@property (nonatomic) CGFloat headerViewHeight;
@property (nonatomic) CGFloat headerViewLowerMargin;
@property (nonatomic) CGFloat titleViewLowerMargin;
@property (nonatomic) CGFloat snippetViewLowerMargin;
@property (nonatomic) CGFloat dateViewLowerMargin;
@property (nonatomic) CGFloat statusViewHeight;
@property (nonatomic) CGFloat statusViewLowerMargin;
@property (nonatomic) BOOL configureForLayoutOnly;
@property (nonatomic) BOOL didPreserveStartingConstraintConstants;
@property (nonatomic) ActionBarMode currentActionBarMode;

@end

@implementation PostCardTableViewCell

@synthesize delegate;

#pragma mark - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self applyStyles];
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
    if (self.contentProvider) {
        [self configureCell:self.contentProvider layoutOnly:self.configureForLayoutOnly];
    }
}

#pragma mark - Accessors

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat innerWidth = [self innerWidthForSize:size];
    CGSize innerSize = CGSizeMake(innerWidth, CGFLOAT_MAX);

    // Add up all the things.
    CGFloat height = CGRectGetMinY(self.postContentView.frame);

    height += CGRectGetMinY(self.headerView.frame);
    if (self.headerViewHeightConstraint.constant > 0) {
        height += self.headerViewHeight;
        height += self.headerViewLowerMargin;
    }

    if (self.postCardImageView) {
        // the image cell xib
        height += self.postCardImageViewHeightConstraint.constant;
        height += self.postCardImageViewBottomConstraint.constant;
    }

    height += [self.titleLabel sizeThatFits:innerSize].height;
    height += self.titleLowerConstraint.constant;

    height += [self.snippetLabel sizeThatFits:innerSize].height;
    height += self.snippetLowerConstraint.constant;

    height += CGRectGetHeight(self.dateView.frame);
    height += self.dateViewLowerConstraint.constant;

    height += self.statusHeightConstraint.constant;
    height += self.statusViewLowerConstraint.constant;

    height += CGRectGetHeight(self.actionBar.frame);

    height += self.postContentBottomConstraint.constant;

    return CGSizeMake(size.width, height);
}

- (CGFloat)innerWidthForSize:(CGSize)size
{
    CGFloat width = 0.0;
    CGFloat horizontalMargin = self.headerViewLeftConstraint.constant;
    // FIXME: Ideally we'd check `self.maxIPadWidthConstraint.isActive` but that
    // property is iOS 8 only. When iOS 7 support is ended update this and check
    // the constraint. 
    if ([UIDevice isPad] && size.width >= self.maxIPadWidthConstraint.constant) {
        width = self.maxIPadWidthConstraint.constant;
    } else {
        width = size.width;
        horizontalMargin += CGRectGetMinX(self.postContentView.frame);
    }
    width -= (horizontalMargin * 2);
    return width;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.innerContentView.backgroundColor = backgroundColor;
}

- (id<WPPostContentViewProvider>)providerOrRevision
{
    return [self.contentProvider hasRevision] ? [self.contentProvider revision] : self.contentProvider;
}

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
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.shadowView.hidden = highlighted;
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
    [WPStyleGuide applyPostStatusStyle:self.statusLabel];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonRight];
    [WPStyleGuide applyPostMetaButtonStyle:self.metaButtonLeft];
    self.actionBar.backgroundColor = [WPStyleGuide lightGrey];
    self.shadowView.backgroundColor = [WPStyleGuide postCardBorderColor];
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    [self configureCell:contentProvider layoutOnly:NO];
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider layoutOnly:(BOOL)layoutOnly
{
    self.configureForLayoutOnly = layoutOnly;
    self.contentProvider = contentProvider;

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
    [self configureActionBar];

    [self setNeedsUpdateConstraints];
}

- (void)configureHeader
{
    if (![self.contentProvider isMultiAuthorBlog]) {
        self.headerViewHeightConstraint.constant = 0;
        self.headerViewLowerConstraint.constant = 0;
        // If not visible, just return and don't bother setting the text or loading the avatar.
        self.headerView.hidden = YES;
        return;
    }
    self.headerView.hidden = NO;
    self.headerViewHeightConstraint.constant = self.headerViewHeight;
    self.headerViewLowerConstraint.constant = self.headerViewLowerMargin;

    // No need to worry about text or image when configuring only layout
    if (self.configureForLayoutOnly) {
        return;
    }

    self.authorBlogLabel.text = [self.contentProvider blogNameForDisplay];
    self.authorNameLabel.text = [self.contentProvider authorNameForDisplay];
    UIImage *placeholder = [UIImage imageNamed:@"post-blavatar-placeholder"];

    [self.avatarImageView setImageWithSiteIcon:[self.contentProvider blavatarForDisplay] placeholderImage:placeholder];
}

- (void)configureCardImage
{
    if (self.configureForLayoutOnly) {
        return;
    }

    if (!self.postCardImageView) {
        return;
    }

    id<WPPostContentViewProvider>provider = [self providerOrRevision];
    if (![provider featuredImageURLForDisplay]) {
        self.postCardImageView.image = nil;
    }

    NSURL *url = [provider featuredImageURLForDisplay];
    // if not private create photon url
    if (![provider isPrivate]) {
        CGSize imageSize = self.postCardImageView.frame.size;
        url = [PhotonImageURLHelper photonURLWithSize:imageSize forImageURL:url];
    }

    self.postCardImageView.image = nil; // Clear the image so we know its not stale.
    [self.postCardImageView setImageWithURL:url placeholderImage:nil];
}

- (void)configureTitle
{
    id<WPPostContentViewProvider>provider = [self providerOrRevision];
    NSString *str = [provider titleForDisplay] ?: [NSString string];
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardTitleAttributes]];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLowerConstraint.constant = ([str length] > 0) ? self.titleViewLowerMargin : 0.0;
}

- (void)configureSnippet
{
    id<WPPostContentViewProvider>provider = [self providerOrRevision];
    NSString *str = [provider contentPreviewForDisplay] ?: [NSString string];
    self.snippetLabel.attributedText = [[NSAttributedString alloc] initWithString:str attributes:[WPStyleGuide postCardSnippetAttributes]];
    self.snippetLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.snippetLowerConstraint.constant = ([str length] > 0) ? self.snippetViewLowerMargin : 0.0;
}

- (void)configureDate
{
    id<WPPostContentViewProvider>provider = [self providerOrRevision];
    self.dateLabel.text = [provider dateStringForDisplay];
}

- (void)configureStatusView
{
    NSString *str = [self.contentProvider statusForDisplay];
    self.statusView.hidden = ([str length] == 0);
    if (self.statusView.hidden) {
        self.dateViewLowerConstraint.constant = 0.0;
        self.statusHeightConstraint.constant = 0.0;
    } else {
        self.dateViewLowerConstraint.constant = self.dateViewLowerMargin;
        self.statusHeightConstraint.constant = self.statusViewHeight;
    }

    self.statusLabel.text = str;
    // Set the correct icon and text color
    if ([[self.contentProvider status] isEqualToString:PostStatusPending]) {
        self.statusImageView.image = [UIImage imageNamed:@"icon-post-status-pending"];
        self.statusLabel.textColor = [WPStyleGuide jazzyOrange];
    } else if ([[self.contentProvider status] isEqualToString:PostStatusScheduled]) {
        self.statusImageView.image = [UIImage imageNamed:@"icon-post-status-scheduled"];
        self.statusLabel.textColor = [WPStyleGuide wordPressBlue];
    } else if ([[self.contentProvider status] isEqualToString:PostStatusTrash]) {
        self.statusImageView.image = [UIImage imageNamed:@"icon-post-status-trashed"];
        self.statusLabel.textColor = [WPStyleGuide errorRed];
    } else if (!self.statusView.hidden) {
        self.statusImageView.image = [UIImage imageNamed:@"icon-post-status-pending"];
        self.statusLabel.textColor = [WPStyleGuide jazzyOrange];
    } else {
        self.statusLabel.text = nil;
        self.statusImageView.image = nil;
        self.statusLabel.textColor = [WPStyleGuide grey];
    }

    [self.statusView setNeedsUpdateConstraints];
}


#pragma mark - Configure Meta

- (void)configureMetaButtons
{
    if (self.configureForLayoutOnly) {
        return;
    }

    [self resetMetaButton:self.metaButtonRight];
    [self resetMetaButton:self.metaButtonLeft];

    NSMutableArray *mButtons = [NSMutableArray arrayWithObjects:self.metaButtonLeft, self.metaButtonRight, nil];
    if ([self.contentProvider numberOfComments] > 0) {
        UIButton *button = [mButtons lastObject];
        [mButtons removeLastObject];
        NSString *title = [NSString stringWithFormat:@"%d", [self.contentProvider numberOfComments]];
        [self configureMetaButton:button withTitle:title andImage:[UIImage imageNamed:@"icon-postmeta-comment"]];
    }

    if ([self.contentProvider numberOfLikes] > 0) {
        UIButton *button = [mButtons lastObject];
        [mButtons removeLastObject];
        NSString *title = [NSString stringWithFormat:@"%d", [self.contentProvider numberOfLikes]];
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


#pragma mark - Configure Actionbar

- (void)configureActionBar
{
    if (self.configureForLayoutOnly) {
        return;
    }

    NSString *status = [self.contentProvider status];
    if ([status isEqualToString:PostStatusPublish] || [status isEqualToString:PostStatusPrivate]) {
        [self configurePublishedActionBar];
    } else if ([status isEqualToString:PostStatusTrash]) {
        // trashed
        [self configureTrashedActionBar];
    } else {
        // anything else (draft, pending, scheduled, something custom) treat as draft
        [self configureDraftActionBar];
    }
}

- (void)configurePublishedActionBar
{
    if (self.currentActionBarMode == ActionBarModePublish) {
        return;
    }
    self.currentActionBarMode = ActionBarModePublish;

    __weak __typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray array];
    PostCardActionBarItem *item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Edit", @"Label for the edit post button. Tapping displays the editor.")
                                                                 image:[UIImage imageNamed:@"icon-post-actionbar-edit"]
                                                      highlightedImage:nil];
    item.callback = ^{
        [weakSelf editPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"View", @"Label for the view post button. Tapping displays the post as it appears on the web.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-view"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf viewPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    if ([self.contentProvider supportsStats]) {
        item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Stats", @"Label for the view stats button. Tapping displays statistics for a post.")
                                              image:[UIImage imageNamed:@"icon-post-actionbar-stats"]
                                   highlightedImage:nil];
        item.callback = ^{
            [weakSelf statsPostAction];
        };
        item.imageInsets = ActionbarButtonImageInsets;
        [items addObject:item];
    }

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Trash", @"Label for the trash post button. Tapping moves a post to the trash bin.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-trash"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf trashPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    [self.actionBar setItems:items];
}

- (void)configureDraftActionBar
{
    if (self.currentActionBarMode == ActionBarModeDraft) {
        return;
    }
    self.currentActionBarMode = ActionBarModeDraft;

    __weak __typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray array];
    PostCardActionBarItem *item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Edit", @"Label for the edit post button. Tapping displays the editor.")
                                                                 image:[UIImage imageNamed:@"icon-post-actionbar-edit"]
                                                      highlightedImage:nil];
    item.callback = ^{
        [weakSelf editPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Preview", @"Label for the preview post button. Tapping shows a preview of the post.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-view"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf viewPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Publish", @"Label for the publish button. Tapping publishes a draft post.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-publish"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf publishPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Trash", @"Label for the trash post button. Tapping moves a post to the trash bin.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-trash"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf trashPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    [self.actionBar setItems:items];
}

- (void)configureTrashedActionBar
{
    if (self.currentActionBarMode == ActionBarModeTrash) {
        return;
    }
    self.currentActionBarMode = ActionBarModeTrash;

    __weak __typeof(self) weakSelf = self;
    NSMutableArray *items = [NSMutableArray array];
    PostCardActionBarItem *item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Restore", @"Label for restoring a trashed post.")
                                                                 image:[UIImage imageNamed:@"icon-post-actionbar-restore"]
                                                      highlightedImage:nil];
    item.callback = ^{
        [weakSelf restorePostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    item = [PostCardActionBarItem itemWithTitle:NSLocalizedString(@"Delete", @"Label for the delete post buton. Tapping permanently deletes a post.")
                                          image:[UIImage imageNamed:@"icon-post-actionbar-trash"]
                               highlightedImage:nil];
    item.callback = ^{
        [weakSelf trashPostAction];
    };
    item.imageInsets = ActionbarButtonImageInsets;
    [items addObject:item];

    [self.actionBar setItems:items];
}


#pragma mark - Actions

- (void)editPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedEditActionForProvider:)]) {
        [self.delegate cell:self receivedEditActionForProvider:self.contentProvider];
    }
}

- (void)viewPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedViewActionForProvider:)]) {
        [self.delegate cell:self receivedViewActionForProvider:self.contentProvider];
    }
}

- (void)publishPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedPublishActionForProvider:)]) {
        [self.delegate cell:self receivedPublishActionForProvider:self.contentProvider];
    }
}

- (void)trashPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedTrashActionForProvider:)]) {
        [self.delegate cell:self receivedTrashActionForProvider:self.contentProvider];
    }
}

- (void)restorePostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedRestoreActionForProvider:)]) {
        [self.delegate cell:self receivedRestoreActionForProvider:self.contentProvider];
    }
}

- (void)statsPostAction
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedStatsActionForProvider:)]) {
        [self.delegate cell:self receivedStatsActionForProvider:self.contentProvider];
    }
}

@end
