#import "ReaderCommentsViewController.h"

#import "Comment.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderCommentCell.h"
#import "ReaderPost.h"
#import "ReaderPostHeaderView.h"
#import "UIAlertView+Blocks.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import "UIView+Subviews.h"
#import "WPAvatarSource.h"
#import "WPNoResultsView.h"
#import "WPImageViewController.h"
#import "WPTableViewHandler.h"
#import "WPToast.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

static CGFloat const EstimatedCommentRowHeight = 150.0;
static CGFloat const CommentAvatarSize = 32.0;
static CGFloat const PostHeaderHeight = 54.0;

static NSString *CommentDepth0CellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *CommentDepth1CellIdentifier = @"CommentDepth1CellIdentifier";
static NSString *CommentDepth2CellIdentifier = @"CommentDepth2CellIdentifier";
static NSString *CommentDepth3CellIdentifier = @"CommentDepth3CellIdentifier";
static NSString *CommentDepth4CellIdentifier = @"CommentDepth4CellIdentifier";
static NSString *CommentLayoutCellIdentifier = @"CommentLayoutCellIdentifier";


@interface ReaderCommentsViewController () <NSFetchedResultsControllerDelegate,
                                            ReaderCommentCellDelegate,
                                            UITextViewDelegate,
                                            WPContentSyncHelperDelegate,
                                            WPTableViewHandlerDelegate>

@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) ReaderCommentCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) ReplyTextView *replyTextView;
@property (nonatomic, strong) UIView *postHeader;

@end


@implementation ReaderCommentsViewController

#pragma mark - Static Helpers

+ (instancetype)controllerWithPost:(ReaderPost *)post
{
    ReaderCommentsViewController *controller = [[self alloc] init];
    controller.post = post;
    return controller;
}


#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];

    [self configureNavbar];
    [self configurePostHeader];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureCellForLayout];
    [self configureInfiniteScroll];
    [self configureTextReplyView];
    [self configureConstraints];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self refreshAndSync];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.replyTextView resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (IS_IPHONE) {
        // DTCoreText can be cranky about refreshing its rendered text when its
        // frame changes, even when setting its relayoutMask. Setting setNeedsLayout
        // on the cell prior to reloading seems to force the cell's
        // DTAttributedTextContentView to behave.
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            [cell setNeedsLayout];
        }
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    // Make sure a selected comment is visible after rotating.
    if ([self.tableView indexPathForSelectedRow] && self.replyTextView.isFirstResponder) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
    }

    [self configureNoResultsView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    // Refresh cached row heights based on the width for the new orientation.
    // Must happen before the table view calculates its content size / offset
    // for the new orientation.
    CGRect bounds = self.tableView.window.frame;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = MIN(width, height);
    } else {
        width = MAX(width, height);
    }
    [self updateCellForLayoutWidthConstraint:width];

    if (IS_IPHONE) {
        [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Remove the no results view or else the position will abruptly adjust after rotation
    // due to the table view sizing for image preloading
    [self.noResultsView removeFromSuperview];

    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#pragma mark - Configuration

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
}

- (void)configurePostHeader
{
    // Wrapper view
    UIView *headerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), PostHeaderHeight)];
    headerWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    headerWrapper.backgroundColor = [UIColor whiteColor];
    headerWrapper.clipsToBounds = YES;

    // Post header view
    ReaderPostHeaderView *headerView = [[ReaderPostHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), PostHeaderViewAvatarSize)];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.backgroundColor = [UIColor whiteColor];
    [headerView setTitle:[self.post titleForDisplay]];
    [headerView setSubtitle:NSLocalizedString(@"Comments on", @"Sentence fragment. The full phrase is 'Comments on' followed by the title of a post on a separate line.")];
    [headerWrapper addSubview:headerView];

    // Fetch the avatar
    CGSize imageSize = CGSizeMake(PostHeaderViewAvatarSize, PostHeaderViewAvatarSize);
    UIImage *image = [self.post cachedAvatarWithSize:imageSize];
    if (image) {
        [headerView setAvatarImage:image];
    } else {
        [self.post fetchAvatarWithSize:imageSize success:^(UIImage *image) {
            [headerView setAvatarImage:image];
        }];
    }

    // Border
    CGSize borderSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 1.0);
    UIImage *borderImage = [UIImage imageWithColor:[WPStyleGuide readGrey] havingSize:borderSize];
    UIImageView *borderView = [[UIImageView alloc] initWithImage:borderImage];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.contentMode = UIViewContentModeScaleAspectFill;
    [headerWrapper addSubview:borderView];

    // Layout
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, borderView);
    NSDictionary *metrics = @{@"margin":@12};
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(margin)-[headerView]-(margin)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(margin)-[headerView]-(>=1)-[borderView(1)]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[borderView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];

    self.postHeader = headerWrapper;;
    [self.view addSubview:self.postHeader];
}

