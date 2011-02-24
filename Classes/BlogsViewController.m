#import "BlogsViewController.h"

@implementation BlogsViewController
@synthesize blogsList;
@synthesize resultsController;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [FlurryAPI logEvent:@"Blogs"];
	
    self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(showAddBlogView:)] autorelease];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Blogs" style:UIBarButtonItemStyleBordered target:nil action:nil]; 
	self.tableView.allowsSelectionDuringEditing = YES;
    
    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"Error fetching request (Blogs) %@", [error localizedDescription]);
    } else {
        NSLog(@"fetched blogs: %@", [resultsController fetchedObjects]);
    }

	// restore blog for iPad
	if (DeviceIsPad() == YES) {
		if (appDelegate.shouldLoadBlogFromUserDefaults) {
			//[self showBlog:NO];
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBlogWithoutAnimation) name:@"NewBlogAdded" object:nil];
	
	[self checkEditButton];
	
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

- (void) checkEditButton{
	if([Blog countWithContext:appDelegate.managedObjectContext] > 0)
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
	else
		self.navigationItem.leftBarButtonItem = nil;
}

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification {
	self.blogsList = nil;
	self.blogsList = [[[BlogDataManager sharedDataManager] blogsList] mutableCopy];
    [resultsController performFetch:nil];
    [self.tableView reloadData];
	[self checkEditButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (DeviceIsPad())
		return YES;
	
	return NO;
}

#pragma mark -
#pragma mark UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Blog *blog = [resultsController objectAtIndexPath:indexPath];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
#if defined __IPHONE_3_0
    cell.textLabel.text = [NSString decodeXMLCharactersIn:[blog blogName]];
    cell.detailTextLabel.text = [blog hostURL];
    cell.imageView.image = [blog favicon];
#else if defined __IPHONE_2_0
    cell.text = [NSString decodeXMLCharactersIn:[blog blogName]];
    cell.image = [blog favicon];
#endif

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.tableView cellForRowAtIndexPath:indexPath].editing) {
        Blog *blog = [resultsController objectAtIndexPath:indexPath];
		
		EditSiteViewController *editSiteViewController;
		editSiteViewController = [[EditSiteViewController alloc] initWithNibName:@"EditSiteViewController" bundle:nil];
		
        editSiteViewController.blog = blog;
		if (DeviceIsPad()) {
			UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:editSiteViewController];
			aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			aNavigationController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
			appDelegate.navigationController = aNavigationController;
			[appDelegate.splitViewController presentModalViewController:aNavigationController animated:YES];
			[self cancel:self];
			[aNavigationController release];
		}
		else {
			[self.navigationController pushViewController:editSiteViewController animated:YES];
		}
		[editSiteViewController release];
        [atableView setEditing:NO animated:YES];
    }
	else if ([self canChangeCurrentBlog]) {
        Blog *blog = [resultsController objectAtIndexPath:indexPath];
		[self showBlog:blog animated:YES];
    }
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && [self canChangeCurrentBlog]) {
		[tableView beginUpdates];
        Blog *blog = [resultsController objectAtIndexPath:indexPath];
        [appDelegate.managedObjectContext deleteObject:blog];
        blog = nil;
		[tableView endUpdates];
        NSError *error = nil;
        if (![appDelegate.managedObjectContext save:&error]) {
            NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
            exit(-1);
        }
    }
}

- (void)edit:(id)sender {
	if ([self canChangeCurrentBlog]) {
		[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
		UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
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


- (void)showAddBlogView:(id)sender {
	WelcomeViewController *welcomeView = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
	if(DeviceIsPad() == YES) {
		WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController-iPad" bundle:nil];
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
		aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        aNavigationController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
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

- (void)showBlogWithoutAnimation {
//    [self showBlog:NO];
}

- (void)showBlog:(Blog *)blog animated:(BOOL)animated {
    [WPReachability sharedReachability].hostName = blog.hostURL;
	
	BlogViewController *blogViewController = [[BlogViewController alloc] initWithNibName:@"BlogViewController" bundle:nil];
    blogViewController.blog = blog;
    [appDelegate setCurrentBlog:blog];
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
	if ([Blog countWithContext:appDelegate.managedObjectContext] == 0) {
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
#pragma mark Fetched results controller

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:appDelegate.managedObjectContext]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    NSFetchedResultsController *aResultsController = [[NSFetchedResultsController alloc]
                         initWithFetchRequest:fetchRequest
                         managedObjectContext:appDelegate.managedObjectContext
                         sectionNameKeyPath:nil
                         cacheName:nil];
    self.resultsController = aResultsController;
    resultsController.delegate = self;

    [aResultsController release];
    [fetchRequest release];
    [sortDescriptor release]; sortDescriptor = nil;
    [sortDescriptors release]; sortDescriptors = nil;

    return resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    self.resultsController = nil;
	[blogsList release]; blogsList = nil;
    [super dealloc];
}

@end
