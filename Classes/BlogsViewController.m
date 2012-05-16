#import "BlogsViewController.h"
#import "BlogsTableViewCell.h"
#import "QuickPhotoViewController.h"
#import "UINavigationController+FormSheet.h"
#import "QuickPhotoUploadProgressController.h"
#import "UIImageView+Gravatar.h"
#import "SFHFKeychainUtils.h"
#import "CameraPlusPickerManager.h"

@interface BlogsViewController (Private)
- (void)setupPhotoButton;
- (void)setupReader;
@end

@interface BlogsViewController ()
@property (nonatomic, retain) Post *currentQuickPost;
@end

@implementation BlogsViewController
@synthesize resultsController, currentBlog, tableView;
@synthesize currentQuickPost = _currentQuickPost;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [quickPhotoButton release]; quickPhotoButton = nil;
    [readerButton release]; readerButton = nil;
    self.tableView = nil;
    [appDelegate setCurrentBlogReachability: nil];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(showAddBlogView:)] autorelease];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Blogs", @"") style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.isAccessibilityElement = YES;
    self.tableView.accessibilityLabel = @"Blog List";       // required for UIAutomation for iOS 4
	if([self.tableView respondsToSelector:@selector(setAccessibilityIdentifier:)]){
		self.tableView.accessibilityIdentifier = @"Blog List";  // required for UIAutomation for iOS 5		
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

	//status bar notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame:) name:DidChangeStatusBarFrame object:nil];
	
	[self checkEditButton];
	[self setupPhotoButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DidChangeStatusBarFrame object:nil];
	[super viewWillDisappear:animated];
}