- (void)configureTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth0CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth1CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth2CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth3CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth4CellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)configureTableViewHandler
{
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;
}

- (void)configureCellForLayout
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentLayoutCellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CommentLayoutCellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
}

- (void)configureInfiniteScroll
{
    if (self.syncHelper.hasMoreContent) {
        CGFloat width = CGRectGetWidth(self.tableView.bounds);
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 50.0f)];
        footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [footerView addSubview:self.activityFooter];
        self.tableView.tableFooterView = footerView;

    } else {
        self.tableView.tableFooterView = nil;
        self.activityFooter = nil;
    }
}

- (void)configureTextReplyView
{
    if (!self.post.commentsOpen) {
        return;
    }

    __typeof(self) __weak weakSelf = self;

    ReplyTextView *replyTextView = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.placeholder = NSLocalizedString(@"Write a reply…", @"Placeholder text for inline compose view");
    replyTextView.replyText = [NSLocalizedString(@"Reply", @"") uppercaseString];
    replyTextView.onReply = ^(NSString *content) {
        [weakSelf sendReplyWithNewContent:content];
    };
    replyTextView.delegate = self;
    self.replyTextView = replyTextView;

    [self.view addSubview:self.replyTextView];
    [self.view bringSubviewToFront:self.replyTextView];
}

- (void)configureNoResultsView
{
    if (!self.isViewLoaded) {
        return;
    }

    if (!self.noResultsView) {
        self.noResultsView = [[WPNoResultsView alloc] init];
    }

    if ([self.tableViewHandler.resultsController.fetchedObjects count] > 0) {
        [self.noResultsView removeFromSuperview];
        return;
    }

    // Refresh the NoResultsView Properties
    self.noResultsView.titleText = self.noResultsTitleText;

    // Only add and animate no results view if it isn't already
    // in the table view
    if (![self.noResultsView isDescendantOfView:self.tableView]) {
        [self.tableView addSubviewWithFadeAnimation:self.noResultsView];
    } else {
        [self.noResultsView centerInSuperview];
    }

    [self.tableView sendSubviewToBack:self.noResultsView];
}

- (NSString *)noResultsTitleText
{
    if (self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching comments...", @"A brief prompt shown when the comment list is empty, letting the user know the app is currently fetching new comments.");
    }

    return NSLocalizedString(@"Be the first to leave a commment.", @"Message shown encouraging the user to leave a comment on a post in the reader.");
}

- (void)configureConstraints
{
    NSMutableDictionary *views = [@{@"tableView": self.tableView,
                                    @"postHeader": self.postHeader,
                                    @"mainView": self.view} mutableCopy];

    NSDictionary *metrics = @{@"WPTableViewWidth": @(WPTableViewFixedWidth), @"headerHeight":@(PostHeaderHeight)};

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.postHeader
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    if (IS_IPAD) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[postHeader(WPTableViewWidth)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[postHeader(==mainView)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[postHeader(headerHeight)][tableView]"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];


    if (self.post.commentsOpen) {
        views[@"replyTextView"] = self.replyTextView;
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.replyTextView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0.0]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[tableView][replyTextView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];

        if (IS_IPAD) {
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[replyTextView(WPTableViewWidth)]"
                                                                              options:0
                                                                              metrics:metrics
                                                                                views:views]];
        } else {
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[replyTextView(==mainView)]"
                                                                              options:0
                                                                              metrics:metrics
                                                                                views:views]];
        }
    }
}

- (void)updateCellForLayoutWidthConstraint:(CGFloat)width
{
    UIView *contentView = self.cellForLayout.contentView;
    if (self.cellForLayoutWidthConstraint) {
        [contentView removeConstraint:self.cellForLayoutWidthConstraint];
    }
    NSDictionary *views = NSDictionaryOfVariableBindings(contentView);
    NSDictionary *metrics = @{@"width":@(width)};
    self.cellForLayoutWidthConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"[contentView(width)]"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views] firstObject];
    [contentView addConstraint:self.cellForLayoutWidthConstraint];
}

