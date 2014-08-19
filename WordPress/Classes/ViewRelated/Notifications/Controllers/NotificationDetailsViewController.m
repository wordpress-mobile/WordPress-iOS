#import "NotificationDetailsViewController.h"

#import "WordPressAppDelegate.h"
#import <Simperium/Simperium.h>

#import "Blog.h"
#import "Notification.h"

#import "ContextManager.h"

#import "BlogService.h"
#import "CommentService.h"
#import "ReaderSiteService.h"

#import "WPWebViewController.h"
#import "ReaderPostDetailViewController.h"
#import "StatsViewController.h"

#import "WordPress-Swift.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"
#import "UIActionSheet+Helpers.h"
#import "UIAlertView+Blocks.h"
#import "NSObject+Helpers.h"



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSUInteger NotificationDetailSectionsCount   = 1;

static UIEdgeInsets NotificationTableInsetsPhone    = {0.0f,  0.0f, 20.0f, 0.0f};
static UIEdgeInsets NotificationTableInsetsPad      = {40.0f, 0.0f, 20.0f, 0.0f};


#pragma mark ==========================================================================================
#pragma mark Private
#pragma mark ==========================================================================================

@interface NotificationDetailsViewController () <SPBucketDelegate>
@property (nonatomic, strong) NSDictionary *layoutCellMap;
@property (nonatomic, strong) NSDictionary *reuseIdentifierMap;
@end


#pragma mark ==========================================================================================
#pragma mark NotificationDetailsViewController
#pragma mark ==========================================================================================

@implementation NotificationDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title                      = NSLocalizedString(@"Details", @"Notification Details Section Title");
    self.restorationClass           = [self class];
    
    self.tableView.contentInset     = IS_IPAD ? NotificationTableInsetsPad : NotificationTableInsetsPhone;
    self.tableView.backgroundColor  = [WPStyleGuide itsEverywhereGrey];

    self.reuseIdentifierMap = @{
        @(NoteBlockTypesText)       : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockTypesComment)    : NoteBlockCommentTableViewCell.reuseIdentifier,
        @(NoteBlockTypesQuote)      : NoteBlockQuoteTableViewCell.reuseIdentifier,
        @(NoteBlockTypesImage)      : NoteBlockImageTableViewCell.reuseIdentifier,
        @(NoteBlockTypesUser)       : NoteBlockUserTableViewCell.reuseIdentifier
    };
    
    Simperium *simperium            = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    SPBucket *notificationsBucket   = [simperium bucketForName:NSStringFromClass([Notification class])];
    notificationsBucket.delegate    = self;
}


#pragma mark - Autolayout Helpers

- (NSDictionary *)layoutCellMap
{
    if (_layoutCellMap) {
        return _layoutCellMap;
    }
    
    NSString *storyboardID  = NSStringFromClass([self class]);
    NotificationDetailsViewController *detailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:storyboardID];
    
    UITableView *tableView  = detailsViewController.tableView;
    
    _layoutCellMap = @{
        @(NoteBlockTypesText)       : [tableView dequeueReusableCellWithIdentifier:NoteBlockTextTableViewCell.reuseIdentifier],
        @(NoteBlockTypesComment)    : [tableView dequeueReusableCellWithIdentifier:NoteBlockCommentTableViewCell.reuseIdentifier],
        @(NoteBlockTypesQuote)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockQuoteTableViewCell.reuseIdentifier],
        @(NoteBlockTypesImage)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockImageTableViewCell.reuseIdentifier],
        @(NoteBlockTypesUser)       : [tableView dequeueReusableCellWithIdentifier:NoteBlockUserTableViewCell.reuseIdentifier]
    };
    
    return _layoutCellMap;
}


#pragma mark - SPBucketDeltage Methods

