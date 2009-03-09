//
//  PagesListController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesListController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "PageDetailViewController.h"
#import "PageDetailsController.h"
#import "PagesDraftListController.h"
#import "WordPressAppDelegate.h"


#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnection.h"

@interface PagesListController (private)

- (void) addPostsToolbarItems;
- (void)layoutSubviews;
-(void) setPageDetailsController;

@end


@implementation PagesListController

@synthesize pageDetailViewController,pageDetailsController;
#define ROW_HEIGHT 60.0f
#define LOCALDRAFT_ROW_HEIGHT 44.0f

#define NAME_TAG 100
#define DATE_TAG 200

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	rect = CGRectMake(0.0, 0.0, pagesTableView.frame.size.width, ROW_HEIGHT);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_OFFSET 10.0f
#define RIGHT_OFFSET 280.0f
	
#define MAIN_FONT_SIZE 15.0f
#define DATE_FONT_SIZE 12.0f
	
#define LABEL_HEIGHT 19.0f
#define DATE_LABEL_HEIGHT 15.0f
#define VERTICAL_OFFSET	2.0f
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT - DATE_LABEL_HEIGHT - VERTICAL_OFFSET ) / 2.0, 288, LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = NAME_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	//	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	
	rect = CGRectMake(LEFT_OFFSET, rect.origin.y+ LABEL_HEIGHT + VERTICAL_OFFSET , 320, DATE_LABEL_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = DATE_TAG;
	label.font = [UIFont systemFontOfSize:DATE_FONT_SIZE];
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor colorWithRed:0.560f green:0.560f blue:0.560f alpha:1];
	[label release];
    
    // Activity bar
    rect = CGRectMake(cell.frame.origin.x+cell.frame.size.width-25, rect.origin.y-10, 20, 20);
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    activityView.tag = 201;
    activityView.hidden = YES;
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [cell.contentView addSubview:activityView];
    [activityView release];    
	
    return cell;
}
- (IBAction) showAddNewPage:(id)sender {
	// Set current post to a new post
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] makeNewPageCurrent];
	
	self.pageDetailsController.mode = 0; 	
	self.navigationItem.rightBarButtonItem = nil;
	self.pageDetailsController.tabController.selectedIndex=0;
	[[self navigationController] pushViewController:self.pageDetailsController animated:YES];
}

