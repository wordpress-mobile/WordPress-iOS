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

#import "WPToast.h"



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSUInteger NotificationDetailSectionsCount   = 1;

static NSString *NotificationActionUnfollowIcon     = @"action_icon_unfollowed";
static NSString *NotificationActionFollowIcon       = @"action_icon_followed";

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
    self.tableView.separatorColor   = [WPStyleGuide readGrey];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    
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
        NotificationURL *noteURL = [block.urls firstObject];
        [self openURL:noteURL.url];
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
    NotificationURL *blogURL        = [block.urls firstObject];
    NotificationMedia *media        = [block.media firstObject];
    NSNumber *following             = [block actionForKey:NoteActionFollowKey];
    __weak __typeof(self) weakSelf  = self;
    
    cell.name                       = block.text;
    cell.blogURL                    = blogURL.url;
    cell.gravatarURL                = media.mediaURL;
    cell.following                  = following.boolValue;
    cell.actionEnabled              = following != nil;
    
    cell.onFollowClick              = ^() {
        [weakSelf toggleFollowWithBlock:block];
    };
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell block:(NotificationBlock *)block
{
    __weak __typeof(self) weakSelf  = self;
    cell.attributedText             = block.attributedTextRegular;
    
    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
    cell.onLikeClick                = ^(){
#warning TODO: Implement Likes
        NSLog(@"Like");
    };
    cell.onSpamClick                = ^(){
#warning TODO: Implement Spam
        NSLog(@"Spam");
    };
    cell.onTrashClick               = ^(){
#warning TODO: Implement Trash
        NSLog(@"Trash");
    };
    cell.onMoreClick                = ^(){
#warning TODO: Implement More
        NSLog(@"More");
    };
}

- (void)setupQuoteCell:(NoteBlockQuoteTableViewCell *)cell block:(NotificationBlock *)block
{
    cell.attributedText             = block.attributedTextQuoted;
}

- (void)setupImageCell:(NoteBlockImageTableViewCell *)cell block:(NotificationBlock *)block
{
    NotificationMedia *media        = [block.media firstObject];
    cell.imageURL                   = media.mediaURL;
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
    // Reader:
    if ([self shouldPushNativeReaderForURL:url]) {
        [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:self.note];
        return;
    }

    // Load the Blog
    Blog *blog = [self loadBlogWithID:_note.metaSiteID];
    
    // Stats
    if (_note.isStatsEvent && blog.isWPcom){
        [self performSegueWithIdentifier:NSStringFromClass([StatsViewController class]) sender:blog];
        
    // WebView
    } else if (url) {
        [self performSegueWithIdentifier:NSStringFromClass([WPWebViewController class]) sender:url];
        
    // Failure
    } else {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}

- (BOOL)shouldPushNativeReaderForURL:(NSURL *)url
{
    // Find the associated NotificationURL, if any
    NotificationURL *notificationURL = nil;
    for (NotificationBlock *block in self.note.bodyBlocks) {
        for (NotificationURL *noteURL in block.urls) {
            if ([noteURL.url isEqual:url]) {
                notificationURL = noteURL;
            }
        }
    }
    
    return (notificationURL.isPost || notificationURL.isComment) && self.note.metaPostID && self.note.metaSiteID;
}

- (Blog *)loadBlogWithID:(NSNumber *)blogID
{
    if (!blogID) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:blogID];
    
    return blog;
}


#pragma mark - Action Handlers

- (void)toggleFollowWithBlock:(NotificationBlock *)block
{
    NSNumber *siteID = block.metaSiteID;
    if (!siteID) {
		return;
	}
    
    // Stats please!
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];

    // Display a Toast
    BOOL isFollowing = [[block actionForKey:NoteActionFollowKey] boolValue];
    
    if (isFollowing) {
        [WPToast showToastWithMessage:NSLocalizedString(@"Unfollowed", @"User unfollowed a blog")
                             andImage:[UIImage imageNamed:NotificationActionUnfollowIcon]];
    } else {
        [WPToast showToastWithMessage:NSLocalizedString(@"Followed", @"User followed a blog")
                             andImage:[UIImage imageNamed:NotificationActionFollowIcon]];
    }
    
	// Hit the Backend
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
	WordPressComApi *restApi        = [accountService.defaultWordPressComAccount restApi];
    __weak __typeof(self)weakSelf   = self;
    
	[restApi followBlog:siteID.integerValue isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSNumber* isFollowingNow = [(NSDictionary *)responseObject numberForKey:NotificationRestFollowingKey];
        [block setActionOverrideValue:isFollowingNow forKey:NoteActionFollowKey];
        
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
		DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        
        [block removeActionOverrideForKey:NotificationRestFollowingKey];
        [weakSelf.tableView reloadData];
	}];
    
    // Set an Override: Simperium will update the real object anytime, but let's fake it until we make it!
    [block setActionOverrideValue:@(!isFollowing) forKey:NoteActionFollowKey];
}


#pragma mark - Storyboard Helpers

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *webViewSegueID    = NSStringFromClass([WPWebViewController class]);
    NSString *statsSegueID      = NSStringFromClass([StatsViewController class]);
    NSString *readerSegueID     = NSStringFromClass([ReaderPostDetailViewController class]);
    
    if ([segue.identifier isEqualToString:webViewSegueID] && [sender isKindOfClass:[NSURL class]]) {
        WPWebViewController *webViewController = segue.destinationViewController;
        webViewController.url = (NSURL *)sender;
        
    } else if([segue.identifier isEqualToString:statsSegueID] && [sender isKindOfClass:[Blog class]]) {
        StatsViewController *statsViewController = segue.destinationViewController;
        statsViewController.blog = (Blog *)sender;
        
    } else if([segue.identifier isEqualToString:readerSegueID] && [sender isKindOfClass:[Notification class]]) {
        Notification *note = sender;
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:note.metaPostID siteID:note.metaSiteID];
    }
}

@end