- (void)bucket:(SPBucket *)bucket didChangeObjectForKey:(NSString *)key forChangeType:(SPBucketChangeType)changeType memberNames:(NSArray *)memberNames
{
    // Reload the table, if *our* notification got updated
    if ([self.note.simperiumKey isEqualToString:key]) {
        [self.tableView reloadData];
    }
}


#pragma mark - UIViewController Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSString *noteID = [coder decodeObjectForKey:NSStringFromClass([Notification class])];
    if (!noteID) {
        return nil;
    }
    
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:noteID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    Notification *restoredNotification = (Notification *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredNotification) {
        return nil;
    }
    
    UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
    if (!storyboard) {
        return nil;
    }
    
    NotificationDetailsViewController *vc   = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.restorationIdentifier                = [identifierComponents lastObject];
    vc.restorationClass                     = [NotificationDetailsViewController class];
    vc.note                                 = restoredNotification;
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *noteIdKey = NSStringFromClass([Notification class]);
    [coder encodeObject:[self.note.objectID.URIRepresentation absoluteString] forKey:noteIdKey];
    [super encodeRestorableStateWithCoder:coder];
}


#pragma mark - Helpers

- (NotificationBlock *)blockForIndexPath:(NSIndexPath *)indexPath
{
    return self.note.bodyBlocks[indexPath.row];
}


#pragma mark - UITableViewDelegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    /**
        Note
        This is a workaround. iOS 7 + grouped cells result in an extra top spacing.
        Ref.: http://stackoverflow.com/questions/17699831/how-to-change-height-of-grouped-uitableview-header
     */
    
    return CGFLOAT_MIN;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return NotificationDetailSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.note.bodyBlocks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block                = [self blockForIndexPath:indexPath];
    NoteBlockTableViewCell *tableViewCell   = self.layoutCellMap[@(block.type)] ?: self.layoutCellMap[@(NoteBlockTypesText)];
    
    [self setupCell:tableViewCell block:block];

    CGFloat height = [tableViewCell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block        = [self blockForIndexPath:indexPath];
    NSString *reuseIdentifier       = self.reuseIdentifierMap[@(block.type)] ?: self.reuseIdentifierMap[@(NoteBlockTypesText)];
    NoteBlockTableViewCell *cell    = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self setupCell:cell block:block];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block = [self blockForIndexPath:indexPath];
    
    // When tapping a User's cell, let's push the associated blog. If any!
    if (block.type == NoteBlockTypesUser) {
        NSURL *linkHome = [NSURL URLWithString:block.metaLinksHome];
        [self openURL:linkHome];
    }
}


#pragma mark - NoteBlockTableViewCell Helpers

- (void)setupCell:(NoteBlockTableViewCell *)cell block:(NotificationBlock *)block
{
    // Note: This is gonna look awesome in Swift
    if (block.type == NoteBlockTypesUser) {
        [self setupUserCell:(NoteBlockUserTableViewCell *)cell block:block];
        
    } else if (block.type == NoteBlockTypesQuote) {
        [self setupQuoteCell:(NoteBlockQuoteTableViewCell *)cell block:block];
        
    } else if (block.type == NoteBlockTypesComment){
        [self setupCommentCell:(NoteBlockCommentTableViewCell *)cell block:block];
        
    } else if (block.type == NoteBlockTypesImage) {
        [self setupImageCell:(NoteBlockImageTableViewCell *)cell block:block];
        
    } else {
        [self setupTextCell:(NoteBlockTextTableViewCell *)cell block:block];
    }
}