- (void)dealloc {
	
	if ( pageDetailViewController != nil) {
		[pageDetailViewController autorelease];
		pageDetailViewController = nil;
	}
	[pageDetailsController release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
	[super dealloc];
}


#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[BlogDataManager sharedDataManager] countOfPageTitles];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if( indexPath.row == 0 )
	{
		static NSString *draftsTableCellRowId = @"DraftsTableCellRowId";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:draftsTableCellRowId];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:draftsTableCellRowId] autorelease];
			cell.font = [cell.font fontWithSize:MAIN_FONT_SIZE];
			UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, (LOCALDRAFT_ROW_HEIGHT - LABEL_HEIGHT)/2 , 80, LABEL_HEIGHT)];
			badgeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [badgeLabel setTag:99];
			badgeLabel.textColor = [UIColor lightGrayColor];
			badgeLabel.textAlignment = UITextAlignmentRight;
			badgeLabel.font = cell.font;
			[[cell contentView] addSubview:badgeLabel];
			[badgeLabel release];
			
			//As these values won't change in the lifetime of this tableview so we can do this only for once.
			cell.text =  @"Local Drafts";
			cell.image = [UIImage imageNamed:@"DraftsFolder.png"];
		}
		
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		UILabel *bLabel = (UILabel *)[cell viewWithTag:99];
		NSNumber *count = [dm.currentBlog valueForKey:@"kPageDraftsCount"];
		if( [count intValue] )
		{
			int c = ( count == nil ? 0 : [count intValue] );
			bLabel.text = [NSString stringWithFormat:@"(%d)", c];
		}
		else {
			bLabel.text = [NSString stringWithFormat:@""];
		}
		
		[[cell contentView] bringSubviewToFront:bLabel];
		
		return cell;
	}
	else
	{
		static NSString *pagesTableRowId = @"pagesTableRowId";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pagesTableRowId];
		if (cell == nil) {
			cell = [self tableviewCellWithReuseIdentifier:pagesTableRowId];
		}
		
		cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
		
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
		
		if ( [dm countOfPageTitles] ) 
		{
			id currentPage = [dm pageTitleAtIndex:indexPath.row-1];
			
			NSString *title = [[currentPage valueForKey:@"title"] 
							   stringByTrimmingCharactersInSet:whitespaceCS];
			
			if( title == nil || ([title length] == 0) )
				title = @"(no title)" ;
			
			

			static NSDateFormatter *dateFormatter = nil;
			if (dateFormatter == nil) {
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
				[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			}
			
			UILabel *label = (UILabel *)[cell viewWithTag:NAME_TAG];
			label.text = title;
			label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
			NSDate *date = [currentPage valueForKey:@"date_created_gmt"];
			label = (UILabel *)[cell viewWithTag:DATE_TAG];
			label.text = [dateFormatter stringFromDate:date];			
		}
	return cell;
	}
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	
	[BlogDataManager sharedDataManager].isLocaDraftsCurrent = (indexPath.row == 0);

	if( indexPath.row == 0 )
	{
		PagesDraftListController *pagesDraftsListController = [[PagesDraftListController alloc] initWithNibName:@"PagesDraftListController" bundle:nil];
		pagesDraftsListController.pagesListController = self;
		
		BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
		[dataManager loadPageDraftTitlesForCurrentBlog];
		
		[[self navigationController] pushViewController:pagesDraftsListController animated:YES];
		[pagesDraftsListController release];
		return;
	}
	else
	{
		if( !connectionStatus)
		{
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Editing is not supported now."
															delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			
			[alert1 show];
			WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
			[delegate setAlertRunning:YES];
			
			[alert1 release];		
			
			[pagesTableView deselectRowAtIndexPath:indexPath animated:YES];
			return;
		}
		
		
		self.pageDetailsController.tabController.selectedIndex=0;
		BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
		[dataManager makePageAtIndexCurrent:indexPath.row-1];	
		

	//	[self setPageDetailsController ];
		self.pageDetailsController.mode = 1; 	
		self.navigationItem.rightBarButtonItem = nil;
		self.pageDetailsController.hasChanges = NO; 	
		[[self navigationController] pushViewController:self.pageDetailsController animated:YES];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setPageDetailsController ];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];	
}

- (void)reachabilityChanged
{
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	
	[pagesTableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.row != 0 )
		return ROW_HEIGHT;
	
	return LOCALDRAFT_ROW_HEIGHT;
}


#pragma mark -
- (void)viewWillAppear:(BOOL)animated {
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm loadPageTitlesForCurrentBlog];
	dm.isLocaDraftsCurrent = NO;

	self.title=@"Pages";
	
	NSInteger totalpages = [[[dm currentBlog] valueForKey:@"totalpages"] integerValue];
	NSInteger newpages = [[[dm currentBlog] valueForKey:@"newpages"] integerValue];
	
	pagessStatusButton.title = [NSString stringWithFormat:@"%d %@ (%d %@)",
							   totalpages,
							   @"Pages",
							   newpages, 
							   @"New"];
	
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[pagesTableView reloadData];
	[pagesTableView deselectRowAtIndexPath:[pagesTableView indexPathForSelectedRow] animated:NO];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)addProgressIndicator
{
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	[aiv startAnimating]; 
	[aiv release];
	
	self.navigationItem.rightBarButtonItem = activityButtonItem;
	[activityButtonItem release];
	[apool release];
}

- (void)removeProgressIndicator
{
	while (self.navigationItem.rightBarButtonItem == nil){
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	self.navigationItem.rightBarButtonItem = nil;
}


- (IBAction)downloadRecentPages:(id)sender {
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
	[sharedBlogDataManager syncPagesForBlog:[sharedBlogDataManager currentBlog]];
	[sharedBlogDataManager loadPageTitlesForCurrentBlog];
	
	[pagesTableView reloadData];
	[self removeProgressIndicator];
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

-(void)setPageDetailsController
{
	if(self.pageDetailsController == nil)
		self.pageDetailsController = [[PageDetailsController alloc] initWithNibName:@"PageDetailsController" bundle:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
}
@end