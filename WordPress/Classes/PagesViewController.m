//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"
#import "EditPageViewController.h"
#import "WPTableViewControllerSubclass.h"

#define TAG_OFFSET 1010

@interface PagesViewController (PrivateMethods)
- (void)syncFinished;
- (BOOL)isSyncing;
@end

@implementation PagesViewController

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"Pages", @"");
}

- (NSString *)noResultsText
{
    return NSLocalizedString(@"No pages yet", @"Displayed when the user pulls up the pages view and they have no pages");
}


- (void)syncItemsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    [self.blog syncPagesWithSuccess:success failure:failure loadMore: NO];
}

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    EditPageViewController *editPostViewController = [[EditPageViewController alloc] initWithPost:apost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)showAddPostView {
    [WPMobileStats trackEventForWPCom:StatsEventPagesClickedNewPage];
    
    Page *post = [Page newDraftForBlog:self.blog];
    [self editPost:post];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Don't show a section title if there's only one section
    if ([tableView numberOfSections] <= 1)
        return nil;

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