- (void)setupUserCell:(NoteBlockUserTableViewCell *)cell block:(NotificationBlock *)block
{
    NotificationMedia *media        = [block.media firstObject];
    
    cell.name                       = block.text;
    cell.blogTitle                  = block.metaTitlesHome;
    
#warning TODO: Implement Follow
    
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell block:(NotificationBlock *)block
{
    __weak __typeof(self) weakSelf  = self;
    
    cell.isLikeEnabled              = [block isActionEnabled:NoteActionLikeKey];
    cell.isApproveEnabled           = [block isActionEnabled:NoteActionApproveKey];
    cell.isTrashEnabled             = [block isActionEnabled:NoteActionTrashKey];
    cell.isMoreEnabled              = [block isActionEnabled:NoteActionApproveKey];

    cell.isLikeOn                   = [block isActionOn:NoteActionLikeKey];
    cell.isApproveOn                = [block isActionOn:NoteActionApproveKey];
    
    cell.attributedText             = block.attributedTextRegular;

    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
    
    cell.onLikeClick                = ^(){
        [weakSelf likeCommentWithBlock:block];
    };
    
    cell.onUnlikeClick              = ^(){
        [weakSelf unlikeCommentWithBlock:block];
    };
    
    cell.onApproveClick             = ^(){
        [weakSelf approveCommentWithBlock:block];
    };

    cell.onUnapproveClick             = ^(){
        [weakSelf unapproveCommentWithBlock:block];
    };
    
    cell.onTrashClick               = ^(){
        [weakSelf trashCommentWithBlock:block];
    };
    
    cell.onMoreClick                = ^(){
        [weakSelf displayMoreActionsWithBlock:block];
    };
}

- (void)setupQuoteCell:(NoteBlockQuoteTableViewCell *)cell block:(NotificationBlock *)block
{
    cell.attributedText             = block.attributedTextQuoted;
}

- (void)setupImageCell:(NoteBlockImageTableViewCell *)cell block:(NotificationBlock *)block
{
    NotificationMedia *media        = [block.media firstObject];
    [cell downloadImageWithURL:media.mediaURL];
}

- (void)setupTextCell:(NoteBlockTextTableViewCell *)cell block:(NotificationBlock *)block
{
    __weak __typeof(self) weakSelf  = self;
    cell.attributedText             = block.attributedTextRegular;
    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
}


#pragma mark - Helpers

- (void)openURL:(NSURL *)url
{
    if ([self displayReaderWithURL:url]) {
        return;
    }
    
    if ([self displayStatsWithURL:url]) {
        return;
    }
    
    if ([self displayWebViewWithURL:url]) {
        return;
    }
    
    [self.tableView deselectSelectedRowWithAnimation:YES];
}

- (BOOL)displayReaderWithURL:(NSURL *)url
{
    NotificationURL *notificationURL = [self.note findNotificationUrlWithUrl:url];
    
    BOOL success = ((notificationURL.isPost || notificationURL.isComment) && _note.metaPostID && _note.metaSiteID);
    if (success) {
        [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:_note];
    }
    return success;
}

- (BOOL)displayStatsWithURL:(NSURL *)url
{
    if (!_note.isStatsEvent || !_note.metaSiteID) {
        return false;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:_note.metaSiteID];
    
    BOOL success = blog.isWPcom;
    if (success) {
        [self performSegueWithIdentifier:NSStringFromClass([StatsViewController class]) sender:blog];
    }
    return success;
}

- (BOOL)displayWebViewWithURL:(NSURL *)url
{
    BOOL success = url != nil;
    if (success) {
        [self performSegueWithIdentifier:NSStringFromClass([WPWebViewController class]) sender:url];
    }
    return success;
}

- (void)displayMoreActionsWithBlock:(NotificationBlock *)block
{
    NSString *editTitle     = NSLocalizedString(@"Edit Comment", @"Edit a comment");
    NSString *spamTitle     = NSLocalizedString(@"Mark as Spam", @"Mark a comment as spam");
    NSString *cancelTitle   = NSLocalizedString(@"Cancel", nil);
    
    // Prepare the More Menu
    NSMutableArray *otherButtonTitles  = [NSMutableArray array];
    
    if ([block isActionEnabled:NoteActionEditKey]) {
        [otherButtonTitles addObject:editTitle];
    }
    
    if ([block isActionEnabled:NoteActionSpamKey]) {
        [otherButtonTitles addObject:spamTitle];
    }
    
    // Render the actionSheet
    __typeof(self) __weak weakSelf = self;
    UIActionSheet *actionSheet  = [[UIActionSheet alloc] initWithTitle:nil
                                                     cancelButtonTitle:cancelTitle
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:otherButtonTitles
                                                            completion:^(NSString *buttonTitle) {
                                                                if ([buttonTitle isEqualToString:editTitle]) {
                                                                    [weakSelf editCommentWithBlock:block];
                                                                } else if ([buttonTitle isEqualToString:spamTitle]) {
                                                                    [weakSelf spamCommentWithBlock:block];
                                                                }
                                                            }];
    
    [actionSheet showInView:self.view.window];
}


#pragma mark - Action Handlers

- (void)followSiteWithBlock:(NotificationBlock *)block
{
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderSiteService *service      = [[ReaderSiteService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service followSiteWithID:block.metaSiteID.integerValue success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionFollowKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionFollowKey];
}

- (void)unfollowSiteWithBlock:(NotificationBlock *)block
{
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderSiteService *service      = [[ReaderSiteService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unfollowSiteWithID:block.metaSiteID.integerValue success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionFollowKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionFollowKey];
}

- (void)likeCommentWithBlock:(NotificationBlock *)block
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service likeCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionLikeKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionLikeKey];
}

- (void)unlikeCommentWithBlock:(NotificationBlock *)block
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unlikeCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionLikeKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionLikeKey];
}

