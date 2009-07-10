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
#import "Reachability.h"
#import "WordPressAppDelegate.h"

#define LOCAL_DRAFTS_SECTION    0
#define PAGES_SECTION           1
#define NUM_SECTIONS			2

#define REFRESH_BUTTON_HEIGHT   50

@interface PagesViewController (Private)
- (void)loadPages;
- (void)setPageDetailsController;
- (void)refreshHandler;
- (void)downloadRecentPages;
- (void)showAddNewPage;
- (void)addRefreshButton;
@end


@implementation PagesViewController

@synthesize newButtonItem, pageDetailViewController, pageDetailsController;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
    self.tableView.backgroundColor = kTableBackgroundColor;
    
    [self addRefreshButton];    
	[self setPageDetailsController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
	
	newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
																  target:self
																  action:@selector(showAddNewPage)];
}

- (void)viewWillAppear:(BOOL)animated {
	connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
	
	[self loadPages];
	[super viewWillAppear:animated];
}

- (void)dealloc {	
	if (pageDetailViewController != nil) {
		[pageDetailViewController autorelease];
		pageDetailViewController = nil;
	}
    
	[pageDetailsController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
    
    [newButtonItem release];
	[refreshButton release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
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
	if (section == LOCAL_DRAFTS_SECTION) {
		return [[BlogDataManager sharedDataManager] numberOfPageDrafts];
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
        page = [dm pageTitleAtIndex:indexPath.row];
    }
	
	cell.post = page;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	dataManager.isLocaDraftsCurrent = (indexPath.section == LOCAL_DRAFTS_SECTION);
    
	if (indexPath.section == LOCAL_DRAFTS_SECTION) {
		id currentDraft = [dataManager pageDraftTitleAtIndex:indexPath.row];
		
		// Bail out if we're in the middle of saving the draft.
		if ([[currentDraft valueForKey:kAsyncPostFlag]intValue] == 1) {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			return;
		}
		
		[dataManager makePageDraftAtIndexCurrent:indexPath.row];
	} else {
		if (!connectionStatus) {
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Editing is not supported now."
															delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			
			[alert1 show];
			[delegate setAlertRunning:YES];
			[alert1 release];		
			
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
	
	self.pageDetailsController.mode = 1;
	[delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return POST_ROW_HEIGHT;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.section == LOCAL_DRAFTS_SECTION);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	
	if (indexPath.section == LOCAL_DRAFTS_SECTION) {
		[dataManager deletePageDraftAtIndex:indexPath.row forBlog:[dataManager currentBlog]];
	} else {
		// TODO: delete the page.
	}
	
	[self loadPages];
}

#pragma mark -
#pragma mark Private methods

- (void)loadPages {	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	dm.isLocaDraftsCurrent = NO;
	
	[dm loadPageTitlesForCurrentBlog];
	[dm loadPageDraftTitlesForCurrentBlog];
	
	[self.tableView reloadData];
}

- (void)reachabilityChanged {
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
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
	[self performSelectorInBackground:@selector(downloadRecentPages) withObject:nil];
}

- (void)downloadRecentPages {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    
	[dm syncPagesForBlog:[dm currentBlog]];
	[self loadPages];
	
	[refreshButton stopAnimating];
	[pool release];
}

- (void)showAddNewPage {
	[[BlogDataManager sharedDataManager] makeNewPageCurrent];	
	self.pageDetailsController.mode = 0;
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//Code to disable landscape when alert is raised.
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

-(void)setPageDetailsController {
	if (self.pageDetailsController == nil) {
		self.pageDetailsController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
}

@end
