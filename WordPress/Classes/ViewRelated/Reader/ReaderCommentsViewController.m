#import "ReaderCommentsViewController.h"

#import "Comment.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "InlineComposeView.h"
#import "ReaderCommentPublisher.h"
#import "ReaderCommentCell.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "WPAvatarSource.h"
#import "WPImageViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPTableImageSource.h"
#import "WPTableViewHandler.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

static CGFloat const SectionHeaderHeight = 25.0f;
static CGFloat const EstimatedCommentRowHeight = 150.0;
static CGFloat const CommentAvatarSize = 32.0;

static NSString *CommentDepth0CellIdentifier = @"CommentDepth0CellIdentifier";
static NSString *CommentDepth1CellIdentifier = @"CommentDepth1CellIdentifier";
static NSString *CommentDepth2CellIdentifier = @"CommentDepth2CellIdentifier";
static NSString *CommentDepth3CellIdentifier = @"CommentDepth3CellIdentifier";
static NSString *CommentDepth4CellIdentifier = @"CommentDepth4CellIdentifier";
static NSString *CommentLayoutCellIdentifier = @"CommentLayoutCellIdentifier";


@interface ReaderCommentsViewController () <ReaderCommentPublisherDelegate,
                                            ReaderCommentCellDelegate,
                                            WPContentSyncHelperDelegate,
                                            WPTableViewHandlerDelegate,
                                            NSFetchedResultsControllerDelegate>


@property (nonatomic, strong, readwrite) ReaderPost *post;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) InlineComposeView *inlineComposeView;
@property (nonatomic, strong) ReaderCommentPublisher *commentPublisher;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) ReaderCommentCell *cellForLayout;
@property (nonatomic, strong) NSLayoutConstraint *cellForLayoutWidthConstraint;

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

    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];

    if (self.tableViewHandler) {
        self.tableViewHandler.delegate = nil;
    }
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;

    [self configureCellForLayout];
    [self configureInfiniteScroll];
    [self configureTableView];
    [self configureNavbar];
    [self configureCommentPublisher];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self refreshAndSync];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.inlineComposeView dismissComposer];

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
    if ([self.tableView indexPathForSelectedRow] && self.inlineComposeView.isDisplayed) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
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


#pragma mark - Configuration

- (void)configureCellForLayout
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentLayoutCellIdentifier];
    self.cellForLayout = [self.tableView dequeueReusableCellWithIdentifier:CommentLayoutCellIdentifier];
    [self updateCellForLayoutWidthConstraint:CGRectGetWidth(self.tableView.bounds)];
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

- (void)configureTableView
{
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth0CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth1CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth2CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth3CellIdentifier];
    [self.tableView registerClass:[ReaderCommentCell class] forCellReuseIdentifier:CommentDepth4CellIdentifier];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)configureNavbar
{
    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
}

- (void)configureCommentPublisher
{
    self.inlineComposeView = [[InlineComposeView alloc] initWithFrame:CGRectZero];
    [self.inlineComposeView setButtonTitle:NSLocalizedString(@"Post", nil)];
    [self.view addSubview:self.inlineComposeView];

    // Comment composer responds to the inline compose view to publish comments
    self.commentPublisher = [[ReaderCommentPublisher alloc] initWithComposer:self.inlineComposeView];
    self.commentPublisher.delegate = self;
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
}


#pragma mark - Notification handlers

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    //deselect the selected comment if there is one
    NSArray *selection = [self.tableView indexPathsForSelectedRows];
    if ([selection count] > 0) {
        [self.tableView deselectRowAtIndexPath:[selection objectAtIndex:0] animated:YES];
    }
}


#pragma mark - Actions

- (void)dismissKeyboard:(id)sender
{
    if ([self.view.gestureRecognizers containsObject:self.tapOffKeyboardGesture]) {
        [self.view removeGestureRecognizer:self.tapOffKeyboardGesture];
    }

    [self.inlineComposeView dismissComposer];
}


#pragma mark - Sync methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(NSInteger))success failure:(void (^)(NSError *))failure
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service syncHierarchicalCommentsForPost:self.post page:1 success:success failure:failure];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(NSInteger))success failure:(void (^)(NSError *))failure
{
    [self.activityFooter startAnimating];

    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSInteger page = [service numberOfHierarchicalPagesSyncedforPost:self.post] + 1;
    [service syncHierarchicalCommentsForPost:self.post page:page success:success failure:failure];
}

- (void)syncContentEnded
{
    [self.activityFooter stopAnimating];
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

    [cell configureCell:comment];

    if ([cell isEqual:self.cellForLayout]) {
        return;
    }

    [self setAvatarForComment:comment forCell:cell indexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SectionHeaderHeight;
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


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    [self.tableView deselectRowAtIndexPath:[selectedRows objectAtIndex:0] animated:YES];

    if (self.inlineComposeView.isDisplayed) {
        [self.inlineComposeView dismissComposer];
    }
}


#pragma mark - ReaderCommentPublisherDelegate methods

- (void)commentPublisherDidPublishComment:(ReaderCommentPublisher *)composer
{
    [WPAnalytics track:WPAnalyticsStatReaderCommentedOnArticle];
    [self.inlineComposeView dismissComposer];

    // TODO: figure out which page of comments this falls under and sync that page.
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
    if (self.inlineComposeView.isDisplayed) {
        [self.inlineComposeView toggleComposer];
        return;
    }

    self.commentPublisher.post = self.post;
    self.commentPublisher.comment = comment;

    if ([self canComment]) {
        [self.view addGestureRecognizer:self.tapOffKeyboardGesture];

        [self.inlineComposeView displayComposer];
    }

    [self.tableView selectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:YES scrollPosition:UITableViewScrollPositionTop];
}


@end