- (void) checkEditButton{
	[self.tableView reloadData];
	[self.tableView endEditing:YES];
	self.tableView.editing = NO;
	
    [self cancel:self]; // Shows edit button
}

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification {
	[resultsController performFetch:nil];
	[appDelegate sendPushNotificationBlogsList]; 
	[self checkEditButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (DeviceIsPad())
		return YES;
    else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark -
#pragma mark UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogCell";
    BlogsTableViewCell *cell = (BlogsTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    
    CGRect frame = CGRectMake(8,8,35,35);
    UIImageView* asyncImage = [[[UIImageView alloc] initWithFrame:frame] autorelease];
    
    if (cell == nil) {
        cell = [[[BlogsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        [cell.imageView removeFromSuperview];
    }
    else {
        UIImageView* oldImage = (UIImageView*)[cell.contentView viewWithTag:999];
        [oldImage removeFromSuperview];
    }
    
	asyncImage.layer.cornerRadius = 4.0;
	asyncImage.layer.masksToBounds = YES;
	asyncImage.tag = 999;
    asyncImage.opaque = YES;
	[asyncImage setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
	[cell.contentView addSubview:asyncImage];
	
    NSString *firstLine = [blog blogName];
    NSString *secondLine = [blog hostURL];
    
    if (nil == firstLine || [firstLine isEqual:@""]) {
        firstLine = [blog hostURL];
        secondLine = @"";
    }
           
#if defined __IPHONE_3_0
    cell.textLabel.text = firstLine;
    cell.detailTextLabel.text = secondLine;
#elif defined __IPHONE_2_0
    cell.text = firstLine;
#endif

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

-(NSString *)tableView:(UITableView*)aTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return NSLocalizedString(@"Remove", @"");
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([aTableView cellForRowAtIndexPath:indexPath].editing) {
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
		
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
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
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
		
		Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
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
			[appDelegate sendPushNotificationBlogsList];
		} else {
			//the blog is using the network connection and cannot be stoped, show a message to the user
			UIAlertView *blogIsCurrentlyBusy = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"Info alert title")
																		  message:NSLocalizedString(@"The blog is syncing with the server. Please try later.", @"")
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
        && [[self.resultsController fetchedObjects] count] > 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
            || [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            wantsPhotoButton = YES;
        }
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]) {
            wantsReaderButton = YES;
        }
    }
    if (quickPhotoButton.superview != nil && !wantsPhotoButton) {
        [quickPhotoButton removeFromSuperview];
        [quickPhotoButton release]; quickPhotoButton = nil;
    }
    if (readerButton.superview != nil && !wantsReaderButton) {
        [readerButton removeFromSuperview];
        [readerButton release]; readerButton = nil;
    }
    CGRect tableFrame = self.tableView.frame;
    if (wantsReaderButton || wantsPhotoButton) {
        self.tableView.frame = CGRectMake(tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, 336);
    } else {
        self.tableView.frame = CGRectMake(tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, 416);
    }
    if (wantsPhotoButton && quickPhotoButton == nil) {
        quickPhotoButton = [QuickPhotoButton button];
        [quickPhotoButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
        CGFloat x = wantsReaderButton ? (self.view.bounds.size.width / 2) : 0;
        CGFloat width = wantsReaderButton ? (self.view.bounds.size.width / 2) : self.view.bounds.size.width;
        quickPhotoButton.frame = CGRectMake(x, self.view.bounds.size.height - 83, width, 83);
        [quickPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [quickPhotoButton setTitle:NSLocalizedString(@"Photo", @"") forState:UIControlStateNormal];     
        [quickPhotoButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [quickPhotoButton setTitleShadowColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [quickPhotoButton addTarget:self action:@selector(quickPhotoPost) forControlEvents:UIControlEventTouchUpInside];
        [quickPhotoButton retain];
        [self.view addSubview:quickPhotoButton];
        hasCameraPlus = [[CameraPlusPickerManager sharedManager] cameraPlusPickerAvailable];
    }
    if (wantsReaderButton && readerButton == nil) {
        readerButton = [QuickPhotoButton button];
		[readerButton setImage:[UIImage imageNamed:@"read.png"] forState:UIControlStateNormal];
        CGFloat width = wantsPhotoButton ? self.view.bounds.size.width / 2 : self.view.bounds.size.width;
        readerButton.frame = CGRectMake(0, self.view.bounds.size.height - 83, width, 83);
        [readerButton setTitle:NSLocalizedString(@"Read", @"") forState:UIControlStateNormal];
        [readerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [readerButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [readerButton setTitleShadowColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [readerButton addTarget:self action:@selector(showReader) forControlEvents:UIControlEventTouchUpInside];
        [readerButton retain];
        [self.view addSubview:readerButton];
    }
    if (!wantsReaderButton && readerViewController != nil) { 
        [readerViewController release]; 
        readerViewController = nil; 
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
            readerViewController = [[WPReaderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil]; 
            readerViewController.username = wpcom_username; 
            readerViewController.password = wpcom_password; 
            readerViewController.url = [NSURL URLWithString:kMobileReaderURL];
            [readerViewController view]; // Force web view preload 
        } 
    } 
} 


- (void)showReader { 
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)]; 
    if ( appDelegate.wpcomAvailable == NO ) {
        UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, no connection to WordPress.com.", @"")
																	  message:NSLocalizedString(@"The Reader is not available at this moment.", @"")
																	 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [connectionFailAlert show];
        [connectionFailAlert release];
        return;
    }
    [self setupReader]; 
    [self.navigationController pushViewController:readerViewController animated:YES]; 
} 

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType useCameraPlus:(BOOL)withCameraPlus {
    if (withCameraPlus) {
        CameraPlusPickerManager *picker = [CameraPlusPickerManager sharedManager];
        picker.callbackURLProtocol = @"wordpress";
        picker.maxImages = 1;
        picker.imageSize = 4096;
        CameraPlusPickerMode mode = (sourceType == UIImagePickerControllerSourceTypeCamera) ? CameraPlusPickerModeShootOnly : CameraPlusPickerModeLightboxOnly;
        [picker openCameraPlusPickerWithMode:mode];
    } else {
        QuickPhotoViewController *quickPhotoViewController = [[QuickPhotoViewController alloc] init];
        quickPhotoViewController.blogsViewController = self;
        quickPhotoViewController.sourceType = sourceType;
        [self.navigationController pushViewController:quickPhotoViewController animated:YES];
        [quickPhotoViewController release];
    }
}

- (void)showQuickPhoto:(UIImagePickerControllerSourceType)sourceType {
    [self showQuickPhoto:sourceType useCameraPlus:NO];
}

- (void)showQuickPhotoWithImage:(UIImage *)image isCameraPlus:(BOOL)cameraPlus {
    QuickPhotoViewController *quickPhotoViewController = [[QuickPhotoViewController alloc] init];
    quickPhotoViewController.blogsViewController = self;
    quickPhotoViewController.photo = image;
    quickPhotoViewController.isCameraPlus = cameraPlus;
    [self.navigationController pushViewController:quickPhotoViewController animated:YES];
    [quickPhotoViewController release];    
}

- (void)quickPhotoPost {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];

	UIActionSheet *actionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if (hasCameraPlus) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                      delegate:self 
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                        destructiveButtonTitle:nil 
                                             otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),NSLocalizedString(@"Add Photo from Camera+", @""), NSLocalizedString(@"Take Photo with Camera+", @""),nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                      delegate:self 
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                        destructiveButtonTitle:nil 
                                             otherButtonTitles:NSLocalizedString(@"Add Photo from Library", @""),NSLocalizedString(@"Take Photo", @""),nil];            
        }
	}
	else {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary];
        return;
	}
	
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:self.view];
    [appDelegate setAlertRunning:YES];
	
    [actionSheet release];
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

- (void)showBlog:(Blog *)blog animated:(BOOL)animated {
	BlogViewController *blogViewController = [[BlogViewController alloc] initWithNibName:@"BlogViewController" bundle:nil];
    blogViewController.blog = blog;
    [appDelegate setCurrentBlog:blog];
    
   [appDelegate setCurrentBlogReachability: [Reachability reachabilityWithHostname:blog.hostname] ];
    
	[self.navigationController pushViewController:blogViewController animated:animated];
	[blogViewController release];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake){
		
	}
}

- (void)setCurrentQuickPost:(Post *)currentQuickPost {
    if (currentQuickPost != _currentQuickPost) {
        if (_currentQuickPost) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PostUploaded" object:_currentQuickPost];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PostUploadFailed" object:_currentQuickPost];
            [_currentQuickPost release];
        }
        _currentQuickPost = [currentQuickPost retain];
        if (_currentQuickPost) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDidUploadSuccessfully:) name:@"PostUploaded" object:currentQuickPost];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUploadFailed:) name:@"PostUploadFailed" object:currentQuickPost];
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if(buttonIndex == 1) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeCamera];
    } else if(buttonIndex == 2) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypePhotoLibrary useCameraPlus:YES];
    } else if(buttonIndex == 3) {
        [self showQuickPhoto:UIImagePickerControllerSourceTypeCamera useCameraPlus:YES];
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

    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        resultsController = nil;
    }

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
    if (self.navigationController.visibleViewController == self) {
        [self setupPhotoButton];
    }
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

