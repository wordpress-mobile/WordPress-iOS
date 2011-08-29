#import "BlogsViewController.h"
#import "BlogsTableViewCell.h"
#import "QuickPhotoViewController.h"
#import "UINavigationController+FormSheet.h"
#import "QuickPhotoUploadProgressController.h"

@interface BlogsViewController (Private)
- (void) cleanUnusedMediaFileFromTmpDir;
- (void)setupPhotoButton;
- (void)setupReader;
@end

@implementation BlogsViewController
@synthesize resultsController, currentBlog, tableView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidUnload {
    [quickPhotoButton release]; quickPhotoButton = nil;
    [readerButton release]; readerButton = nil;
    self.tableView = nil;
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [FlurryAPI logEvent:@"Blogs"];
	
    self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(showAddBlogView:)] autorelease];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Blogs", @"") style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	self.tableView.allowsSelectionDuringEditing = YES;
    
    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
//        NSLog(@"Error fetching request (Blogs) %@", [error localizedDescription]);
    } else {
//        NSLog(@"fetched blogs: %@", [resultsController fetchedObjects]);
		//Start a check on the media files that should be deleted from disk
		[self performSelectorInBackground:@selector(cleanUnusedMediaFileFromTmpDir) withObject:nil];
    }

    [self setupPhotoButton];
	
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

    //quick photo upload notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaDidUploadSuccessfully:) name:ImageUploadSuccessful object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaUploadFailed:) name:ImageUploadFailed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDidUploadSuccessfully:) name:@"PostUploaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUploadFailed:) name:@"PostUploadFailed" object:nil];
    
	//status bar notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame:) name:DidChangeStatusBarFrame object:nil];
	
	[self checkEditButton];
	[self setupPhotoButton];
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

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogCell";
    BlogsTableViewCell *cell = (BlogsTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
    cell.textLabel.text = [blog blogName];
    cell.detailTextLabel.text = [blog hostURL];
#elif defined __IPHONE_2_0
    cell.text = [blog blogName];
#endif

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

-(NSString *)tableView:(UITableView*)aTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Remove", @"");
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([aTableView cellForRowAtIndexPath:indexPath].editing) {
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
        [aTableView setEditing:NO animated:YES];
    }
	else {	// if ([self canChangeCurrentBlog]) {
        Blog *blog = [resultsController objectAtIndexPath:indexPath];
		[self showBlog:blog animated:YES];

		//we should keep a reference to the last selected blog
		if (DeviceIsPad() == YES) {
			self.currentBlog = blog;
		}
    }
	[aTableView deselectRowAtIndexPath:[aTableView indexPathForSelectedRow] animated:YES];
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		Blog *blog = [resultsController objectAtIndexPath:indexPath];
		if([self canChangeBlog:blog]){
			[aTableView beginUpdates];
			
            [FileLogger log:@"Deleted blog %@", blog];
			[appDelegate.managedObjectContext deleteObject:blog];
			
			[aTableView endUpdates];
			NSError *error = nil;
			if (![appDelegate.managedObjectContext save:&error]) {
				WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
				exit(-1);
			}
		} else {
			//the blog is using the network connection and cannot be stoped, show a message to the user
			UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
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

- (void)setupPhotoButton {
    BOOL wantsPhotoButton = NO;
    BOOL wantsReaderButton = NO;
    
    if (!DeviceIsPad()
        && [[resultsController fetchedObjects] count] > 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
            || [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            wantsPhotoButton = YES;
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]) {
            wantsReaderButton = YES;
        }
    }
    if (quickPhotoButton.superview != nil) {
        [quickPhotoButton removeFromSuperview];
        [quickPhotoButton release]; quickPhotoButton = nil;
    }
    if (readerButton.superview != nil) {
        [readerButton removeFromSuperview];
        [readerButton release]; readerButton = nil;
    }
    if (!wantsReaderButton && !wantsPhotoButton) {
        self.tableView.contentInset = UIEdgeInsetsZero;
    } else {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 83, 0);
    }
    if (wantsPhotoButton && quickPhotoButton == nil) {
        quickPhotoButton = [QuickPhotoButton button];
        [quickPhotoButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
        CGFloat x = wantsReaderButton ? (self.view.bounds.size.width / 2) : 0;
        CGFloat width = wantsReaderButton ? (self.view.bounds.size.width / 2) : self.view.bounds.size.width;
        quickPhotoButton.frame = CGRectMake(x, self.view.bounds.size.height - 83, width, 83);
        [quickPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if (wantsReaderButton) {
            [quickPhotoButton setTitle:nil forState:UIControlStateNormal];
        } else {
            [quickPhotoButton setTitle:NSLocalizedString(@"Quick Photo", @"") forState:UIControlStateNormal];            
        }
        [quickPhotoButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [quickPhotoButton setTitleShadowColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [quickPhotoButton addTarget:self action:@selector(quickPhotoPost) forControlEvents:UIControlEventTouchUpInside];
        [quickPhotoButton retain];
        [self.view addSubview:quickPhotoButton];
    }
    if (wantsReaderButton && readerButton == nil) {
        readerButton = [QuickPhotoButton button];
        CGFloat width = wantsPhotoButton ? self.view.bounds.size.width / 2 : self.view.bounds.size.width;
        readerButton.frame = CGRectMake(0, self.view.bounds.size.height - 83, width, 83);
        [readerButton setTitle:@"Reader" forState:UIControlStateNormal];
        [readerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [readerButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [readerButton setTitleShadowColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [readerButton addTarget:self action:@selector(showReader) forControlEvents:UIControlEventTouchUpInside];
        [readerButton retain];
        [self.view addSubview:readerButton];
    }
    if (wantsReaderButton) {
        [self setupReader];
    } else if (readerViewController != nil) {
        [readerViewController release]; readerViewController = nil;
        [readerNavigationController release]; readerNavigationController = nil;
    }
}

- (void)didChangeStatusBarFrame:(NSNotification *)notification {
	[self performSelectorOnMainThread:@selector(setupPhotoButton) withObject:nil waitUntilDone:NO];
}

- (void)setupReader {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    if (readerViewController == nil) {
        NSError *error = nil;
        NSString *wpcom_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        NSString *wpcom_password = [SFHFKeychainUtils getPasswordForUsername:wpcom_username
                                                              andServiceName:@"WordPress.com"
                                                                       error:&error];
        if (wpcom_username && wpcom_password) {
            readerViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
            readerViewController.needsLogin = YES;
            readerViewController.username = wpcom_username;
            readerViewController.password = wpcom_password;
            readerViewController.isReader = YES;
            readerViewController.url = [NSURL URLWithString:@"https://en.wordpress.com/reader/mobile/?preload=false"];
            [readerViewController view]; // Force web view preload
            readerNavigationController = [[UINavigationController alloc] initWithRootViewController:readerViewController];
        }
    }
}

- (void)showReader {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setupReader];
    
    [self.navigationController pushViewController:readerViewController animated:YES];
}

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType {
    QuickPhotoViewController *quickPhotoViewController = [[QuickPhotoViewController alloc] init];
    quickPhotoViewController.blogsViewController = self;
    quickPhotoViewController.sourceType = sourceType;
    [self.navigationController pushViewController:quickPhotoViewController animated:YES];
    [quickPhotoViewController release];
}

- (void)quickPhotoPost {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [FlurryAPI logEvent:@"QuickPhoto"];

	UIActionSheet *actionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
												  delegate:self 
										 cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
									destructiveButtonTitle:nil 
										 otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];
	}
	else {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        return;
	}
	
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:self.view];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
}

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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    } else if(buttonIndex == 1) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeCamera];
    }
}

