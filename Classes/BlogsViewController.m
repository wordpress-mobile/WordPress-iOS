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
}

- (void)viewDidDisappear:(BOOL)animated {
    [self cancel:self];
}

- (void)viewWillAppear:(BOOL)animated {
	if([[BlogDataManager sharedDataManager] countOfBlogs] > 0)
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
	else
		self.navigationItem.leftBarButtonItem = nil;
	
	self.blogsList = nil;
	self.blogsList = [[[BlogDataManager sharedDataManager] blogsList] mutableCopy];
	
	[self.tableView reloadData];
	[self.tableView endEditing:YES];
	[BlogDataManager sharedDataManager].selectedBlogID = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NewBlogAdded" object:nil];
	[super viewWillDisappear:animated];
}

- (void)blogsRefreshNotificationReceived:(id)notification {
    [self.tableView reloadData];
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
        EditSiteViewController *blogDetailViewController = [[EditSiteViewController alloc] initWithNibName:@"EditSiteViewController" bundle:nil];
		blogDetailViewController.blogName = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:@"blogName"];
		blogDetailViewController.blogID = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:kBlogId];
		blogDetailViewController.url = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:@"url"];
		blogDetailViewController.host = [[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] objectForKey:kBlogHostName];

		if (DeviceIsPad() == YES)
		{
			UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];
			modalNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			[[CPopoverManager instance] setCurrentPopoverController:NULL];
			[[WordPressAppDelegate sharedWordPressApp].splitViewController presentModalViewController:modalNavigationController animated:YES];
			[modalNavigationController release];
		}
		else
		{
			[self.navigationController pushViewController:blogDetailViewController animated:YES];
		}
		[blogDetailViewController release];
		
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
		UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																		  style:UIBarButtonItemStyleDone
																		 target:self
																		 action:@selector(cancel:)] autorelease];
		[self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
		[self.tableView setEditing:YES animated:YES];
	}
}

- (void)cancel:(id)sender {
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
	
	[[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:indexPath.row];
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
