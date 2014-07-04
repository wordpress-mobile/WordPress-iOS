#import "NotificationDetailsViewController.h"
#import "Notification.h"
#import "Notification+UI.h"

#import "NoteBlockHeaderTableViewCell.h"
#import "NoteBlockTextTableViewCell.h"
#import "NoteBlockImageTableViewCell.h"
#import "NoteBlockUserTableViewCell.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"

#import "WPWebViewController.h"

#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"

#import "Blog.h"
#import "BlogService.h"
#import "StatsViewController.h"

#import "WPToast.h"

#import "WordPressAppDelegate.h"
#import <Simperium/Simperium.h>
#import <Simperium/SPBucket.h>


#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

typedef NS_ENUM(NSInteger, NotificationDetailSections) {
    NotificationDetailSectionsHeader    = 0,
    NotificationDetailSectionsBodyItems = 1,
    NotificationDetailSectionsCount     = 2
};

static NSString *NotificationActionUnfollowIcon = @"action_icon_unfollowed";
static NSString *NotificationActionFollowIcon   = @"action_icon_followed";
static NSString *NotificationRestFollowingKey   = @"is_following";

static UIEdgeInsets NotificationTableInsets     = { 0.0f, 0.0f, 20.0f, 0.0f };


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
    
    self.tableView.contentInset     = NotificationTableInsets;
    self.tableView.backgroundColor  = [WPStyleGuide itsEverywhereGrey];
    self.tableView.separatorColor   = [WPStyleGuide readGrey];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    
    self.title                      = NSLocalizedString(@"Details", @"Notification Details Section Title");
    self.restorationClass           = [self class];
    
    Simperium *simperium            = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
    SPBucket *notificationsBucket   = [simperium bucketForName:NSStringFromClass([Notification class])];
    notificationsBucket.delegate    = self;
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
    NotificationBlock *block = (indexPath.section == NotificationDetailSectionsHeader) ? self.note.subjectBlock : self.note.bodyBlocks[indexPath.row];
    NSAssert([block isKindOfClass:[NotificationBlock class]], nil);
    
    return block;
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return NotificationDetailSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == NotificationDetailSectionsHeader) ? 1 : self.note.bodyBlocks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block = [self blockForIndexPath:indexPath];

    if (indexPath.section == NotificationDetailSectionsHeader) {
        return [NoteBlockHeaderTableViewCell heightWithText:block.text];
        
    } else if (block.type == NoteBlockTypesUser) {
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
    
    if (indexPath.section == NotificationDetailSectionsHeader) {
        NSString *reuseIdentifier           = [NoteBlockHeaderTableViewCell reuseIdentifier];
        NoteBlockHeaderTableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        cell.noticon                        = self.note.noticon;
        cell.attributedText                 = block.attributedSubject;
        
        return cell;
        
    } else if (block.type == NoteBlockTypesUser) {
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
            [weakSelf openURL:url];
        };
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlock *block = [self blockForIndexPath:indexPath];
    
    // When tapping a User's cell, let's push the associated blog. If any!
    if (block.type == NoteBlockTypesUser) {
        NotificationURL *blogURL = [block.urls firstObject];
        if (blogURL.url) {
            [self openURL:blogURL.url];
        }
    }
}


#pragma mark - Action Helpers

- (void)openURL:(NSURL *)url
{
    NSString *segueID   = NSStringFromClass([WPWebViewController class]);
    id sender           = url;
    
    // Detect if it's a stats notification, and push the StatsVC
    if ([self.note isStatsEvent]) {
        BlogService *service    = [[BlogService alloc] initWithManagedObjectContext:self.note.managedObjectContext];
        Blog *blog              = [service blogByBlogId:self.note.metaSiteID];

        // Attempt to load the blog by its name
        if (!blog) {
            NSString *blogName  = [[[NSScanner scannerWithString:self.note.subjectBlock.text] scanQuotedText] firstObject];
            blog                = [service blogByBlogName:blogName];
        }

        // On success, push the Stats VC
        if (blog) {
            segueID = NSStringFromClass([StatsViewController class]);
            sender  = blog;
        }
    }
    
    [self performSegueWithIdentifier:segueID sender:sender];
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
    NSString *webViewSegueID = NSStringFromClass([WPWebViewController class]);
    NSString *statsSegueID   = NSStringFromClass([StatsViewController class]);
    
    if ([segue.identifier isEqualToString:webViewSegueID] && [sender isKindOfClass:[NSURL class]]) {
        WPWebViewController *webViewController      = segue.destinationViewController;
        webViewController.url                       = (NSURL *)sender;
        
    } else if([segue.identifier isEqualToString:statsSegueID] && [sender isKindOfClass:[Blog class]]) {
        StatsViewController *statsViewController    = segue.destinationViewController;
        statsViewController.blog                    = (Blog *)sender;
    }
}

@end