- (void)setAvatarForComment:(Comment *)comment forCell:(ReaderCommentCell *)cell indexPath:(NSIndexPath *)indexPath
{
    WPAvatarSource *source = [WPAvatarSource sharedSource];

    NSString *hash;
    CGSize size = CGSizeMake(CommentAvatarSize, CommentAvatarSize);
    NSURL *url = [comment avatarURLForDisplay];
    WPAvatarSourceType type = [source parseURL:url forAvatarHash:&hash];

    UIImage *image = [source cachedImageForAvatarHash:hash ofType:type withSize:size];
    if (image) {
        [cell setAvatarImage:image];
        return;
    }

    [cell setAvatarImage:[UIImage imageNamed:@"default-identicon"]];
    if (hash) {
        [source fetchImageForAvatarHash:hash ofType:type withSize:size success:^(UIImage *image) {
            if (cell == [self.tableView cellForRowAtIndexPath:indexPath]) {
                [cell setAvatarImage:image];
            }
        }];
    }
}


#pragma mark - Accessor methods

- (void)setPost:(ReaderPost *)post
{
    if (post == _post) {
        return;
    }

    _post = post;

    if (_post.isWPCom) {
        self.syncHelper = [[WPContentSyncHelper alloc] init];
        self.syncHelper.delegate = self;
    }

    if([self isViewLoaded]) {
        [self configureInfiniteScroll];
    }
}

- (UIActivityIndicatorView *)activityFooter
{
    if (_activityFooter) {
        return _activityFooter;
    }

    CGRect rect = CGRectMake(145.0f, 10.0f, 30.0f, 30.0f);
    _activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    _activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _activityFooter.hidesWhenStopped = YES;
    _activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [_activityFooter stopAnimating];

    return _activityFooter;
}

- (BOOL)canComment
{
    return self.post.commentsOpen;
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSync
{
    self.title = self.post.postTitle ?: NSLocalizedString(@"Reader", @"Placeholder title for ReaderPostDetails.");

    // Refresh incase the post needed to be fetched.
    [self.tableView reloadData];

    [self.syncHelper syncContent];

    [self configureNoResultsView];
}


#pragma mark - Notification handlers

- (void)handleKeyboardWillShow:(NSNotification *)notification
{
    NSDictionary* userInfo = notification.userInfo;

    // Convert the rect to view coordinates: enforce the current orientation!
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];

    // Bottom Inset: Consider the tab bar!
    CGRect viewFrame = self.view.frame;
    CGFloat bottomInset = CGRectGetHeight(kbRect) - (CGRectGetMaxY(kbRect) - CGRectGetHeight(viewFrame));

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [self.view updateConstraintWithFirstItem:self.view
                                  secondItem:self.replyTextView
                          firstItemAttribute:NSLayoutAttributeBottom
                         secondItemAttribute:NSLayoutAttributeBottom
                                    constant:bottomInset];

    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    //deselect the selected comment if there is one
    NSArray *selection = [self.tableView indexPathsForSelectedRows];
    if ([selection count] > 0) {
        [self.tableView deselectRowAtIndexPath:[selection objectAtIndex:0] animated:YES];
    }




    NSDictionary* userInfo = notification.userInfo;

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [self.view updateConstraintWithFirstItem:self.view
                                  secondItem:self.replyTextView
                          firstItemAttribute:NSLayoutAttributeBottom
                         secondItemAttribute:NSLayoutAttributeBottom
                                    constant:0];

    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}


#pragma mark - Actions

- (void)tapRecognized:(id)sender
{
    if ([self.view.gestureRecognizers containsObject:self.tapOffKeyboardGesture]) {
        [self.view removeGestureRecognizer:self.tapOffKeyboardGesture];
    }

    [self.tableView deselectSelectedRowWithAnimation:YES];
    [self.replyTextView resignFirstResponder];
}

