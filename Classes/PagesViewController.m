//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"

#define TAG_OFFSET 1010

@implementation PagesViewController
@synthesize newButtonItem, anyMorePages, selectedIndexPath, draftManager, appDelegate, tabController, drafts, mediaManager, dm;
@synthesize visiblePages, pageManager, pages, progressAlert, spinner, loadLimit;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	dm = [BlogDataManager sharedDataManager];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	pageManager = [[PageManager alloc] initWithXMLRPCUrl:[dm.currentBlog valueForKey:@"xmlrpc"]];
	draftManager = [[DraftManager alloc] init];
	pages = [[NSMutableArray alloc] init];
	visiblePages = [[NSMutableArray alloc] init];
	
	loadLimit = [[[dm.currentBlog valueForKey:kPostsDownloadCount] substringToIndex:3] intValue];
	if(loadLimit < 10)
		loadLimit = 10;
	
	NSLog(@"loadLimit: %d", loadLimit);
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    [self addRefreshButton];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddNewPage)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePagesTableAfterDraftSaved:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPages) name:@"DidSyncPages" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.navigationItem.title = [dm.currentBlog objectForKey:@"title"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (DeviceIsPad() == YES) {
		if (self.selectedIndexPath) {
			[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	
	if ([[Reachability sharedReachability] internetConnectionStatus]) {
		if ([defaults boolForKey:@"refreshPagesRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshPagesRequired"];
		}
	}	
	
	[self loadPages];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES)
		return YES;
	
    if ([appDelegate isAlertRunning] == YES)
        return NO;
	
    return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;

	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	
	switch (section) {
		case 0:
			if(drafts.count > 0)
				result = @"Local Drafts";
			break;
		case 1:
			result = @"Pages";
			break;
		default:
			break;
	}
	
	return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int result = 0;
	
	switch (section) {
		case 0:
			result = drafts.count;
			break;
		case 1:
			result = visiblePages.count;
			break;
		default:
			break;
	}
	
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	int foo = 0;
    static NSString *pageCellIdentifier = @"PageCell";
	
    UITableViewCell *pageCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:pageCellIdentifier];
	UITableViewCell *result;
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	
    if (pageCell == nil) {
        pageCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:pageCellIdentifier] autorelease];
    }
	
	switch (indexPath.section) {
		case 0:
			foo = indexPath.row;
			Post *page = [drafts objectAtIndex:indexPath.row];
			pageCell.textLabel.text = page.postTitle;
			pageCell.detailTextLabel.text = [formatter stringFromDate:page.dateCreated];
			result = pageCell;
			break;
		case 1:
			pageCell.textLabel.text = [[visiblePages objectAtIndex:indexPath.row] objectForKey:@"title"];
			pageCell.detailTextLabel.text = [formatter stringFromDate:[self localDateFromGMT:[[visiblePages objectAtIndex:indexPath.row] objectForKey:@"date_created_gmt"]]];
			result = pageCell;
			break;
		default:
			break;
	}
	
	[formatter release];
    return result;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int foo = 0;
	PageViewController *pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];

	switch (indexPath.section) {
		case 0:
			foo = indexPath.row;
			Post *page = [drafts objectAtIndex:indexPath.row];
			[pageViewController setSelectedPostID:page.uniqueID];
			[appDelegate showContentDetailViewController:pageViewController];
			
			self.selectedIndexPath = indexPath;
			break;
		case 1:
			[pageViewController setPageManager:self.pageManager];
			
			NSNumber *pageID = [[visiblePages objectAtIndex:indexPath.row] objectForKey:@"page_id"];
			[pageViewController setSelectedPostID:[pageID stringValue]];
			[appDelegate showContentDetailViewController:pageViewController];
			
			self.selectedIndexPath = indexPath;
			break;
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[pageViewController release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
	[progressAlert show];
	
	[self performSelectorInBackground:@selector(deletePageAtIndexPath:) withObject:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *result = nil;
	
	switch (section) {
		case 1:
			// Build Load More view
			break;
		default:
			break;
	}
	
	return result;
}

#pragma mark -
#pragma mark Custom Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:self.tableView numberOfRowsInSection:0] > 0) {
        NSUInteger indexes[] = {0, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else if ([self tableView:self.tableView numberOfRowsInSection:1] > 0) {
        NSUInteger indexes[] = {1, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)loadPages {
    [refreshButton startAnimating];
	self.drafts = [draftManager getType:@"page" forBlog:[dm.currentBlog valueForKey:@"blogid"]];
	
	int pageCount = 0;
	[pages removeAllObjects];
	[visiblePages removeAllObjects];
	for(NSDictionary *page in pageManager.pages) {
		[pages addObject:page];
		
		if(pageCount < loadLimit)
			[visiblePages addObject:page];
		pageCount++;
	}
	
	[self refreshTable];
    [refreshButton stopAnimating];
}

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);

    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];

    self.tableView.tableHeaderView = refreshButton;
}

- (void)refreshHandler {
    [refreshButton startAnimating];
	[pageManager syncPages];
}

- (void)showAddNewPage {
    [dm makeNewPageCurrent];
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
	backButton.title = @"Pages";
	self.navigationItem.backBarButtonItem = backButton;
	[backButton release]; 
	
	PageViewController *pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
	[appDelegate showContentDetailViewController:pageViewController];
	[pageViewController release];
}

- (void)addSpinnerToCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:YES];
	
	int totalPages = [[BlogDataManager sharedDataManager] countOfPageTitles];
	NSString * totalString = [NSString stringWithFormat:@"%d pages loaded", totalPages];
	[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Loading more pages...":YES];
	
	[apool release];
}

- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:NO];
	
	[apool release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [appDelegate setAlertRunning:NO];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake) {
		[self refreshHandler];
	}
}

- (void)updatePagesTableAfterDraftSaved:(NSNotification *)notification {
    [dm loadPageTitlesForCurrentBlog];
	[self loadPages];
}

- (void)deletePageAtIndexPath:(NSIndexPath *)indexPath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (indexPath.section == 0) {
		Post *draft = [drafts objectAtIndex:indexPath.row];
		[mediaManager removeForPostID:draft.postID andBlogURL:[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:@"url"]];
		
		NSManagedObject *objectToDelete = [drafts objectAtIndex:indexPath.row];
		[appDelegate.managedObjectContext deleteObject:objectToDelete];
		
        // Commit the change.
        NSError *error;
        if (![appDelegate.managedObjectContext save:&error]) {
			NSLog(@"Severe error when trying to delete local draft. Error: %@", error);
        }
		
		[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
		[progressAlert release];
		[self performSelectorOnMainThread:@selector(didDeleteDraftAtIndexPath:) withObject:indexPath waitUntilDone:NO];
    }
	else if(indexPath.section == 1){
		if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
															message:@"no internet connection."
														   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			alert.tag = TAG_OFFSET;
			[alert show];
			[appDelegate setAlertRunning:YES];
			[alert release];
		}
		else {
			NSNumber *pageID = [[visiblePages objectAtIndex:indexPath.row] objectForKey:@"page_id"];
			BOOL result = [pageManager deletePage:pageID];
			[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
			[progressAlert release];
			if(result == YES)
				[self performSelectorOnMainThread:@selector(didDeletePageAtIndexPath:) withObject:indexPath waitUntilDone:NO];
		}
	}
	
    [pool release];
}

- (void)didDeleteDraftAtIndexPath:(NSIndexPath *)indexPath {
	[drafts removeObjectAtIndex:indexPath.row];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	[self loadPages];
	[progressAlert dismiss];
}

- (void)didDeletePageAtIndexPath:(NSIndexPath *)indexPath {
	[pages removeObjectAtIndex:indexPath.row];
	[visiblePages removeObjectAtIndex:indexPath.row];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	[self loadPages];
	[progressAlert dismiss];
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (NSDate *)localDateFromGMT:(NSDate *)sourceDate {
	NSTimeZone *sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	NSTimeZone *destinationTimeZone = [NSTimeZone systemTimeZone];
	
	NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
	NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
	NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
	
	NSDate *result = [[[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate] autorelease];
	return result;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[progressAlert release];
	[spinner release];
	[pageManager release];
	[visiblePages release];
	[pages release];
	[draftManager release];
	[mediaManager release];
	[drafts release];
	[tabController release];
    [newButtonItem release];
    [refreshButton release];
	[selectedIndexPath release];
    [super dealloc];
}

@end