- (void)uploadQuickPhoto:(Post *)post {
    if (post != nil) {
        self.currentQuickPost = post;

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
        
        uploadController.label.textColor = [[[UIColor alloc] initWithRed:70.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0f] autorelease];
        uploadController.label.text = NSLocalizedString(@"Uploading Quick Photo...", @"");
        
        //show the upload dialog animation
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.6f];
        quickPhotoButton.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height + 83, frame.size.width, frame.size.height);
        frame = uploadController.view.frame;
        uploadController.view.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height - 83, frame.size.width, frame.size.height);
        
        [UIView commitAnimations];
    }
}

- (void)showQuickPhotoButton:(BOOL)delay {
    if (uploadController) {
        [UIView animateWithDuration:0.6f
                              delay:delay ? 1.2f : 0.0f
                            options:0
                         animations:^{
                             CGRect frame = quickPhotoButton.frame;
                             quickPhotoButton.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height - 83, frame.size.width, frame.size.height);
                             frame = uploadController.view.frame;
                             uploadController.view.frame = CGRectMake(frame.origin.x, self.view.bounds.size.height + 83, frame.size.width, frame.size.height);
                         } completion:^(BOOL finished) {
                             [uploadController.view removeFromSuperview];
                             [uploadController release]; uploadController = nil;
                         }];
    }
}

- (void)postDidUploadSuccessfully:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;
    self.currentQuickPost = nil;
    if (uploadController) {
        [UIView animateWithDuration:0.6f animations:^{
            [uploadController.spinner setAlpha:0.0f];
            uploadController.label.text = NSLocalizedString(@"Published!", @"");
            uploadController.label.textColor = [[UIColor alloc] initWithRed:0.0f green:128.0f/255.0f blue:0.0f alpha:1.0f];
            uploadController.label.frame = CGRectMake(uploadController.label.frame.origin.x, uploadController.label.frame.origin.y - 12, uploadController.label.frame.size.width, uploadController.label.frame.size.height);
        } completion:^(BOOL finished) {
            [self showQuickPhotoButton:YES];
        }];
    }
}

- (void)postUploadFailed:(NSNotification *)notification {
    appDelegate.isUploadingPost = NO;
    self.currentQuickPost = nil;
    [self showQuickPhotoButton:NO];
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
    [appDelegate setCurrentBlogReachability: nil];
    [quickPhotoButton release]; quickPhotoButton = nil;
    self.tableView = nil;
    [uploadController release];
    [readerViewController release]; 
    [super dealloc];
}

@end