- (void)sendReplyWithNewContent:(NSString *)content
{
    NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
    NSString *sendingMessage = NSLocalizedString(@"Sending...", @"The app is uploading a comment");
    UIImage *successImage = [UIImage imageNamed:@"action-icon-success"];
    UIImage *sendingImage = [UIImage imageNamed:@"action-icon-replied"];

    __typeof(self) __weak weakSelf = self;

    void (^successBlock)() = ^void() {
        [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
        [WPToast showToastWithMessage:successMessage andImage:successImage];
        [weakSelf refreshAndSync];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        DDLogError(@"Error sending reply: %@", error);
        [UIAlertView showWithTitle:nil
                           message:NSLocalizedString(@"There has been an unexpected error while sending your reply", nil)
                 cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
                 otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  [weakSelf sendReplyWithNewContent:content];
                              }
                          }];
    };

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath) {
        Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
        [service replyToCommentWithID:comment.commentID
                               siteID:self.post.siteID
                              content:content
                              success:successBlock
                              failure:failureBlock];
    } else {
        [service replyToPostWithID:self.post.postID
                            siteID:self.post.siteID
                           content:content
                           success:successBlock
                           failure:failureBlock];
    }

    [WPToast showToastWithMessage:sendingMessage andImage:sendingImage];
}


#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:success failure:failure];
    [self configureNoResultsView];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(NSInteger, BOOL))success failure:(void (^)(NSError *))failure
{
    [self.activityFooter startAnimating];

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:success failure:failure];
}

- (void)syncContentEnded
{
    [self.activityFooter stopAnimating];
    [self configureNoResultsView];
}


#pragma mark - UITableView Delegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSString *)entityName
{
    return NSStringFromClass([Comment class]);
}

- (NSFetchRequest *)fetchRequest
{
    if (!self.post) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"post = %@", self.post];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"hierarchy" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    return fetchRequest;
}

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)indexPath
{
    ReaderCommentCell *cell = (ReaderCommentCell *)aCell;
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    if (comment.depth > 0 && indexPath.row > 0) {
        NSIndexPath *previousPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        Comment *previousComment = [self.tableViewHandler.resultsController objectAtIndexPath:previousPath];
        if (previousComment.depth < comment.depth) {
            cell.isFirstNestedComment = YES;
        }
    }

    if (indexPath.row < [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
        NSIndexPath *nextPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        Comment *nextComment = [self.tableViewHandler.resultsController objectAtIndexPath:nextPath];
        if ([nextComment.depth integerValue] == 0) {
            cell.needsExtraPadding = YES;
        }
    }

    if (indexPath.row == 0) {
        cell.hidesBorder = YES;
    }

    [cell configureCell:comment];

    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    [self setAvatarForComment:comment forCell:cell indexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return EstimatedCommentRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    [self configureCell:self.cellForLayout atIndexPath:indexPath];
    CGSize size = [self.cellForLayout sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = (Comment *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    NSInteger depth = [comment.depth integerValue];

    NSString *cellIdentifier;

    switch (depth) {
        case 0:
            cellIdentifier = CommentDepth0CellIdentifier;
            break;
        case 1:
            cellIdentifier = CommentDepth1CellIdentifier;
            break;
        case 2:
            cellIdentifier = CommentDepth2CellIdentifier;
            break;
        case 3:
            cellIdentifier = CommentDepth3CellIdentifier;
            break;
        default:
            cellIdentifier = CommentDepth4CellIdentifier;
    }

    ReaderCommentCell *cell = (ReaderCommentCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == [self.tableViewHandler numberOfSectionsInTableView:tableView]) &&
        (indexPath.row + 4 >= [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self configureNoResultsView];
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    [self.tableView deselectRowAtIndexPath:[selectedRows objectAtIndex:0] animated:YES];

    [self.replyTextView resignFirstResponder];
}


#pragma mark - ReaderCommentCell Delegate methods

- (void)commentCell:(UITableViewCell *)cell linkTapped:(NSURL *)url
{
    WPWebViewController *controller = [[WPWebViewController alloc] init];
    [controller setUrl:url];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)commentCell:(UITableViewCell *)cell replyToComment:(Comment *)comment
{
    // if a row is already selected don't allow selection of another
    if (self.replyTextView.isFirstResponder) {
        [self.replyTextView resignFirstResponder];
        return;
    }

    if (![self canComment]) {
        return;
    }


    [self.replyTextView becomeFirstResponder];

    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)commentCell:(ReaderCommentCell *)cell toggleLikeStatusForComment:(Comment *)comment
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    [commentService toggleLikeStatusForComment:comment siteID:self.post.siteID success:nil failure:nil];
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];
    return YES;
}

@end
