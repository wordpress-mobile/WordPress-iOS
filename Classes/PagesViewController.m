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
@synthesize pageManager, progressAlert, loadLimit, pages;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	dm = [BlogDataManager sharedDataManager];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	pageManager = [[PageManager alloc] initWithXMLRPCUrl:[dm.currentBlog valueForKey:@"xmlrpc"]];
	draftManager = [[DraftManager alloc] init];
	pages = [[NSMutableArray alloc] init];
	
	loadLimit = [[dm.currentBlog valueForKey:kPostsDownloadCount] intValue];
	if(loadLimit < 10)
		loadLimit = 10;
	
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    [self addRefreshButton];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddNewPage)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"DidSyncPages" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPages) name:@"DidGetPages" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPages) name:@"DidAddPage" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewPage:) name:@"DidCreatePage" object:nil];
	
	[self loadPages];
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
	
	[self refreshTable];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if(pages.count < pageManager.pages.count)
		return 3;
	else
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
			result = pages.count;
			break;
		case 2:
			result = 1;
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
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	
    if (pageCell == nil) {
        pageCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:pageCellIdentifier] autorelease];
		pageCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		pageCell.detailTextLabel.textColor = [UIColor lightGrayColor];
	}
	
	UILoadMoreCell *loadCell = (UILoadMoreCell *)[tableView dequeueReusableCellWithIdentifier:kCellLoadMore_ID];
	if (loadCell == nil) {
        loadCell = [UILoadMoreCell createNewLoadMoreCellFromNib];
    }
	
	switch (indexPath.section) {
		case 0:
			foo = indexPath.row;
			Post *page = [drafts objectAtIndex:indexPath.row];
			pageCell.textLabel.text = page.postTitle;
			if((pageCell.textLabel.text == nil) || ([pageCell.textLabel.text length] == 0)) {
				pageCell.textLabel.text = @"(no title)";
			}
			pageCell.detailTextLabel.text = [formatter stringFromDate:page.dateCreated];
			result = pageCell;
			break;
		case 1:
			pageCell.textLabel.text = [[pages objectAtIndex:indexPath.row] objectForKey:@"title"];
			if((pageCell.textLabel.text == nil) || ([pageCell.textLabel.text length] == 0)) {
				pageCell.textLabel.text = @"(no title)";
			}
			pageCell.detailTextLabel.text = [formatter stringFromDate:[self localDateFromGMT:[[pages objectAtIndex:indexPath.row] objectForKey:@"date_created_gmt"]]];
			result = pageCell;
			break;
		case 2:
			loadCell.backgroundColor = [UIColor grayColor];
			loadCell.mainLabel.text = @"Load more pages.";
			if(pageManager.isGettingPages == YES)
				loadCell.subtitleLabel.text = [NSString stringWithFormat:@"%d pages loaded. Fetching total...", pages.count];
			else
				loadCell.subtitleLabel.text = [NSString stringWithFormat:@"%d pages loaded. %d total.", pages.count, self.pageManager.pages.count];
			result = loadCell;
			break;
		default:
			break;
	}
	
	[formatter release];
    return result;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0:
			cell.textLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
			cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
			break;
		case 1:
			cell.textLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
			cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
			break;
		case 2:
			cell.backgroundView = nil;
			break;
		default:
			break;
	}
	
	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int foo = 0;
	PageViewController *pageViewController;
	if(DeviceIsPad() == YES)
		pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController-iPad" bundle:nil];
	else
		pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];

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
			
			NSNumber *pageID = [[pages objectAtIndex:indexPath.row] objectForKey:@"page_id"];
			[pageViewController setSelectedPostID:[pageID stringValue]];
			
			if(DeviceIsPad() == YES)
				[appDelegate showContentDetailViewController:pageViewController];
			else
				[appDelegate showContentDetailViewController:pageViewController];
			
			self.selectedIndexPath = indexPath;
			break;
		case 2:
			[self loadMore];
			break;

		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[pageViewController release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat result = POST_ROW_HEIGHT;
	switch (indexPath.section) {
		case 2:
			result = 60.0;
			break;
		default:
			break;
	}
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting..."];
	[progressAlert show];
	
	[self performSelectorInBackground:@selector(deletePageAtIndexPath:) withObject:indexPath];
}

#pragma mark -
#pragma mark Custom Methods

- (void)loadMore {
	UILoadMoreCell *loadCell = (UILoadMoreCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	loadCell.mainLabel.text = @"Loading more pages...";
	loadCell.mainLabel.textColor = [UIColor grayColor];
	[loadCell.spinner startAnimating];
	
	[self performSelectorInBackground:@selector(loadMoreInBackground) withObject:nil];
}

- (void)loadMoreInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread sleepForTimeInterval:0.75];
	
	int pageCount = 0;
	for(NSDictionary *page in pageManager.pages) {
		if((pageCount < loadLimit) && (![pages containsObject:page])) {
			[pages addObject:page];
			pageCount++;
		}
		else if(pageCount >= loadLimit) {
			break;
		}
	}
	
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)loadPages {
    [refreshButton startAnimating];
	[self refreshTable];
	self.drafts = [draftManager getType:@"page" forBlog:[dm.currentBlog valueForKey:@"blogid"]];
	
	int pageCount = 0;
	[pages removeAllObjects];
	for(NSDictionary *page in pageManager.pages) {
		if(pageCount < loadLimit) {
			[pages addObject:page];
			pageCount++;
		}
		else
			break;
	}
	
	NSSortDescriptor *pageSorter = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
	[pages sortUsingDescriptors:[NSArray arrayWithObject:pageSorter]];
	
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
	
	PageViewController *pageViewController;
	if(DeviceIsPad() == YES)
		pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController-iPad" bundle:nil];
	else
		pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
	[appDelegate showContentDetailViewController:pageViewController];
	[pageViewController release];
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

- (void)deletePageAtIndexPath:(NSIndexPath *)indexPath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if (indexPath.section == 0) {
		[mediaManager removeForPostID:[(Post *)[drafts objectAtIndex:indexPath.row] postID] andBlogURL:[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:@"url"]];
		
		NSManagedObject *objectToDelete = [drafts objectAtIndex:indexPath.row];
		[appDelegate.managedObjectContext deleteObject:objectToDelete];
		
        // Commit the change.
        NSError *error;
        if (![appDelegate.managedObjectContext save:&error]) {
			NSLog(@"Severe error when trying to delete local draft. Error: %@", error);
        }
		
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
		}
		else {
			NSNumber *pageID = [[pages objectAtIndex:indexPath.row] objectForKey:@"page_id"];
			BOOL result = [pageManager deletePage:pageID];
			if(result == YES)
				[self performSelectorOnMainThread:@selector(didDeletePageAtIndexPath:) withObject:indexPath waitUntilDone:NO];
		}
	}
	
    [pool release];
}

- (void)didDeleteDraftAtIndexPath:(NSIndexPath *)indexPath {
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
	[drafts removeObjectAtIndex:indexPath.row];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	[self refreshTable];
	[self loadPages];
}

- (void)didDeletePageAtIndexPath:(NSIndexPath *)indexPath {
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
	[pages removeObjectAtIndex:indexPath.row];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	[self refreshTable];
	[self loadPages];
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

- (void)addNewPage:(NSNotification *)notification {
	NSDictionary *newPage = [(NSDictionary *)[notification object] retain];
	[pages insertObject:newPage atIndex:0];
	[drafts removeAllObjects];
	drafts = [draftManager getType:@"page" forBlog:[dm.currentBlog valueForKey:@"blogid"]];
	[self refreshTable];
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
	[pageManager release];
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