- (void)approveCommentWithBlock:(NotificationBlock *)block
{
    [WPAnalytics track:WPAnalyticsStatNotificationApproved];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service approveCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionApproveKey];
}

- (void)unapproveCommentWithBlock:(NotificationBlock *)block
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unapproveCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf.tableView reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionApproveKey];
}

- (void)spamCommentWithBlock:(NotificationBlock *)block
{
    NSInteger const btnIndexSpam = 1;
    
    // Callback Block
    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != btnIndexSpam) {
            return;
        }
        
        [WPAnalytics track:WPAnalyticsStatNotificationFlaggedAsSpam];
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service spamCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:nil];
    };
    
    // Show the alertView
    NSString *message = NSLocalizedString(@"Are you sure you want to mark this comment as Spam?",
                                          @"Message asking for confirmation before marking a comment as spam");
    
    [UIAlertView showWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                       message:message
             cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
             otherButtonTitles:@[NSLocalizedString(@"Spam", @"Spam")]
                      tapBlock:completion];
}

- (void)trashCommentWithBlock:(NotificationBlock *)block
{
    NSInteger const btnIndexTrash = 1;
    
    // Callback Block
    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != btnIndexTrash) {
            return;
        }
        
        [WPAnalytics track:WPAnalyticsStatNotificationTrashed];
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service deleteCommentWithID:block.metaCommentID blogID:block.metaSiteID success:nil failure:nil];
    };
 
    // Show the alertView
    NSString *message = NSLocalizedString(@"Are you sure you want to delete this comment?",
                                          @"Message asking for confirmation on comment deletion");
    
    [UIAlertView showWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                       message:message
             cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
             otherButtonTitles:@[NSLocalizedString(@"Delete", @"Delete")]
                      tapBlock:completion];
}

- (void)editCommentWithBlock:(NotificationBlock *)block
{
#warning TODO: Implement Me
}


#pragma mark - Storyboard Helpers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:NSStringFromClass([WPWebViewController class])]) {
        WPWebViewController *webViewController = segue.destinationViewController;
        webViewController.url = (NSURL *)sender;
        
    } else if([segue.identifier isEqualToString:NSStringFromClass([StatsViewController class])]) {
        StatsViewController *statsViewController = segue.destinationViewController;
        statsViewController.blog = (Blog *)sender;
        
    } else if([segue.identifier isEqualToString:NSStringFromClass([ReaderPostDetailViewController class])]) {
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        Notification *note = (Notification *)sender;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}

@end
