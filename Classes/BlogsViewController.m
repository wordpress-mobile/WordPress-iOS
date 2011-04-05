#import "BlogsViewController.h"
#import "BlogsTableViewCell.h"

@interface BlogsViewController (Private)
- (void) cleanUnusedMediaFileFromTmpDir;
@end

@implementation BlogsViewController
@synthesize resultsController, currentBlog;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [FlurryAPI logEvent:@"Blogs"];
	
    self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(showAddBlogView:)] autorelease];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Blogs", @"") style:UIBarButtonItemStyleBordered target:nil action:nil]; 
	self.tableView.allowsSelectionDuringEditing = YES;
    
    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"Error fetching request (Blogs) %@", [error localizedDescription]);
    } else {
        NSLog(@"fetched blogs: %@", [resultsController fetchedObjects]);
		//Start a check on the media files that should be deleted from disk
		[self performSelectorInBackground:@selector(cleanUnusedMediaFileFromTmpDir) withObject:nil];
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
			UIAlertView *ratingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"App Store Rating", @"") 
																  message:NSLocalizedString(@"If you like WordPress for iOS, we'd appreciate it if you could leave us a rating in the App Store. Would you like to do that now?", @"") 
																 delegate:self 
														cancelButtonTitle:NSLocalizedString(@"No", @"") 
														otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
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
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self cancel:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBlogWithoutAnimation) name:@"NewBlogAdded" object:nil];

	[self checkEditButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}


- (void) checkEditButton{
	[self.tableView reloadData];
	[self.tableView endEditing:YES];
	self.tableView.editing = NO;
	
	if([Blog countWithContext:appDelegate.managedObjectContext] > 0) {
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
		[self cancel:self];
	}
	else
		self.navigationItem.leftBarButtonItem = nil;
}

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification {
	[resultsController performFetch:nil];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogCell";
    BlogsTableViewCell *cell = (BlogsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Blog *blog = [resultsController objectAtIndexPath:indexPath];
    
    CGRect frame = CGRectMake(8,8,35,35);
    WPAsynchronousImageView* asyncImage = [[[WPAsynchronousImageView alloc]
                                            initWithFrame:frame] autorelease];
    
    if (cell == nil) {
        cell = [[[BlogsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        [cell.imageView removeFromSuperview];
    }
    else {
        WPAsynchronousImageView* oldImage = (WPAsynchronousImageView*)[cell.contentView viewWithTag:999];
        [oldImage removeFromSuperview];
    }
    
    asyncImage.isBlavatar = YES;
    if ([blog isWPcom])
        asyncImage.isWPCOM = YES;
	asyncImage.layer.cornerRadius = 4.0;
	asyncImage.layer.masksToBounds = YES;
	asyncImage.tag = 999;
	NSURL* url = [blog blavatarURL];
	[asyncImage loadImageFromURL:url];
	[cell.contentView addSubview:asyncImage];
	
#if defined __IPHONE_3_0
    cell.textLabel.text = [NSString decodeXMLCharactersIn:[blog blogName]];
    cell.detailTextLabel.text = [blog hostURL];
#else if defined __IPHONE_2_0
    cell.text = [NSString decodeXMLCharactersIn:[blog blogName]];
#endif

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

-(NSString *)tableView:(UITableView*)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Remove", @"");
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
	else {	// if ([self canChangeCurrentBlog]) {
        Blog *blog = [resultsController objectAtIndexPath:indexPath];
		[self showBlog:blog animated:YES];

		//we should keep a reference to the last selected blog
		if (DeviceIsPad() == YES) {
			self.currentBlog = blog;
		}
    }
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		Blog *blog = [resultsController objectAtIndexPath:indexPath];
		if([self canChangeBlog:blog]){
			[tableView beginUpdates];
			
            [FileLogger log:@"Deleted blog %@", blog];
			[appDelegate.managedObjectContext deleteObject:blog];
			
			[tableView endUpdates];
			NSError *error = nil;
			if (![appDelegate.managedObjectContext save:&error]) {
				WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
				exit(-1);
			}
		} else {
			//the blog is using the network connection and cannot be stoped, show a message to the user
			UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"")
																		  message:NSLocalizedString(@"The blog is synching with the server. Please try later.", @"")
																		 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
			[blogIsCurrentlyBusy show];
			[blogIsCurrentlyBusy release];
		}
		blog = nil;
	}
}


- (void)edit:(id)sender {
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
																	  style:UIBarButtonItemStyleDone
																	 target:self
																	 action:@selector(cancel:)] autorelease];
	[self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
	[self.tableView setEditing:YES animated:YES];
}

- (void)cancel:(id)sender {
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"")
																	style:UIBarButtonItemStylePlain
																   target:self
																   action:@selector(edit:)] autorelease];
    [self.navigationItem setLeftBarButtonItem:editButton animated:YES];
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark -
#pragma mark Custom methods