#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex == 1) {
		// Take them to the App Store
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:NSLocalizedString(@"http://itunes.apple.com/us/app/wordpress/id335703880?mt=8", @"App URL, change 'us' for your local store code (test the link first)")]];
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
    [self setupPhotoButton];
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

- (void)uploadQuickPhoto:(Post *)post{
    
    appDelegate.isUploadingPost = YES;
    
    quickPicturePost = post;
    if (post != nil) {
        //remove the quick photo button w/ sexy animation
        CGRect frame = quickPhotoButton.frame;
        
        if (uploadController == nil) {
            uploadController = [[QuickPhotoUploadProgressController alloc] initWithNibName:@"QuickPhotoUploadProgressController" bundle:nil];
            uploadController.view.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height + 83, frame.size.width, frame.size.height);
            [self.view addSubview:uploadController.view];
        }
        
        if (uploadController.spinner.alpha == 0.0) {
            //reset the uploading view
            [uploadController.spinner setAlpha: 1.0f];
            uploadController.label.frame = CGRectMake(uploadController.label.frame.origin.x, uploadController.label.frame.origin.y + 12, uploadController.label.frame.size.width, uploadController.label.frame.size.height);
        }
        [uploadController.spinner startAnimating];
        uploadController.label.textColor = [[UIColor alloc] initWithRed:70.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0f];
        uploadController.label.text = NSLocalizedString(@"Uploading Quick Photo...", @"");
        
        //show the upload dialog animation
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6f];
        quickPhotoButton.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height + 83, frame.size.width, frame.size.height);
        frame = uploadController.view.frame;
        uploadController.view.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height - 83, frame.size.width, frame.size.height);
        
        [UIView commitAnimations];
 
        //upload the image
        [[post.media anyObject] performSelector:@selector(upload) withObject:nil];
    }
}

