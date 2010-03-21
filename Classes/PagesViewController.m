//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"

#import "BlogDataManager.h"
#import "EditPageViewController.h"
#import "PageViewController.h"
#import "PostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "WPProgressHUD.h"
#import "IncrementPost.h"

#define LOCAL_DRAFTS_SECTION    0
#define PAGES_SECTION           1
#define NUM_SECTIONS            2

#define TAG_OFFSET 1010

@interface PagesViewController (Private)

- (void)scrollToFirstCell;
- (void)loadPages;
- (void)setPageDetailsController;
- (void)refreshHandler;
- (void)syncPages;
- (void)showAddNewPage;
- (void)addRefreshButton;
- (void)deletePageAtIndexPath;

@end

@implementation PagesViewController

@synthesize newButtonItem, pageDetailViewController, pageDetailsController;
@synthesize anyMorePages;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    if (pageDetailViewController != nil) {
        [pageDetailViewController autorelease];
        pageDetailViewController = nil;
    }
    
    [pageDetailsController release];
    
    [newButtonItem release];
    [refreshButton release];
	    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

    [self addRefreshButton];
    [self setPageDetailsController];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddNewPage)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	
	if ([[Reachability sharedReachability] internetConnectionStatus])
	{
		if ([defaults boolForKey:@"refreshPagesRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshPagesRequired"];
		}
	}	
	
	[self loadPages];
    
