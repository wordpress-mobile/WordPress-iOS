//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"
#import "PageViewController.h"
#import "EditPageViewController.h"

#define TAG_OFFSET 1010

@interface PagesViewController (PrivateMethods)
- (void)refreshPostList;
@end

@implementation PagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Pages", @"");
}

- (void)syncPosts {
    [self.blog syncPagesWithSuccess:^{
        [self refreshPostList];
    } failure:^(NSError *error) {
        [self refreshPostList];
        if(error) {
            NSDictionary *errInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.blog, @"currentBlog", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kXML_RPC_ERROR_OCCURS object:error userInfo:errInfo];
        }
    } loadMore:NO];
}

// For iPhone
- (void)editPost:(AbstractPost *)apost {
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];

    self.postDetailViewController = [[EditPageViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil];
    self.postDetailViewController.apost = [apost createRevision];
    self.postDetailViewController.editMode = kEditPost;
    [self.postDetailViewController refreshUIForCurrentPost];
    [appDelegate showContentDetailViewController:self.postDetailViewController];
}

// For iPad
- (void)showSelectedPost {
    Page *page = nil;
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSIndexPath *indexPath = self.selectedIndexPath;

    @try {
        page = [self.resultsController objectAtIndexPath:indexPath];
        WPLog(@"Selected page at indexPath: (%i,%i)", indexPath.section, indexPath.row);
    }
    @catch (NSException *e) {
        NSLog(@"Can't select page at indexPath (%i,%i)", indexPath.section, indexPath.row);
        NSLog(@"sections: %@", self.resultsController.sections);
        NSLog(@"results: %@", self.resultsController.fetchedObjects);
        page = nil;
    }
    self.postReaderViewController = [[PageViewController alloc] initWithPost:page];
    [delegate showContentDetailViewController:self.postReaderViewController];    
}

- (void)showAddPostView {
	WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    Page *post = [Page newDraftForBlog:self.blog];
	if (DeviceIsPad()) {
        self.postReaderViewController = [[[PageViewController alloc] initWithPost:post] autorelease];
		[delegate showContentDetailViewController:self.postReaderViewController];
        [self.postReaderViewController showModalEditor];
	} else {
        self.postDetailViewController = [[[EditPageViewController alloc] initWithNibName:@"EditPostViewController" bundle:nil] autorelease];
        self.postDetailViewController.apost = [post createRevision];
        self.postDetailViewController.editMode = kNewPost;
        [self.postDetailViewController refreshUIForCompose];
		[delegate showContentDetailViewController:self.postDetailViewController];
	}
    [post release];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSString *sectionName = [sectionInfo name];
    
    return [Page titleForRemoteStatus:[sectionName numericValue]];
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
		[defaults setBool:false forKey:@"refreshPagesRequired"];
		return YES;
	}
	
	return NO;
}

- (void)loadMoreItems {
	[self.blog syncPagesWithSuccess:^ {
        [self refreshPostList];
    } failure:nil loadMore:YES];
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)entityName {
    return @"Page";
}

@end