- (void)showQuickPhotoButton: (BOOL)delay{
    CGRect frame = quickPhotoButton.frame;
    [UIView beginAnimations:nil context:nil]; 
    [UIView setAnimationDuration:0.6f];
    if (delay)
        [UIView setAnimationDelay:1.2f];
    
    quickPhotoButton.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height - 83, frame.size.width, frame.size.height);
    
    frame = uploadController.view.frame;
    
    uploadController.view.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height + 83, frame.size.width, frame.size.height);
    
    [UIView commitAnimations];
}

- (void)mediaDidUploadSuccessfully:(NSNotification *)notification {
    
    Media *media = (Media *)[notification object];
    [media save];
    quickPicturePost.content = [NSString stringWithFormat:@"%@\n\n%@", [media html], quickPicturePost.content];
    [quickPicturePost upload];    
}

- (void)mediaUploadFailed:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;
    [self showQuickPhotoButton: NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the photo upload failed. The post has been saved as a Local Draft.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)postDidUploadSuccessfully:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;
    [UIView beginAnimations:nil context:nil]; 
    [UIView setAnimationDuration:0.6f];
    [uploadController.spinner setAlpha:0.0f];
    uploadController.label.text = NSLocalizedString(@"Published!", @"");
    uploadController.label.textColor = [[UIColor alloc] initWithRed:0.0f green:128.0f/255.0f blue:0.0f alpha:1.0f];
    uploadController.label.frame = CGRectMake(uploadController.label.frame.origin.x, uploadController.label.frame.origin.y - 12, uploadController.label.frame.size.width, uploadController.label.frame.size.height);
    [UIView commitAnimations];
    [self showQuickPhotoButton: YES];
}

- (void)postUploadFailed:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;
    [self showQuickPhotoButton: NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Quick Photo Failed", @"")
                                                    message:NSLocalizedString(@"Sorry, the photo publish failed. The post has been saved as a Local Draft.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
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
    [quickPhotoButton release]; quickPhotoButton = nil;
    self.tableView = nil;
    [quickPicturePost release];
    [uploadController release];
    [readerViewController release];
    [readerNavigationController release];
    [super dealloc];
}

@end
