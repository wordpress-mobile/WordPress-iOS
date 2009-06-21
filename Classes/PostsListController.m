#import "PostsListController.h"
#import "BlogDataManager.h"
#import "PostDetailViewController.h"
#import "PostDetailEditController.h"
#import "DraftsListController.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPNavigationLeftButtonView.h"
#import "UIViewController+WPAnimation.h"

#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCConnection.h"

@interface PostsListController (private)

- (void) addPostsToolbarItems;
- (void)layoutSubviews;

@end


@implementation PostsListController

@synthesize postDetailViewController, postDetailEditController;

#define ROW_HEIGHT 60.0f
#define LOCALDRAFT_ROW_HEIGHT 44.0f

#define NAME_TAG 100
#define DATE_TAG 200
#define NEW_VERSION_ALERT_TAG 5111

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	rect = CGRectMake(0.0, 0.0, postsTableView.frame.size.width, ROW_HEIGHT);
	
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
#if defined __IPHONE_3_0
	rect = CGRectMake(cell.frame.origin.x+cell.frame.size.width-35, rect.origin.y-10, 20, 20);
#else if defined __IPHONE_2_0
    rect = CGRectMake(cell.frame.origin.x+cell.frame.size.width-25, rect.origin.y-10, 20, 20);
#endif	
	
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    activityView.tag = 201;
    activityView.hidden = YES;
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [cell.contentView addSubview:activityView];
    [activityView release];    
	
    return cell;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AsynchronousPostIsPosted" object:nil];
	
	[postDetailEditController release];
	[PostDetailViewController release];
	[super dealloc];
}



- (IBAction) showAddPostView:(id)sender {
	// Set current post to a new post
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] makeNewPostCurrent];
	
	self.postDetailViewController.mode = 0; 
	
	// Create a new nav controller to provide navigation bar with Cancel and Done buttons.
	// Ask for modal presentation
	[[self navigationController] pushViewController:self.postDetailViewController animated:YES];
	
}

- (PostDetailViewController *)postDetailViewController
{
	if (postDetailViewController == nil) {
		postDetailViewController = [[PostDetailViewController alloc] initWithNibName:@"PostDetailViewController" bundle:nil];
		postDetailViewController.postsListController = self;
	}
	return postDetailViewController;
}

#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//for local drafts
	return [[BlogDataManager sharedDataManager] countOfPostTitles] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//local drafts cell
	if( indexPath.row == 0 )
	{
		static NSString *draftsTableCellRowId = @"DraftsTableCellRowId";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:draftsTableCellRowId];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:draftsTableCellRowId] autorelease];
			//cell.font = [cell.font fontWithSize:MAIN_FONT_SIZE];
			UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, (LOCALDRAFT_ROW_HEIGHT - LABEL_HEIGHT)/2 , 80, LABEL_HEIGHT)];
			badgeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [badgeLabel setTag:99];
			badgeLabel.textColor = [UIColor lightGrayColor];
			badgeLabel.textAlignment = UITextAlignmentRight;
			//			badgeLabel.font = cell.font;
			badgeLabel.font = [badgeLabel.font fontWithSize:MAIN_FONT_SIZE];
			[[cell contentView] addSubview:badgeLabel];
			[badgeLabel release];
			
			//As these values won't change in the lifetime of this tableview so we can do this only for once.
			//cell.text =  @"Local Drafts";
			
#if defined __IPHONE_3_0	
			cell.textLabel.text = @"Local Drafts";
			cell.textLabel.font = [cell.textLabel.font fontWithSize:14.0f];
			cell.imageView.image = [UIImage imageNamed:@"DraftsFolder.png"];
#else if defined __IPHONE_2_0		
			cell.text = @"Local Drafts";
			cell.font = [cell.font fontWithSize:14.0f];
			cell.image = [UIImage imageNamed:@"DraftsFolder.png"];
