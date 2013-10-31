//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"
#import "PageViewController.h"
#import "EditPageViewController.h"
#import "WPTableViewControllerSubclass.h"

#define TAG_OFFSET 1010

@interface PagesViewController (PrivateMethods)
- (void)syncFinished;
- (BOOL)isSyncing;
@end

@implementation PagesViewController

- (id)init {
    self = [super init];
    if(self) {
        self.title = NSLocalizedString(@"Pages", @"");
    }
    return self;
}

- (NSString *)noResultsText
{
    return NSLocalizedString(@"No pages yet", @"Displayed when the user pulls up the pages view and they have no pages");
}


- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncPagesWithSuccess:success failure:failure loadMore: NO];
}

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    EditPageViewController *editPostViewController = [[EditPageViewController alloc] initWithPost:apost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.panelNavigationController.detailViewController presentViewController:navController animated:YES completion:nil];
}

// For iPad
- (void)showSelectedPost {
    Page *page = nil;
    NSIndexPath *indexPath = self.selectedIndexPath;

    @try {
        page = [self.resultsController objectAtIndexPath:indexPath];
        DDLogInfo(@"Selected page at indexPath: (%i,%i)", indexPath.section, indexPath.row);
    }
    @catch (NSException *e) {
        DDLogError(@"Can't select page at indexPath (%i,%i)", indexPath.section, indexPath.row);
        DDLogError(@"sections: %@", self.resultsController.sections);
        DDLogError(@"results: %@", self.resultsController.fetchedObjects);
        page = nil;
    }
    
    self.postReaderViewController = [[PageViewController alloc] initWithPost:page];
    [self.panelNavigationController.navigationController pushViewController:self.postReaderViewController animated:YES];
}

- (void)showAddPostView {
    [WPMobileStats trackEventForWPCom:StatsEventPagesClickedNewPage];

    if (IS_IPAD)
        [self resetView];
    
    Page *post = [Page newDraftForBlog:self.blog];
    [self editPost:post];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *sectionName = [sectionInfo name];
    
    return [Page titleForRemoteStatus:[sectionName numericValue]];
}

- (NSString *)statsPropertyForViewOpening
{
    return StatsPropertyPagedOpened;
}


#pragma mark -
#pragma mark Syncs methods

- (BOOL)isSyncing {
	return self.blog.isSyncingPages;
}

-(NSDate *) lastSyncDate {
	return self.blog.lastPagesSync;
}

- (BOOL) hasOlderItems {
	return [self.blog.hasOlderPages boolValue];
}

- (BOOL)refreshRequired {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"refreshPagesRequired"]) { 
		[defaults setBool:NO forKey:@"refreshPagesRequired"];
		return YES;
	}
	
	return NO;
}

- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncPagesWithSuccess:success failure:failure loadMore:YES];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Page";
}

@end
