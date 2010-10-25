#import "BlogsViewController.h"

@implementation BlogsViewController
@synthesize blogsList;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(showAddBlogView:)] autorelease];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Blogs" style:UIBarButtonItemStyleBordered target:nil action:nil]; 
	self.tableView.allowsSelectionDuringEditing = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBlogWithoutAnimation) name:@"NewBlogAdded" object:nil];
    
	// restore blog for iPad
	if (DeviceIsPad() == YES) {
		if (appDelegate.shouldLoadBlogFromUserDefaults) {
			[self showBlog:NO];
		}
	}
	
	// Check to see if we should prompt about rating in the App Store
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	// Check for a launch counter
	if([prefs objectForKey:@"launch_count"] == nil) {
		// If it doesn't exist, add it starting at 1
		[prefs setObject:[NSNumber numberWithInt:1] forKey:@"launch_count"];
	}
	else {
		// If we've launched the app 80 times...
		if(([[prefs objectForKey:@"launch_count"] isEqualToNumber:[NSNumber numberWithInt:80]]) && 
		   ([prefs objectForKey:@"has_displayed_rating_prompt"] == nil)) {
			
			// If this is the 30th launch, display the alert
			UIAlertView *ratingAlert = [[UIAlertView alloc] initWithTitle:@"App Store Rating" 
																  message:@"If you like WordPress for iOS, we'd appreciate it if you could leave us a rating in the App Store. Would you like to do that now?" 
																 delegate:self 
														cancelButtonTitle:@"No" 
														otherButtonTitles:@"Yes", nil];
			[ratingAlert show];
			[ratingAlert release];
			
			// Don't bug them again
			[prefs setObject:@"1" forKey:@"has_displayed_rating_prompt"];
		}
		else if([[prefs objectForKey:@"launch_count"] intValue] < 80) {
			// Increment our launch count
			int launchCount = [[prefs objectForKey:@"launch_count"] intValue];
			launchCount++;
			[prefs setObject:[NSNumber numberWithInt:launchCount] forKey:@"launch_count"];
		}
		[prefs synchronize];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
    [self cancel:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
//	[appDelegate syncBlogs];
//	[appDelegate syncBlogCategoriesAndStatuses];
	
	if([[BlogDataManager sharedDataManager] countOfBlogs] > 0)
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
	else
		self.navigationItem.leftBarButtonItem = nil;
	
	self.blogsList = nil;
	self.blogsList = [[[BlogDataManager sharedDataManager] blogsList] mutableCopy];
	
	[self.tableView reloadData];
	[self.tableView endEditing:YES];
	[BlogDataManager sharedDataManager].selectedBlogID = nil;
	
	self.tableView.editing = NO;
	[self cancel:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification {
	self.blogsList = nil;
	self.blogsList = [[[BlogDataManager sharedDataManager] blogsList] mutableCopy];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return blogsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	Blog *blog = [[Blog alloc] initWithIndex:indexPath.row];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
#if defined __IPHONE_3_0
    cell.textLabel.text = [NSString decodeXMLCharactersIn:[[blogsList objectAtIndex:(indexPath.row)] valueForKey:@"blogName"]];
    cell.imageView.image = [blog favicon];
#else if defined __IPHONE_2_0
    cell.text = [NSString decodeXMLCharactersIn:[[blogsList objectAtIndex:(indexPath.row)] valueForKey:@"blogName"]];
    cell.image = [blog favicon];
#endif

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	[blog release];

    return cell;
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.tableView cellForRowAtIndexPath:indexPath].editing) {
        [[BlogDataManager sharedDataManager] copyBlogAtIndexCurrent:(indexPath.row)];
		
		EditSiteViewController *editSiteViewController;
		if (DeviceIsPad() == YES)
			editSiteViewController = [[EditSiteViewController alloc] initWithNibName:@"EditSiteViewController-iPad" bundle:nil];
		else
			editSiteViewController = [[EditSiteViewController alloc] initWithNibName:@"EditSiteViewController" bundle:nil];
		
		editSiteViewController.blogName = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:@"blogName"];
		editSiteViewController.blogID = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:kBlogId];
		editSiteViewController.url = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:@"url"];
		editSiteViewController.host = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:kBlogHostName];
		
		if(DeviceIsPad() == YES) {
			UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:editSiteViewController];
			aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			appDelegate.navigationController = aNavigationController;
			[appDelegate.splitViewController presentModalViewController:aNavigationController animated:YES];
			[aNavigationController release];
		}
		else {
			[self.navigationController pushViewController:editSiteViewController animated:YES];
		}
		
		[editSiteViewController release];
		
    }
	else if ([self canChangeCurrentBlog]) {
		[[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:(indexPath.row)];
		[[BlogDataManager sharedDataManager] setSelectedBlogID:
		[[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:@"blogid"]];
		[self showBlog:YES];
    }
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && [self canChangeCurrentBlog]) {
		[tableView beginUpdates];
		[self performSelectorInBackground:@selector(deleteBlog:) withObject:indexPath];
		[blogsList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						 withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];
    }
}