#endif
			
			//cell.image = [UIImage imageNamed:@"DraftsFolder.png"];
			
		}
		
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		UILabel *bLabel = (UILabel *)[cell viewWithTag:99];
		NSNumber *count = [dm.currentBlog valueForKey:@"kDraftsCount"];
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
	else 	//post cell
	{
		static NSString *postsTableRowId = @"postsTableRowId";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:postsTableRowId];
		if (cell == nil) {
			cell = [self tableviewCellWithReuseIdentifier:postsTableRowId];         
			//[[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:postsTableRowId] autorelease];
		}
		
		cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
		
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		NSCharacterSet *whitespaceCS = [NSCharacterSet whitespaceCharacterSet];
		
		if ( [dm countOfPostTitles] ) 
		{
			id currentPost = [dm postTitleAtIndex:indexPath.row-1];
			NSString *title = [[currentPost valueForKey:@"title"] 
							   stringByTrimmingCharactersInSet:whitespaceCS];
			
			static NSDateFormatter *dateFormatter = nil;
			if (dateFormatter == nil) {
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
				[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			}
			
			UILabel *label = (UILabel *)[cell viewWithTag:NAME_TAG];
			label.text = title;
			
			label.textColor = ( connectionStatus ? [UIColor blackColor] : [UIColor grayColor] );
			
			NSDate *date = [currentPost valueForKey:@"date_created_gmt"];
			label = (UILabel *)[cell viewWithTag:DATE_TAG];
			label.text = [dateFormatter stringFromDate:date];
			
			// to stop activity indicator if it is running.
			
			UIActivityIndicatorView *aView = (UIActivityIndicatorView*)[cell viewWithTag:201];
            
			aView.hidden = YES;
			if([aView isAnimating]){
				[aView stopAnimating];
			}
			//to setback disclosure button in place of lock image.
			int aSyncPostVal = [[currentPost valueForKey:kAsyncPostFlag] intValue];
			UIView *view = cell.accessoryView;
			if([view isKindOfClass:[UIImageView class]] && aSyncPostVal==0){
				[cell setAccessoryView:nil];
			}
			
			// to set activity indicator anf lock image for background saving posts.
			if(aSyncPostVal == 1)
			{
				aView.hidden = NO;
				[aView startAnimating];
				//for Lock image
				UIImageView *lockImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lock.png"]];
				cell.accessoryView = lockImg;
				[lockImg release];
			}
		}
		
		return cell;		
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
//
//    return UITableViewCellAccessoryDisclosureIndicator; 
//}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	WPNavigationLeftButtonView *myview = [WPNavigationLeftButtonView createCopyOfView];  
    [myview setTarget:self withAction:@selector(goToHome:)];
    [myview setTitle:@"Blog"];
    UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:myview];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
    [myview release];
	
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsTableViewAfterPostSaved:) name:@"AsynchronousPostIsPosted" object:nil];
	
}

- (void)goToHome:(id)sender {
	[self popTransition:self.navigationController.view];
}

- (void)reachabilityChanged
{
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	
	[postsTableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.row != 0 )
		return ROW_HEIGHT;
	
	return LOCALDRAFT_ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//comment out this block to test on a local VM without internet access.  Add blog to app before turning off network
	//similar block in PagesListController and (probably) in Comments something
	
  	if( !connectionStatus && indexPath.row != 0 )
	{
		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Editing is not supported now."
														delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		alert1.tag=NEW_VERSION_ALERT_TAG;
		[alert1 show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
		
		[alert1 release];		
		
		[postsTableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	//comment out this block to test on a local VM without internet access.  Add blog to app before turning off network
	//similar block in PagesListController and (probably) in Comments something
	
	// Set current blog to blog at the index which was selected
	// A fake blog will be set up if Local Drafts row is selected
	[BlogDataManager sharedDataManager].isLocaDraftsCurrent = (indexPath.row == 0);
	
	if( indexPath.row == 0 )
	{
		DraftsListController *draftsListController = [[DraftsListController alloc] initWithNibName:@"DraftsList" bundle:nil];
		draftsListController.postsListController = self;
		
		BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
		[dataManager loadDraftTitlesForCurrentBlog];
		
		[[self navigationController] pushViewController:draftsListController animated:YES];
		[draftsListController release];
		return;
	}
	else
	{
        BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
		
        id currentPost = [dataManager postTitleAtIndex:indexPath.row-1];
        //code to return the selection if row is in middle of saving data.
		if([[currentPost valueForKey:kAsyncPostFlag] intValue]==1)
            return;
        
		[dataManager makePostAtIndexCurrent:indexPath.row-1];
		
		self.navigationItem.rightBarButtonItem = nil;
		self.postDetailViewController.hasChanges = NO; 
		self.postDetailViewController.mode = 1; 
		postDetailEditController.postDetailViewController=self.postDetailViewController;
		
		[[self navigationController] pushViewController:self.postDetailViewController animated:YES];
	}
}

#pragma mark -
- (void)viewWillAppear:(BOOL)animated {
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm postTitlesForBlog:[dm currentBlog]];
	dm.isLocaDraftsCurrent = NO;
	[dm loadPostTitlesForCurrentBlog];
	
	// we retain this controller in the caller (RootViewController) so load view does not get called 
	// everytime we navigate to the view
	// need to update the prompt and the title here as well as in loadView	
	NSString *blogName = [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"blogName"];
	
	self.title = [NSString stringWithFormat:@"%@", blogName];
	
	NSInteger totalposts = [[[dm currentBlog] valueForKey:@"totalposts"] integerValue];
	NSInteger newposts = [[[dm currentBlog] valueForKey:@"newposts"] integerValue];
	
	
	postsStatusButton.title = [NSString stringWithFormat:@"%d %@ (%d %@)",
							   totalposts,
							   NSLocalizedString(@"Posts", @PostsListController_title_Posts),
							   newposts, 
							   NSLocalizedString(@"New", @PostsListController_title_new)];
	
	
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[postsTableView reloadData];
	[postsTableView deselectRowAtIndexPath:[postsTableView indexPathForSelectedRow] animated:NO];
	[super viewWillAppear:animated];
}

- (BOOL)handleAutoSavedContext:(NSInteger)tag
{
	if( [[BlogDataManager sharedDataManager] makeAutoSavedPostCurrentForCurrentBlog] )
	{
		NSString *title = [[BlogDataManager sharedDataManager].currentPost valueForKey:@"title"];
		title = ( title == nil ? @"" : title );
		NSString * titleStr = [NSString stringWithFormat:@"Your last session was interrupted. Unsaved edits to the post \"%@\" were recovered.", title];
		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Recovered Post"
														 message:titleStr
														delegate:self 
											   cancelButtonTitle:nil
											   otherButtonTitles:@"Review Post", nil];
		
		alert1.tag = tag;
		
		[alert1 show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
		
		[alert1 release];
		return YES;
	}
	
	return NO;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self handleAutoSavedContext:0];
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
	//wait incase the other thread did not complete its work.
	while (self.navigationItem.rightBarButtonItem == nil){
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval:0.1]];
	}
	
	self.navigationItem.rightBarButtonItem = nil;
}