//    if ([self.tableView indexPathForSelectedRow]) {
//        [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
//        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
//    }
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LOCAL_DRAFTS_SECTION) {
        if ([[BlogDataManager sharedDataManager] numberOfPageDrafts] > 0) {
            return @"Local Drafts";
        } else {
            return NULL;
        }
    } else {
        return @"Pages";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if (section == LOCAL_DRAFTS_SECTION) {
        return [[BlogDataManager sharedDataManager] numberOfPageDrafts];
		
    } else if ([defaults boolForKey:@"anyMorePages"]) {
        return [[BlogDataManager sharedDataManager] countOfPageTitles] +1;
		
    } else {
		return [[BlogDataManager sharedDataManager] countOfPageTitles];
	}

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PageCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    id page = nil;
	
    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        page = [dm pageDraftTitleAtIndex:indexPath.row];
    } else {
		int count = [[BlogDataManager sharedDataManager] countOfPageTitles];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//handle the case when it's the last row and we need to return the modified "get more posts" cell
		//note that it's not [[BlogDataManager sharedDataManager] countOfPostTitles] +1 because of the difference in the counting of the datasets
		
		if ([defaults boolForKey:@"anyMorePages"]) {
			if (indexPath.row == count) {
			
				NSLog(@"inside the else");
				NSLog(@"index path: %d", indexPath.row);
				//set the labels.  The spinner will be activiated if the row is selected in didSelectRow...
				//get the total number of posts on the blog, make a string and pump it into the cell
				int totalPages = [[BlogDataManager sharedDataManager] countOfPageTitles];
				NSLog(@"totalPages %d", totalPages);
				//show "nothing" if this is the first time this view showed for a newly-loaded blog
				if (totalPages == 0) {
					cell .contentView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
					cell.accessoryType = UITableViewCellAccessoryNone;
					return cell;
				}else{
				
					NSString * totalString = [NSString stringWithFormat:@"%d pages total", totalPages];
					[cell changeCellLabelsForUpdate:totalString:@"Load more pages":NO];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
				}
			}
		}
		//if it wasn't the last cell, proceed as normal.
        page = [dm pageTitleAtIndex:indexPath.row];
    }
	
    cell.post = page;
	
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    dataManager.isLocaDraftsCurrent = (indexPath.section == LOCAL_DRAFTS_SECTION);

    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        id currentDraft = [dataManager pageDraftTitleAtIndex:indexPath.row];

        // Bail out if we're in the middle of saving the draft.
        if ([[currentDraft valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dataManager makePageDraftAtIndexCurrent:indexPath.row];
    } else {
		//handle the case when it's the last row and is the "get more posts" special cell
		if (indexPath.row == [[BlogDataManager sharedDataManager] countOfPageTitles]) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			
			//run the spinner in the background and change the text
			[self performSelectorInBackground:@selector(addSpinnerToCell:) withObject:indexPath];
			
			// deselect the row.
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
			
			//init the Increment Post helper class class
			IncrementPost *incrementPost = [[IncrementPost alloc] init];
			
			//run the "get more" function in the IncrementPost class and get metadata, then parse metadata for next 10 and get 10 more
			anyMorePages = [incrementPost loadOlderPages];
			[defaults setBool:anyMorePages forKey:@"anyMorePages"];
			//TODO: JOHNB if this fails we should surface an alert with useful error message.
			//here or in incrementPost?  Perhaps a bool return?
			
			//release the helper class
			[incrementPost release];
			
			//turn of spinner and change text
			[self performSelectorInBackground:@selector(removeSpinnerFromCell:) withObject:indexPath];
			
			//refresh the post list
			[self loadPages];
			
			//get a reference to the cell
			UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
			
			// solve the problem where the "load more" cell is reused and retains it's old formatting by forcing a redraw
			[cell setNeedsDisplay];
			
			
			//return
			return;
			
		}
		
		
        id page = [dataManager pageTitleAtIndex:indexPath.row];

        // Bail out if we're in the middle of saving the page.
        if ([[page valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dataManager makePageAtIndexCurrent:indexPath.row];

        self.pageDetailsController.hasChanges = NO;
    }

    self.pageDetailsController.mode = editPage;
    [delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //return indexPath.section == LOCAL_DRAFTS_SECTION;
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting Page..."];
	[progressAlert show];
	
	[self performSelectorInBackground:@selector(deletePageAtIndexPath:) withObject:indexPath];
}


#pragma mark -
#pragma mark Private Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:self.tableView numberOfRowsInSection:LOCAL_DRAFTS_SECTION] > 0) {
        NSUInteger indexes[] = {LOCAL_DRAFTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else if ([self tableView:self.tableView numberOfRowsInSection:PAGES_SECTION] > 0) {
        NSUInteger indexes[] = {PAGES_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)loadPages {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    dm.isLocaDraftsCurrent = NO;

    [dm loadPageTitlesForCurrentBlog];
    [dm loadPageDraftTitlesForCurrentBlog];

    [self.tableView reloadData];
}

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);

    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];

    self.tableView.tableHeaderView = refreshButton;
}

- (void)refreshHandler {
    [refreshButton startAnimating];
    [self performSelectorInBackground:@selector(syncPages) withObject:nil];
}

- (void)syncPages {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    [dm syncPagesForBlog:[dm currentBlog]];
    [self loadPages];

    [refreshButton stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [pool release];
}

- (void)showAddNewPage {
    [[BlogDataManager sharedDataManager] makeNewPageCurrent];
    self.pageDetailsController.mode = newPage;
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //Code to disable landscape when alert is raised.

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

    // Return YES for supported orientations
    return YES;
}

- (void) deletePageAtIndexPath:(id)object{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	
	NSIndexPath *indexPath = (NSIndexPath*)object;
	
    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        [dataManager deletePageDraftAtIndex:indexPath.row forBlog:[dataManager currentBlog]];
		[self loadPages];
    } else {
		if (indexPath.section == PAGES_SECTION){
			//check for reachability
			if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
																message:@"no internet connection."
															   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				alert.tag = TAG_OFFSET;
				[alert show];
				
				WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
				[delegate setAlertRunning:YES];
				[alert release];
				return;
			}else{				
				//if reachability is good, make page at index current, delete page, and refresh view (load pages)
				[dataManager makePageAtIndexCurrent:indexPath.row];
				//delete page
				[dataManager deletePage];
				//resync pages
				[self syncPages];
				
			}
		}
	}
	
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
	
}

#pragma mark -
#pragma mark Helper Methods for "Load More" cell
- (void) addSpinnerToCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	//get the cell
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	
	//set the spinner (cast to PostTableView "type" in order to avoid warnings)
	[((PostTableViewCell *)cell) runSpinner:YES];
	
	//set up variables for cell text values
	int totalPages = [[BlogDataManager sharedDataManager] countOfPageTitles];
	NSString * totalString = [NSString stringWithFormat:@"%d pages loaded", totalPages];
	
	//change the text in the cell to say "Loading" and change text color
	[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Loading more pages...":YES];
	
	[apool release];
}

- (void) removeSpinnerFromCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	//get the cell
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	
	//set up variables for changing text values
	//int totalPages = [[BlogDataManager sharedDataManager] countOfPostTitles];
	//NSString * totalString = [NSString stringWithFormat:@"%d pages loaded", totalPages];
	
	//turn off the spinner and change the text
	//[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Load more pages...":NO];
	[((PostTableViewCell *)cell) runSpinner:NO];
	
	[apool release];
}

#pragma mark -

- (void)setPageDetailsController {
    if (self.pageDetailsController == nil) {
        self.pageDetailsController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

@end
