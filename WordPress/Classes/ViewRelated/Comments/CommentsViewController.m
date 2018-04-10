#import "CommentsViewController.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "Comment.h"
#import "Blog.h"

#import "WordPress-Swift.h"
#import "WPTableViewHandler.h"
#import "WPGUIConstants.h"
#import "UIView+Subviews.h"
#import "ContextManager.h"
#import <WordPressShared/WPNoResultsView.h>
#import <WordPressShared/WPStyleGuide.h>
#import <WordPressUI/WordPressUI.h>



static CGRect const CommentsActivityFooterFrame                 = {0.0, 0.0, 30.0, 30.0};
static CGFloat const CommentsActivityFooterHeight               = 50.0;
static NSInteger const CommentsRefreshRowPadding                = 4;
static NSInteger const CommentsFetchBatchSize                   = 10;

static NSString *CommentsReuseIdentifier                        = @"CommentsReuseIdentifier";
static NSString *CommentsLayoutIdentifier                       = @"CommentsLayoutIdentifier";


@interface CommentsViewController () <WPTableViewHandlerDelegate, WPContentSyncHelperDelegate>
@property (nonatomic, strong) WPTableViewHandler        *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper       *syncHelper;
@property (nonatomic, strong) WPNoResultsView           *noResultsView;
@property (nonatomic, strong) UIActivityIndicatorView   *footerActivityIndicator;
@property (nonatomic, strong) UIView                    *footerView;
@property (nonatomic, strong) NSCache                   *estimatedRowHeights;
@end

@implementation CommentsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _syncHelper.delegate = nil;
    _tableViewHandler.delegate = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationClass = [self class];
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.estimatedRowHeights = [[NSCache alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureNavBar];
    [self configureLoadMoreSpinner];
    [self configureNoResultsView];
    [self configureRefreshControl];
    [self configureSyncHelper];
    [self configureTableView];
    [self configureTableViewFooter];
    [self configureTableViewHandler];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
    [self.tableView deselectSelectedRowWithAnimation:YES];
    
    // Refresh the UI
    [self refreshNoResultsView];
    [self handleConnectionError];

    [self refreshAndSyncIfNeeded];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.tableViewHandler clearCachedRowHeights];
}


#pragma mark - Configuration

- (void)configureNavBar
{
    self.title = NSLocalizedString(@"Comments", @"Title for the Blog's Comments Section View");
}

- (void)configureLoadMoreSpinner
{
    // ContainerView
    CGFloat width                           = CGRectGetWidth(self.tableView.bounds);
    CGRect footerViewFrame                  = CGRectMake(0.0, 0.0, width, CommentsActivityFooterHeight);
    UIView *footerView                      = [[UIView alloc] initWithFrame:footerViewFrame];
    
    // Spinner
    UIActivityIndicatorView *indicator      = [[UIActivityIndicatorView alloc] initWithFrame:CommentsActivityFooterFrame];
    indicator.activityIndicatorViewStyle    = UIActivityIndicatorViewStyleGray;
    indicator.hidesWhenStopped              = YES;
    indicator.autoresizingMask              = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    indicator.center                        = footerView.center;
    [indicator stopAnimating];

    [footerView addSubview:indicator];

    // Keep References!
    self.footerActivityIndicator            = indicator;
    self.footerView                         = footerView;
}

- (void)configureNoResultsView
{
    WPNoResultsView *noResultsView          = [WPNoResultsView new];
    noResultsView.titleText                 = [self noResultsViewTitle];
    self.noResultsView                      = noResultsView;
    
    [self.view addSubview:noResultsView];
}

- (NSString *)noResultsViewTitle
{
    NSString *noCommentsMessage = NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
    NSString *noConnectionMessage = [self noConnectionMessage];

    return [ReachabilityUtils isInternetReachable] ? noCommentsMessage : noConnectionMessage;
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl        = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refreshAndSyncWithInteraction) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)configureSyncHelper
{
    WPContentSyncHelper *syncHelper         = [WPContentSyncHelper new];
    syncHelper.delegate                     = self;
    self.syncHelper                         = syncHelper;
}