- (void)edit:(id)sender {
	if ([self canChangeCurrentBlog]) {
		[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
		UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																		  style:UIBarButtonItemStyleDone
																		 target:self
																		 action:@selector(cancel:)] autorelease];
		[self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
		[self.tableView setEditing:YES animated:YES];
	}
}

- (void)cancel:(id)sender {
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithTitle:@"Edit"
																	style:UIBarButtonItemStylePlain
																   target:self
																   action:@selector(edit:)] autorelease];
    [self.navigationItem setLeftBarButtonItem:editButton animated:YES];
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark -
#pragma mark Custom methods

- (BOOL)canChangeCurrentBlog {
	return YES;
}

- (void)showBlogDetailModalViewForNewBlog:(id)inSender {
    [self showBlogDetailModalViewForNewBlogWithAnimation:YES];
}

- (void)showAddBlogView:(id)sender {
	WelcomeViewController *welcomeView = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
	if(DeviceIsPad() == YES) {
		WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController-iPad" bundle:nil];
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		appDelegate.navigationController = aNavigationController;
		[appDelegate.splitViewController presentModalViewController:aNavigationController animated:YES];
		[aNavigationController release];
		[welcomeViewController release];
	}
	else {
		[self.navigationController pushViewController:welcomeView animated:YES];
	}
	[welcomeView release];
}

- (void)showBlogDetailModalViewForNewBlogWithAnimation:(BOOL)animate {
	if ([self canChangeCurrentBlog]) {
		[[BlogDataManager sharedDataManager] makeNewBlogCurrent];
		[self showBlogDetailModalViewWithAnimation:animate];
	}
}

- (void)showBlogDetailModalViewWithAnimation:(BOOL)animate {
	EditSiteViewController *blogDetailViewController = [[[EditSiteViewController alloc] initWithNibName:@"EditSiteViewController" bundle:nil] autorelease];
	UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];
	if (DeviceIsPad() == YES)
	{
		modalNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
		[[CPopoverManager instance] setCurrentPopoverController:NULL];
		[[WordPressAppDelegate sharedWordPressApp].splitViewController presentModalViewController:modalNavigationController animated:animate];
	}
	else
	{
		[[WordPressAppDelegate sharedWordPressApp].navigationController presentModalViewController:modalNavigationController animated:animate];
	}
	
	
	[modalNavigationController release];
}

- (void)showBlogWithoutAnimation {
    [self showBlog:NO];
}

- (void)showBlog:(BOOL)animated {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    NSString *url = [dataManager.currentBlog valueForKey:@"url"];
	
    if (url != nil &&[url length] >= 7 &&[url hasPrefix:@"http://"]) {
        url = [url substringFromIndex:7];
    }
	
    if (url != nil &&[url length]) {
        url = @"wordpress.com";
    }
	
    [Reachability sharedReachability].hostName = url;
	
	BlogViewController *blogViewController = [[BlogViewController alloc] initWithNibName:@"BlogViewController" bundle:nil];
	[self.navigationController pushViewController:blogViewController animated:animated];
	[blogViewController release];
}

- (void)deleteBlog:(NSIndexPath *)indexPath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
	[[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:indexPath.row];
	
	MediaManager *mediaManager = [[MediaManager alloc] init];
	[mediaManager removeForBlogURL:[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:@"url"]];
	[mediaManager release];
	
	[[BlogDataManager sharedDataManager] removeCurrentBlog];
	
	[self performSelectorOnMainThread:@selector(didDeleteBlogSuccessfully:) withObject:indexPath waitUntilDone:NO];
	
	[pool release];
}

- (void)didDeleteBlogSuccessfully:(NSIndexPath *)indexPath {
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsEditedNotification" object:nil];
	if ([[BlogDataManager sharedDataManager] countOfBlogs] == 0) {
		self.navigationItem.leftBarButtonItem = nil;
		[self.tableView setEditing:NO animated:YES];
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake){
		
	}
}

#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
		// Take them to the App Store
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAppStoreURL]];
	}
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[blogsList release];
    [super dealloc];
}

@end
