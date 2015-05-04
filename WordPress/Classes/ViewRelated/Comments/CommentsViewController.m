#import "WPTableViewControllerSubclass.h"
#import "CommentsViewController.h"
#import "NewCommentsTableViewCell.h"
#import "CommentViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "UIColor+Helpers.h"
#import "WPTableViewSectionHeaderView.h"
#import "Comment.h"
#import "ContextManager.h"
#import "CommentService.h"

@interface CommentsViewController ()

@property (nonatomic,strong) NSIndexPath *currentIndexPath;
@property (nonatomic,assign) BOOL moreCommentsAvailable;
@end

@implementation CommentsViewController

CGFloat const CommentsStandardOffset = 16.0;
CGFloat const CommentsSectionHeaderHeight = 24.0;

- (void)dealloc
{
    DDLogMethod();
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)noResultsTitleText
{
    return NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
}

- (void)viewDidLoad
{
    DDLogMethod();

    [super viewDidLoad];
    self.moreCommentsAvailable = YES;
    self.infiniteScrollEnabled = YES;
    self.incrementalLoadingSupported = YES;
    self.title = NSLocalizedString(@"Comments", @"");
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    self.tableView.accessibilityLabel = @"Comments Table";       // required for UIAutomation for iOS 4
    if ([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
        self.tableView.accessibilityIdentifier = @"Comments Table";  // required for UIAutomation for iOS 5
    }

    self.editButtonItem.enabled = [[self.resultsController fetchedObjects] count] > 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod();

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    DDLogMethod();

    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Returning to the comments list while the reply-to keyboard is visible
    // messes with the bottom contentInset. Let's reset it just in case.
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 0;
    self.tableView.contentInset = contentInset;
}

- (void)configureCell:(NewCommentsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    cell.contentProvider = comment;
}

#pragma mark - DetailViewDelegate

- (void)resetView
{
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath: [self.tableView indexPathForSelectedRow] animated:NO];
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath
{
    DDLogMethodParam(indexPath);
    Comment *comment;
    if (indexPath) {
        @try {
            comment = [self.resultsController objectAtIndexPath:indexPath];
        }
        @catch (NSException * e) {
            DDLogInfo(@"Can't select comment at indexPath: (%i,%i)", indexPath.section, indexPath.row);
            DDLogInfo(@"sections: %@", self.resultsController.sections);
            DDLogInfo(@"results: %@", self.resultsController.fetchedObjects);
            comment = nil;
        }
    }

    if (comment) {
        self.currentIndexPath = indexPath;
        self.lastSelectedCommentID = comment.commentID; //store the latest user selection

        CommentViewController *vc = [CommentViewController new];
        vc.comment = comment;
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)setWantedCommentId:(NSNumber *)wantedCommentId
{
    if (![wantedCommentId isEqual:_wantedCommentId]) {
         _wantedCommentId = nil;
        if (wantedCommentId) {
            // First check if we already have the comment
            Comment *comment = [self commentWithId:wantedCommentId];
            if (comment) {
                NSIndexPath *wantedIndexPath = [self.resultsController indexPathForObject:comment];
                [self.tableView scrollToRowAtIndexPath:wantedIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                [self showCommentAtIndexPath:wantedIndexPath];
            } else {
                [self willChangeValueForKey:@"wantedCommentId"];
                _wantedCommentId = wantedCommentId;
                [self didChangeValueForKey:@"wantedCommentId"];
                [self syncItems];
            }
        }
    }
}

- (Comment *)commentWithId:(NSNumber *)commentId
{
    Comment *comment = [[[self.resultsController fetchedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"commentID = %@", commentId]] lastObject];

    return comment;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.resultsController objectAtIndexPath:indexPath];
    return [NewCommentsTableViewCell rowHeightForContentProvider:comment andWidth:WPTableViewFixedWidth];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showCommentAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - Subclass methods

- (NSString *)entityName
{
    return @"Comment";
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, @"spam"];
    NSSortDescriptor *sortDescriptorStatus = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorStatus, sortDescriptorDate];
    fetchRequest.fetchBatchSize = 10;
    return fetchRequest;
}

- (NSString *)sectionNameKeyPath
{
    return @"status";
}

- (Class)cellClass
{
    return [NewCommentsTableViewCell class];
}

- (void)syncItemsViaUserInteraction:(BOOL)userInteraction
                            success:(void (^)())success
                            failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (blogInContext) {
            [commentService syncCommentsForBlog:blogInContext success:^{
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success();
                    });
                }
            } failure:^(NSError *error) {
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure(error);
                    });
                }
            }];
        }
    }];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [super controllerDidChangeContent:controller];

    if ([[self.resultsController fetchedObjects] count] > 0) {
        self.editButtonItem.enabled = YES;
    } else {
        self.editButtonItem.enabled = NO;
        self.currentIndexPath = nil;
    }
}

#pragma mark - Syncs methods

- (BOOL)isSyncing
{
    return [CommentService isSyncingCommentsForBlog:self.blog];
}

- (NSDate *)lastSyncDate
{
    return self.blog.lastCommentsSync;
}

- (BOOL)hasMoreContent {
    return self.moreCommentsAvailable;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService loadMoreCommentsForBlog:self.blog success:^(BOOL hasMore) {
        self.moreCommentsAvailable = hasMore;
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}
@end