- (void)configureTableView
{
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.accessibilityIdentifier  = @"Comments Table";

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    // Register the cells
    NSString *nibName   = [CommentsTableViewCell classNameWithoutNamespaces];
    UINib *nibInstance  = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:nibInstance forCellReuseIdentifier:CommentsReuseIdentifier];
}

- (void)configureTableViewFooter
{
    // Notes:
    //  -  Hide the cellSeparators, when the table is empty
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)configureTableViewHandler
{
    WPTableViewHandler *tableViewHandler    = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.delegate               = self;
    self.tableViewHandler                   = tableViewHandler;
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *cachedHeight = [self.estimatedRowHeights objectForKey:indexPath];
    if (cachedHeight.doubleValue) {
        return cachedHeight.doubleValue;
    }
    return WPTableViewDefaultRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentsTableViewCell *cell = (CommentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CommentsReuseIdentifier];
    NSAssert([cell isKindOfClass:[CommentsTableViewCell class]], nil);
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.estimatedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];

    // Refresh only when we reach the last 3 rows in the last section!
    NSInteger numberOfRowsInSection     = [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section];
    NSInteger lastSection               = [self.tableViewHandler numberOfSectionsInTableView:tableView] - 1;
    
    if ((indexPath.section == lastSection) && (indexPath.row + CommentsRefreshRowPadding >= numberOfRowsInSection)) {
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Failsafe: Make sure that the Comment (still) exists
    NSArray *sections = self.tableViewHandler.resultsController.sections;
    if (indexPath.section >= sections.count) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[indexPath.section];
    if (indexPath.row >= sectionInfo.numberOfObjects) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    // At last, push the details
    Comment *comment            = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    CommentViewController *vc   = [CommentViewController new];
    vc.comment                  = comment;
        
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Override WPTableViewHandler's default of UITableViewAutomaticDimension,
    // which results in 30pt tall headers on iOS 11
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - Comment Actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    NSMutableArray *actions = [NSMutableArray array];
    __typeof(self) __weak weakSelf = self;
    
    NSParameterAssert(comment);
    
    UITableViewRowAction *trash = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                     title:NSLocalizedString(@"Trash", @"Trashes a comment")
                                                                   handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                       [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                           [weakSelf deleteComment:comment];
                                                                       }];
                                                                   }];
    trash.backgroundColor = [WPStyleGuide errorRed];
    [actions addObject:trash];
    
    if (comment.isApproved) {
        UITableViewRowAction *unapprove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                             title:NSLocalizedString(@"Unapprove", @"Unapproves a Comment")
                                                                           handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                               [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                   [weakSelf unapproveComment:comment];
                                                                               }];
                                                                           }];
        
        unapprove.backgroundColor = [WPStyleGuide grey];
        [actions addObject:unapprove];
    } else {
        UITableViewRowAction *approve = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                           title:NSLocalizedString(@"Approve", @"Approves a Comment")
                                                                         handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                             [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                 [weakSelf approveComment:comment];
                                                                             }];
                                                                         }];
        
        approve.backgroundColor = [WPStyleGuide wordPressBlue];
        [actions addObject:approve];
    }
    
    return actions;
}

- (void)approveComment:(Comment *)comment
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
        
    [self.tableView setEditing:NO animated:YES];
    [service approveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"#### Error approving comment: %@", error);
    }];
}

- (void)unapproveComment:(Comment *)comment
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [self.tableView setEditing:NO animated:YES];
    [service unapproveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"#### Error unapproving comment: %@", error);
    }];
}

- (void)deleteComment:(Comment *)comment
{
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [self.tableView setEditing:NO animated:YES];
    [service deleteComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error deleting comment: %@", error);
    }];
}


#pragma mark - WPTableViewHandlerDelegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest            = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate                  = [NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, CommentStatusSpam];
    
    NSSortDescriptor *sortDescriptorStatus  = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate    = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors            = @[sortDescriptorStatus, sortDescriptorDate];
    fetchRequest.fetchBatchSize             = CommentsFetchBatchSize;
    
    return fetchRequest;
}

- (void)configureCell:(CommentsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(cell);
    NSParameterAssert(indexPath);
    
    Comment *comment    = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    
    cell.author         = comment.authorForDisplay;
    cell.approved       = [comment.status isEqualToString:CommentStatusApproved];
    cell.postTitle      = comment.titleForDisplay;
    cell.content        = comment.contentPreviewForDisplay;
    cell.timestamp      = [comment.dateCreated mediumString];
    
    // Don't download the gravatar, if it's the layout cell!
    if ([cell.reuseIdentifier isEqualToString:CommentsLayoutIdentifier]) {
        return;
    }
    
    if (comment.avatarURLForDisplay) {
        [cell downloadGravatarWithURL:comment.avatarURLForDisplay];
    } else {
        [cell downloadGravatarWithGravatarEmail:comment.gravatarEmailForDisplay];
    }
}

- (NSString *)entityName
{
    return NSStringFromClass([Comment class]);
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self refreshNoResultsView];
}

- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController popToViewController:self animated:YES];
}


#pragma mark - WPContentSyncHelper Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;

    __typeof(self) __weak weakSelf = self;

    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (!blogInContext) {
            return;
        }
        
        [commentService syncCommentsForBlog:blogInContext
                                    success:^(BOOL hasMore) {
                                        if (success) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                success(hasMore);
                                            });
                                        }
                                    }
                                    failure:^(NSError *error) {
                                        if (failure) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                failure(error);
                                            });
                                        }

                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [weakSelf refreshPullToRefresh];
                                        });
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [weakSelf handleConnectionError];
                                        });
                                    }];
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:self.blog.objectID error:nil];
        if (!blogInContext) {
            return;
        }
        
        [commentService loadMoreCommentsForBlog:blogInContext
                                        success:^(BOOL hasMore) {
                                                    if (success) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            success(hasMore);
                                                        });
                                                    }
                                        }
                                        failure:^(NSError *error) {
                                                if (failure) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        failure(error);
                                                    });
                                                }
                                        }];
    }];
    
    [self refreshInfiniteScroll];
}

- (void)syncContentEnded:(WPContentSyncHelper *)syncHelper
{
    [self refreshInfiniteScroll];
    [self refreshNoResultsView];
    [self refreshPullToRefresh];
}

- (BOOL)contentIsEmpty
{
    return [self.tableViewHandler.resultsController isEmpty];
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSyncWithInteraction
{
    [self.syncHelper syncContentWithUserInteraction];
}

- (void)refreshAndSyncIfNeeded
{
    if ([CommentService shouldRefreshCacheFor:self.blog]) {
        [self.syncHelper syncContent];
    }
}

- (void)refreshInfiniteScroll
{
    NSParameterAssert(self.footerView);
    NSParameterAssert(self.footerActivityIndicator);
    
    if (self.syncHelper.isSyncing) {
        self.tableView.tableFooterView = self.footerView;
        [self.footerActivityIndicator startAnimating];
    } else if (!self.syncHelper.hasMoreContent) {
        [self configureTableViewFooter];
    }
}

- (void)refreshPullToRefresh
{
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshNoResultsView
{
    BOOL isTableViewEmpty = [self contentIsEmpty];
    BOOL shouldPerformAnimation = self.noResultsView.hidden;
    
    self.noResultsView.hidden = !isTableViewEmpty;
    
    if (!isTableViewEmpty) {
        return;
    }
    
    // Display NoResultsView
    self.noResultsView.titleText = [self noResultsViewTitle];
    
    self.noResultsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView pinSubviewAtCenter:self.noResultsView];

    if (shouldPerformAnimation) {
        [self.noResultsView fadeInWithAnimation];
    }
}

@end