- (void) cleanUnusedMediaFileFromTmpDir {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *mediaToKeep = [NSMutableArray array];	
	//get a references to media files linked in a post
	for (Blog *blog in [resultsController fetchedObjects]) {
		NSSet *posts = blog.posts;
		if (posts && (posts.count > 0)) { 
			for (AbstractPost *post in posts) {
				//check for media file
				NSSet *mediaFiles = post.media;
				for (Media *media in mediaFiles) {
					[mediaToKeep addObject:media];
				}
				mediaFiles = nil;
			}
		}
		posts = nil;
	}
	
	//searches for jpg files within the app temp file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSArray *contentsOfDir = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
	
	for (NSString *currentPath in contentsOfDir)
		if([currentPath isMatchedByRegex:@".jpg$"]) {
			NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];
			
			BOOL keep = NO;
			//if the file is not referenced in any post we can delete it
			for (Media *currentMediaToKeepPath in mediaToKeep) {
				if([[currentMediaToKeepPath localURL] isEqualToString:filepath]) {
					keep = YES;
					break;
				}
			}
			
			if(keep == NO) {
				[fileManager removeItemAtPath:filepath error:NULL];
			}
		}
	
	[pool release];
}

- (BOOL)canChangeBlog:(Blog *) blog {
	//we should check  isSyncingPosts, isSyncingPages, isSyncingComments first bc is a fast check
	//we should first check if there are networks activities within the blog
	//we should re-check  isSyncingPosts, isSyncingPages, isSyncingComments;
	if(blog.isSyncingPosts || blog.isSyncingPages || blog.isSyncingComments)
		return NO;
	
	BOOL canDelete = YES;
	
	NSSet *posts = blog.posts;
	if (posts && (posts.count > 0)) { 
		for (AbstractPost *post in posts) {
			if(!canDelete) break;
			
			//check the post status
			if (post.remoteStatus == AbstractPostRemoteStatusPushing)
				canDelete = NO;
			
			//check for media file
			NSSet *mediaFiles = post.media;
			for (Media *media in mediaFiles) {
				if(!canDelete) break;
				if(media.remoteStatus == MediaRemoteStatusPushing) 
					canDelete = NO;
			}
			mediaFiles = nil;
		}
	}
	posts = nil;
	
	if(blog.isSyncingPosts || blog.isSyncingPages || blog.isSyncingComments)
		canDelete = NO;
	
	return canDelete;
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
	
	if (!DeviceIsPad()) {
        return;
    }
	switch (type) {
        case NSFetchedResultsChangeDelete:
			//deleted the last selected blog
			if(currentBlog && (currentBlog == anObject)) {
				WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
				[delegate showContentDetailViewController:nil];
				currentBlog = nil;
			}
			break;
		default:
			break;
    }
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    self.resultsController = nil;
	self.currentBlog = nil;
    [super dealloc];
}

@end
