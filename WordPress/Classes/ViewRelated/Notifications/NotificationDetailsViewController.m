#import "NotificationDetailsViewController.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "NotificationHeaderView.h"

#import "NoteBlockTextTableViewCell.h"
#import "NoteBlockImageTableViewCell.h"
#import "NoteBlockUserTableViewCell.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"
#import "UITableView+Helpers.h"

#import "WPWebViewController.h"

#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"

#import "Blog.h"
#import "BlogService.h"
#import "StatsViewController.h"

#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostDetailViewController.h"

#import "WPToast.h"

#import "WordPressAppDelegate.h"
#import <Simperium/Simperium.h>
#import <Simperium/SPBucket.h>



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSUInteger NotificationDetailSectionsCount   = 1;

static NSString *NotificationActionUnfollowIcon     = @"action_icon_unfollowed";
static NSString *NotificationActionFollowIcon       = @"action_icon_followed";
static NSString *NotificationRestFollowingKey       = @"is_following";

static UIEdgeInsets NotificationTableInsetsPhone    = { 0.0f, 0.0f, 20.0f, 0.0f };
static UIEdgeInsets NotificationTableInsetsPad      = { 40.0f, 0.0f, 20.0f, 0.0f };


#pragma mark ==========================================================================================
#pragma mark Private
#pragma mark ==========================================================================================

@interface NotificationDetailsViewController () <SPBucketDelegate>
@end


#pragma mark ==========================================================================================
#pragma mark NotificationDetailsViewController
#pragma mark ==========================================================================================

@implementation NotificationDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentInset     = IS_IPAD ? NotificationTableInsetsPad : NotificationTableInsetsPhone;
    self.tableView.backgroundColor  = [WPStyleGuide itsEverywhereGrey];
    self.tableView.separatorColor   = [WPStyleGuide readGrey];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    
    self.title                      = NSLocalizedString(@"Details", @"Notification Details Section Title");
    self.restorationClass           = [self class];
    
    NotificationHeaderView *header  = [NotificationHeaderView headerWithWidth:CGRectGetWidth(self.view.bounds)];
    header.noticon                  = self.note.noticon;
    header.attributedText           = self.note.subjectBlock.attributedSubject;
    [header layoutIfNeeded];
    self.tableView.tableHeaderView  = header;
    
    Simperium *simperium            = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    SPBucket *notificationsBucket   = [simperium bucketForName:NSStringFromClass([Notification class])];
    notificationsBucket.delegate    = self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Note: we do this to force layout!
    [self.tableView reloadData];
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
    NotificationBlock *block = [self blockForIndexPath:indexPath];

    if (block.type == NoteBlockTypesUser) {
        return [NoteBlockUserTableViewCell heightWithText:block.text];
        
    } else if (block.type == NoteBlockTypesImage) {
        return [NoteBlockImageTableViewCell heightWithText:block.text];
        
    } else {
        return [NoteBlockTextTableViewCell heightWithText:block.text];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block        = [self blockForIndexPath:indexPath];
    __weak __typeof(self) weakSelf  = self;

    if (block.type == NoteBlockTypesUser) {
        NSString *reuseIdentifier           = [NoteBlockUserTableViewCell reuseIdentifier];
        NoteBlockUserTableViewCell *cell    = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

        NotificationURL *blogURL            = [block.urls firstObject];
        NotificationMedia *gravatarMedia    = [block.media firstObject];
        NSNumber *following                 = [block actionForKey:NoteActionFollowKey];
        
        cell.name                           = block.text;
        cell.blogURL                        = blogURL.url;
        cell.gravatarURL                    = gravatarMedia.mediaURL;
        cell.following                      = following.boolValue;
        cell.actionEnabled                  = following != nil;
        
        cell.onFollowClick                  = ^() {
            [weakSelf toggleFollowWithBlock:block];
        };
        
        return cell;
        
    } else if (block.type == NoteBlockTypesImage) {
        NSString *reuseIdentifier           = [NoteBlockImageTableViewCell reuseIdentifier];
        NoteBlockImageTableViewCell *cell   = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        NotificationMedia *media            = [block.media firstObject];
        cell.imageURL                       = media.mediaURL;

        return cell;
        
    } else {
        NSString *reuseIdentifier           = [NoteBlockTextTableViewCell reuseIdentifier];
        NoteBlockTextTableViewCell *cell    = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        cell.attributedText                 = block.attributedText;
        cell.onUrlClick                     = ^(NSURL *url){
            for (NotificationURL *noteURL in block.urls) {
                if ([noteURL.url isEqual:url]) {
                    [weakSelf handleNotificationURL:noteURL];
                }
            }
        };
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block = [self blockForIndexPath:indexPath];
    
    // When tapping a User's cell, let's push the associated blog. If any!
    if (block.type == NoteBlockTypesUser) {
        NSURL *blogURL = [[block.urls firstObject] url];
        if (blogURL) {
            [self openURL:blogURL];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}


#pragma mark - Helpers

- (void)handleNotificationURL:(NotificationURL *)notificationURL
{
    Blog *blog = nil;
    
    NSNumber *siteID = _note.metaSiteID;
    if (siteID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
        blog                            = [service blogByBlogId:siteID];
    }
    
    if ([notificationURL.type isEqual:NoteLinkTypePost] && _note.metaPostID && _note.metaSiteID) {
        [self openReaderWithNote:self.note];
        
    } else if (_note.isStatsEvent && blog.isWPcom){
        [self openStatsForBlog:blog];
        
    } else if (notificationURL.url) {
        [self openURL:notificationURL.url];
        
    } else {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}


#pragma mark - Action Handlers

- (void)openReaderWithNote:(Notification *)note
{
    [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:note];
}

- (void)openStatsForBlog:(Blog *)blog
{
    [self performSegueWithIdentifier:NSStringFromClass([StatsViewController class]) sender:blog];
}

- (void)openURL:(NSURL *)url
{
    [self performSegueWithIdentifier:NSStringFromClass([WPWebViewController class]) sender:url];
}

- (void)toggleFollowWithBlock:(NotificationBlock *)block
{
    BOOL isFollowing = [[block actionForKey:NoteActionFollowKey] boolValue];
    NSNumber *siteID = block.metaSiteID;
    if (!siteID) {
		return;
	}
    
    // Stats please!
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];

    // Display a Toast    
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