- (void)updatePostsTableViewAfterPostSaved:(NSNotification *)notification
{
    NSDictionary *postIdsDict=[notification userInfo];
    BlogDataManager *dm = [BlogDataManager sharedDataManager]; 
    [dm updatePostsTitlesFileAfterPostSaved:(NSMutableDictionary *)postIdsDict];
	
	//	if([[postIdsDict valueForKey:@"isCurrentPostDraft"] intValue]==1)
	//		[self.navigationController popViewControllerAnimated:YES]; 
	
	[dm loadPostTitlesForCurrentBlog];
	
	NSInteger totalposts = [[[dm currentBlog] valueForKey:@"totalposts"] integerValue];
	NSInteger newposts = [[[dm currentBlog] valueForKey:@"newposts"] integerValue];
	
	
	postsStatusButton.title = [NSString stringWithFormat:@"%d %@ (%d %@)",
							   totalposts,
							   NSLocalizedString(@"Posts", @PostsListController_title_Posts),
							   newposts, 
							   NSLocalizedString(@"New", @PostsListController_title_new)];
	[postsTableView reloadData];
	
}
- (IBAction)downloadRecentPosts:(id)sender {
	
	if( !connectionStatus ){
     	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
		
		UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
														 message:@"Sync operation is not supported now."
														delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		alert1.tag=NEW_VERSION_ALERT_TAG;
		[alert1 show];
		[alert1 release];		
		
		return;
	}	
	
	[self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm syncPostsForCurrentBlog];
	[dm loadPostTitlesForCurrentBlog];
	
	NSInteger totalposts = [[[dm currentBlog] valueForKey:@"totalposts"] integerValue];
	NSInteger newposts = [[[dm currentBlog] valueForKey:@"newposts"] integerValue];
	
	
	postsStatusButton.title = [NSString stringWithFormat:@"%d %@ (%d %@)",
							   totalposts,
							   NSLocalizedString(@"Posts", @PostsListController_title_Posts),
							   newposts, 
							   NSLocalizedString(@"New", @PostsListController_title_new)];
	[postsTableView reloadData];
	[self removeProgressIndicator];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( alertView.tag != NEW_VERSION_ALERT_TAG ) //When Connection Available.
	{
		[[BlogDataManager sharedDataManager] removeAutoSavedCurrentPostFile];
		self.navigationItem.rightBarButtonItem = nil;
		self.postDetailViewController.mode = 2;
		[[self navigationController] pushViewController:self.postDetailViewController animated:YES];
	}
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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

@end

