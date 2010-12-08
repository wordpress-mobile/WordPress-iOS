#import "EditPostViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "CPopoverManager.h"

NSTimeInterval kAnimationDuration = 0.3f;

@implementation EditPostViewController

@synthesize postDetailViewController, selectionTableViewController, segmentedTableViewController, leftView;
@synthesize infoText, urlField, bookMarksArray, selectedLinkRange, currentEditingTextField, isEditing, initialLocation;
@synthesize editingDisabled, editCustomFields, isCustomFieldsEnabledForThisPost, statuses, isLocalDraft, normalTextFrame;
@synthesize textView, contentView, subView, textViewContentView, statusTextField, categoriesTextField, titleTextField;
@synthesize tagsTextField, textViewPlaceHolderField, tagsLabel, statusLabel, categoriesLabel, titleLabel, customFieldsEditButton;
@synthesize locationButton, locationSpinner, newCategoryBarButtonItem, autosaveButton;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"Write";
	statuses = [NSArray arrayWithObjects:@"Local Draft", @"Draft", @"Private", @"Pending Review", @"Published", nil];
    titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    tagsTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    categoriesTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    categoriesLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    tagsLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    tagsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [contentView bringSubviewToFront:textView];
	normalTextFrame = textView.frame;
	
    if (!leftView) {
        leftView = [WPNavigationLeftButtonView createCopyOfView];
        [leftView setTitle:@"Posts"];
    }
	
    [leftView setTitle:@"Posts"];
    [leftView setTarget:self withAction:@selector(cancelView:)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:@"EditPostViewShouldHideKeyboard" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"EditPostViewShouldSave" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publish) name:@"EditPostViewShouldPublish" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkAutosaves) name:@"AutosaveNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];
	//[self hideAutosaveButton];
	
    //JOHNB TODO: Add a check here for the presence of custom fields in the data model
    // if there are, set isCustomFieldsEnabledForThisPost BOOL to true
    isCustomFieldsEnabledForThisPost = [self checkCustomFieldsMinusMetadata];
    //call a helper to set originY for textViewContentView
	
	if (editingDisabled) {
		titleTextField.enabled = NO;
		titleTextField.textColor = [UIColor grayColor];
		
		tagsTextField.enabled = NO;
		tagsTextField.textColor = [UIColor grayColor];
		
		categoriesTextField.enabled = NO;
		categoriesTextField.textColor = [UIColor grayColor];
		
		statusTextField.enabled = NO;
		statusTextField.textColor = [UIColor grayColor];
		
		textView.editable = NO;
	}
	
	self.statusTextField.text = @"Local Draft";
	[self restoreUnsavedPost];
}

- (void)viewWillAppear:(BOOL)animated {
	//WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [super viewWillAppear:animated];
	//[self dismissModalViewControllerAnimated:YES];
	[self syncCategoriesAndStatuses];
    //isCustomFieldsEnabledForThisPost = [self checkCustomFieldsMinusMetadata];
    isCustomFieldsEnabledForThisPost = NO;
	
	// Update older geolocation setting to new format
	BOOL geolocationSetting = NO;
	NSString *geotaggingSettingName = [NSString stringWithFormat:@"%@-Geotagging", [[[BlogDataManager sharedDataManager] currentBlog] valueForKey:kBlogId]];
	if([[[BlogDataManager sharedDataManager] currentBlog] objectForKey:kGeolocationSetting] == nil) {
		if(![[NSUserDefaults standardUserDefaults] boolForKey:geotaggingSettingName])
		{
			[[[BlogDataManager sharedDataManager] currentBlog] setValue:@"NO" forKey:kGeolocationSetting];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:geotaggingSettingName];
			geolocationSetting = NO;
		}
		else {
			[[[BlogDataManager sharedDataManager] currentBlog] setValue:@"YES" forKey:kGeolocationSetting];
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:geotaggingSettingName];
			geolocationSetting = YES;
		}
	}
	else
		geolocationSetting = [[[[BlogDataManager sharedDataManager] currentBlog] objectForKey:kGeolocationSetting] boolValue];
	
	if(geolocationSetting == YES) {
		// Geolocation enabled, let's get this party started.
		locationButton.hidden = NO;
		
		// If the post has already been geotagged, reflect this in the icon, and store the
		// location so we can determine any changes to location in the future
		if([self isPostGeotagged])
		{
			[locationButton setImage:[UIImage imageNamed:@"hasLocation.png"] forState:UIControlStateNormal];
			
			CLLocation *postLocation = [self getPostLocation];
			if((postLocation != nil) && (initialLocation != nil))
			{
				// If our location has changed from its initial value, show the Save button
				if((initialLocation.coordinate.latitude != postLocation.coordinate.latitude) ||
				   (initialLocation.coordinate.longitude != postLocation.coordinate.longitude))
					postDetailViewController.hasChanges = YES;
			}
		}
		else
		{
			// Post does not have a geotag at this point, so check for a removed geotag
			if((initialLocation != nil) && ([self getPostLocation] == nil))
				postDetailViewController.hasChanges = YES;
			
			// Set our geo button back to normal
			[locationButton setImage:[UIImage imageNamed:@"getLocation.png"] forState:UIControlStateNormal];
		}
	}
	else {
		// Geolocation disabled, hide our geo button.
		locationButton.hidden = YES;
	}
	
	[locationButton setNeedsLayout];
	[locationButton setNeedsDisplay];
	
	[postDetailViewController checkAutosaves];
	postDetailViewController.navigationItem.title = @"Write";
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//[self dismissModalViewControllerAnimated:YES];
	[titleTextField resignFirstResponder];
	[tagsTextField resignFirstResponder];
	[categoriesTextField resignFirstResponder];
	[statusTextField resignFirstResponder];
	[textView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return NO;
}

- (void)disableInteraction {
	editingDisabled = YES;
}

#pragma mark -

- (BOOL)isPostPublished {
	BOOL result = NO;
	if(isLocalDraft == YES) {
		result = NO;
	}
	else {
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
		
		if([[status lowercaseString] isEqualToString:@"published"])
			result = YES;
		else
			result = NO;
	}
	
	return result;
}

- (void)refreshUIForCompose {
	self.isLocalDraft = YES;
	postDetailViewController.wasLocalDraft = YES;
	self.navigationItem.title = @"Write";
    titleTextField.text = @"";
    tagsTextField.text = @"";
	[textView setText:kTextViewPlaceholder];
	[textView setTextColor:[UIColor lightGrayColor]];
    textViewPlaceHolderField.hidden = NO;
    categoriesTextField.text = @"";
	self.isLocalDraft = YES;
	[postDetailViewController.post setStatus:@"Local Draft"];
	statusTextField.text = @"Local Draft";
}

- (void)refreshUIForCurrentPost {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	AutosaveManager *autosaveManager = [[AutosaveManager alloc] init];
	DraftManager *draftManager = [[DraftManager alloc] init];
	
	NSString *currentPostID = nil;
	if(([dm.currentPost objectForKey:@"postid"] != nil) && ([dm.currentPost objectForKey:@"postid"] != @""))
		currentPostID = [dm.currentPost objectForKey:@"postid"];
	
	if((currentPostID == nil) && (appDelegate.postID != nil) && (appDelegate.postID.length > 6)) {		
		Post *post = [[draftManager get:appDelegate.postID] retain];
		if(post != nil) {
			if([[post isLocalDraft] isEqualToNumber:[NSNumber numberWithInt:1]])
				self.isLocalDraft = YES;
			postDetailViewController.navigationItem.title = post.postTitle;
			self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
														style:UIBarButtonItemStyleBordered target:nil action:nil];
			
			titleTextField.text = post.postTitle;
			tagsTextField.text = post.tags;
			statusTextField.text = post.status;
			categoriesTextField.text = post.categories;
			
			
			if(post.content == nil) {
				textViewPlaceHolderField.hidden = NO;
				textView.text = @"";
			}
			else {
				textViewPlaceHolderField.hidden = YES;
				textView.text = post.content;
			}
			
			[postDetailViewController setPost:post];
            [post release];
		}
	}
	else {
		self.isLocalDraft = NO;
		NSString *description = [dm.currentPost valueForKey:@"description"];
		NSString *moreText = [dm.currentPost valueForKey:@"mt_text_more"];
		
		if (!description ||[description length] == 0) {
			textViewPlaceHolderField.hidden = NO;
			textView.text = @"";
		} else {
			textViewPlaceHolderField.hidden = YES;
			
			if ((moreText != NULL) && ([moreText length] > 0)){
				// To Do: when we show more tag label dynamically, we need to add label (if any) of more tag in the Character set string .
				//NSRange moretagRange = [description rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<!--more-->"] options:NSForcedOrderingSearch];
				textView.text = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", description, moreText];
			}
			else
				textView.text = description;
		}
		
		if(titleTextField == nil)
			titleTextField = [[UITextField alloc] init];
		titleTextField.text = [dm.currentPost valueForKey:@"title"];
		tagsTextField.text = [dm.currentPost valueForKey:@"mt_keywords"];
		
		NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
		status = (status == nil ? @"" : status);
		statusTextField.text = status;
		
		NSArray *cats = [[dm currentPost] valueForKey:@"categories"];
		if((status) && (cats.count > 0))
			categoriesTextField.text = [cats componentsJoinedByString:@", "];
		else
			categoriesTextField.text = @"";
			
	}
	
	// workaround for odd text view behavior on iPad
	[textView setContentOffset:CGPointZero animated:NO];
	
	// Set our initial location so we can determine if the geotag has been updated later
	[self setInitialLocation:[self getPostLocation]];
	
	[draftManager release];
	[autosaveManager release];
}

- (void)refreshCurrentPostForUI {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if(self.isLocalDraft == YES) {
		WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate setPostID:postDetailViewController.post.uniqueID];
		[postDetailViewController.post setPostTitle:titleTextField.text];
		[postDetailViewController.post setTags:tagsTextField.text];
		[postDetailViewController.post setCategories:categoriesTextField.text];
		[postDetailViewController.post setStatus:statusTextField.text];
		[postDetailViewController.post setContent:textView.text];
	}
	if(titleTextField.text != nil)
		[dm.currentPost setObject:titleTextField.text forKey:@"title"];
	if(tagsTextField.text != nil)
		[dm.currentPost setObject:tagsTextField.text forKey:@"mt_keywords"];
	if(categoriesTextField.text != nil)
		[dm.currentPost setObject:[categoriesTextField.text componentsSeparatedByString:@", "] forKey:@"categories"];
	if(statusTextField.text != nil)
		[dm.currentPost setObject:statusTextField.text forKey:@"status"];
	if((textView.text != nil) && (![textView.text isEqualToString:kTextViewPlaceholder]))
		[dm.currentPost setObject:textView.text forKey:@"description"];
	else
		[dm.currentPost setObject:@"" forKey:@"description"];
}

- (void)populateSelectionsControllerWithCategories {
    if (segmentedTableViewController == nil)
        segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];
	NSArray *selObject;
	
	if(isLocalDraft == YES) {
		selObject = [postDetailViewController.post.categories componentsSeparatedByString:@", "];
	}
	else {
		selObject = [[dm currentPost] valueForKey:@"categories"];
		
		if (selObject == nil)
			selObject = [NSArray array];
	}
	
    [segmentedTableViewController populateDataSource:cats    //datasorce
									   havingContext:kSelectionsCategoriesContext
									 selectedObjects:selObject
									   selectionType:kCheckbox
										 andDelegate:self];
	
    segmentedTableViewController.title = @"Categories";
    segmentedTableViewController.navigationItem.rightBarButtonItem = newCategoryBarButtonItem;
	
    if (isNewCategory != YES) {
		if (DeviceIsPad() == YES) {
			UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:segmentedTableViewController] autorelease];
			UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
			CGRect popoverRect = [self.view convertRect:[categoriesTextField frame] fromView:[categoriesTextField superview]];
			popoverRect.size.width = MIN(popoverRect.size.width, 100); // the text field is actually really big
			[popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			[[CPopoverManager instance] setCurrentPopoverController:popover];
		}
		else {
			WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
			[self refreshCurrentPostForUI];
			postDetailViewController.editMode = kEditPost;
			[delegate.navigationController pushViewController:segmentedTableViewController animated:YES];
		}
    }
	
    isNewCategory = NO;
}

- (void)syncCategories {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[BlogDataManager sharedDataManager] syncCategoriesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[self performSelectorOnMainThread:@selector(refreshCategory) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)refreshCategory {
    NSArray *cats;
	if(isLocalDraft == YES) {
		if(postDetailViewController.post.categories != nil)
			categoriesTextField.text = postDetailViewController.post.categories;
		else
			categoriesTextField.text = @"";
	}
	else {
		cats = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"categories"];
		NSString *status = [[BlogDataManager sharedDataManager] statusDescriptionForStatus:
							[[BlogDataManager sharedDataManager].currentPost valueForKey:@"post_status"] 
																				  fromBlog:[BlogDataManager sharedDataManager].currentBlog];
		
		if((status) && (cats.count > 0))
			categoriesTextField.text = [cats componentsJoinedByString:@", "];
		else
			categoriesTextField.text = @"";
	}
}

- (void)syncStatuses {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[BlogDataManager sharedDataManager] syncStatusesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)refreshStatus {
	if(isLocalDraft == YES) {
		statusTextField.text = @"Local Draft";
	}
	else {
		NSString *status = [[BlogDataManager sharedDataManager] statusDescriptionForStatus:
							[[BlogDataManager sharedDataManager].currentPost valueForKey:@"post_status"] 
																	 fromBlog:[BlogDataManager sharedDataManager].currentBlog];
		status = (status == nil ? @"" : status);
		statusTextField.text = status;
	}
}

- (void)syncCategoriesAndStatuses {
	[self performSelectorInBackground:@selector(syncCategories) withObject:nil];
	[self performSelectorInBackground:@selector(syncStatuses) withObject:nil];
}

- (void)populateSelectionsControllerWithStatuses {
    if (selectionTableViewController == nil)
        selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"postStatusList"];
    NSArray *dataSource = [NSArray arrayWithObjects:
						   [postStatusList valueForKey:@"publish"],
						   [postStatusList valueForKey:@"private"],
						   [postStatusList valueForKey:@"pending"],
						   [postStatusList valueForKey:@"draft"], nil];
	
    if ((isLocalDraft == YES) || (dm.isLocaDraftsCurrent == YES) || (dm.currentPostIndex == -1))
        dataSource = [dataSource arrayByAddingObject:@"Local Draft"];
	
    NSString *curStatus = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
	if(isLocalDraft == YES)
		curStatus = @"Local Draft";
	
    NSArray *selObject = (curStatus == nil ? [NSArray array] : [NSArray arrayWithObject:curStatus]);
	
    [selectionTableViewController populateDataSource:dataSource
									   havingContext:kSelectionsStatusContext
									 selectedObjects:selObject
									   selectionType:kRadio
										 andDelegate:self];
	
    selectionTableViewController.title = @"Status";
    selectionTableViewController.navigationItem.rightBarButtonItem = nil;
	if (DeviceIsPad() == YES) {
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:selectionTableViewController] autorelease];
		UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
		CGRect popoverRect = [self.view convertRect:[statusTextField frame] fromView:[statusTextField superview]];
		popoverRect.size.width = MIN(popoverRect.size.width, 100);
		[popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[[CPopoverManager instance] setCurrentPopoverController:popover];
	}
	else {
		WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
		[self refreshCurrentPostForUI];
		[delegate.navigationController pushViewController:selectionTableViewController animated:YES];
	}
    [selectionTableViewController release], selectionTableViewController = nil;
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }
	
	if(isLocalDraft == YES) {
		if (selContext == kSelectionsStatusContext) {
			[postDetailViewController.post setStatus:[selectedObjects lastObject]];
			statusTextField.text = postDetailViewController.post.status;
			
			if([[postDetailViewController.post.status lowercaseString] isEqualToString:@"local draft"]) {
				[postDetailViewController.post setIsLocalDraft:[NSNumber numberWithInt:1]];
				self.isLocalDraft = YES;
			}
			else {
				NSString *status = [[BlogDataManager sharedDataManager] statusForStatusDescription:statusTextField.text fromBlog:[BlogDataManager sharedDataManager].currentBlog];
				// Convert Local Draft post to BDM post
				[[BlogDataManager sharedDataManager] makeNewPostCurrent];
				[self updateValuesToCurrentPost];
				if (status)
					[[[BlogDataManager sharedDataManager] currentPost] setObject:status forKey:@"post_status"];
				[postDetailViewController.post setIsLocalDraft:[NSNumber numberWithInt:0]];
				self.isLocalDraft = NO;
			}
		}
		
		if (selContext == kSelectionsCategoriesContext) {
			[postDetailViewController.post setCategories:[selectedObjects componentsJoinedByString:@", "]];
			categoriesTextField.text = postDetailViewController.post.categories;
		}
	}
	else {
		BlogDataManager *dm = [BlogDataManager sharedDataManager];
		
		if (selContext == kSelectionsStatusContext) {
			NSString *curStatus = [selectedObjects lastObject];
			NSString *status = [dm statusForStatusDescription:curStatus fromBlog:dm.currentBlog];
			if (status) {
				[[dm currentPost] setObject:status forKey:@"post_status"];
				statusTextField.text = curStatus;
			}
		}
		
		if (selContext == kSelectionsCategoriesContext) {
			[[dm currentPost] setObject:selectedObjects forKey:@"categories"];
			categoriesTextField.text = [selectedObjects componentsJoinedByString:@", "];
		}
	}
	
    [selctionController clean];
    postDetailViewController.hasChanges = YES;
	[self preserveUnsavedPost];
	[postDetailViewController refreshButtons];
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification {
    if ([segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        isNewCategory = YES;
        [self populateSelectionsControllerWithCategories];
    }
}

- (IBAction)showAddNewCategoryView:(id)sender
{
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
	if (DeviceIsPad() == YES) {
		UIPopoverController *popover = [[CPopoverManager instance] currentPopoverController];
		[self refreshCurrentPostForUI];
		[(UINavigationController *)(popover.contentViewController) pushViewController:addCategoryViewController animated:YES];
	} else {
		UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
		[segmentedTableViewController presentModalViewController:nc animated:YES];
		[nc release];
	}
    [addCategoryViewController release];
}

- (void)endEditingAction:(id)sender {
    [titleTextField resignFirstResponder];
    [tagsTextField resignFirstResponder];
    [textView resignFirstResponder];
}

//will be called when auto save method is called.
- (void)updateValuesToCurrentPost {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSString *str = textView.text;
    str = (str != nil ? str : @"");
    [dm.currentPost setValue:str forKey:@"description"];
	
    str = tagsTextField.text;
    str = (str != nil ? str : @"");
    [dm.currentPost setValue:str forKey:@"mt_keywords"];
	
    str = titleTextField.text;
    str = (str != nil ? str : @"");
    [dm.currentPost setValue:str forKey:@"title"];
	
	//[self saveLocationDataToCustomFields];
	
    //TODO:JOHNBCustomFields -- probably want an entry here for custom_fields too
}

//- (IBAction)cancelView:(id)sender {
- (void)cancelView:(id)sender {
    [postDetailViewController cancelView:sender];
}

- (IBAction)endTextEnteringButtonAction:(id)sender {
    [textView resignFirstResponder];
	if (DeviceIsPad() == NO) {
		//		if((postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight))
		//			[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
	}
}

- (IBAction)showCategoriesViewAction:(id)sender {
	//[self showEditPostModalViewWithAnimation:YES];
    [self populateSelectionsControllerWithCategories];
	
}

- (IBAction)showStatusViewAction:(id)sender {
    [self populateSelectionsControllerWithStatuses];
}

- (void)resignTextView {
	[textView resignFirstResponder];
}

//code to append http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText {
    NSArray *stringArray = [NSArray arrayWithObjects:@"http:", @"ftp:", @"https:", nil];
    int i, count = [stringArray count];
    BOOL searchRes = NO;
	
    for (i = 0; i < count; i++) {
        NSString *searchString = [stringArray objectAtIndex:i];
		
        if (searchRes = [urlText hasPrefix:[searchString capitalizedString]])
            break;else if (searchRes = [urlText hasPrefix:[searchString lowercaseString]])
				break;else if (searchRes = [urlText hasPrefix:[searchString uppercaseString]])
					break;
    }
	
    NSString *returnStr;
	
    if (searchRes)
        returnStr = [NSString stringWithString:urlText];else
			returnStr = [NSString stringWithFormat:@"http://%@", urlText];
	
    return returnStr;
}

- (void)showLinkView {
    UIAlertView *addURLSourceAlert = [[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.0)];
    infoText = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 48.0, 260.0, 29.0)];
    urlField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 82.0, 260.0, 29.0)];
    infoText.placeholder = @"Text to be linked";
    urlField.placeholder = @"Link URL";
    //infoText.enabled = YES;
	
    infoText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    infoText.borderStyle = UITextBorderStyleRoundedRect;
    urlField.borderStyle = UITextBorderStyleRoundedRect;
    infoText.keyboardAppearance = UIKeyboardAppearanceAlert;
    urlField.keyboardAppearance = UIKeyboardAppearanceAlert;
	infoText.keyboardType = UIKeyboardTypeDefault;
	urlField.keyboardType = UIKeyboardTypeURL;
    [addURLSourceAlert addButtonWithTitle:@"Cancel"];
    [addURLSourceAlert addButtonWithTitle:@"Save"];
    addURLSourceAlert.title = @"Make a Link\n\n\n\n";
    addURLSourceAlert.delegate = self;
    [addURLSourceAlert addSubview:infoText];
    [addURLSourceAlert addSubview:urlField];
    [infoText becomeFirstResponder];
	
	//deal with rotation
	if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
		|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight))
	{
		CGAffineTransform upTransform = CGAffineTransformMakeTranslation(0.0, 80.0);
		[addURLSourceAlert setTransform:upTransform];
	}else{
		CGAffineTransform upTransform = CGAffineTransformMakeTranslation(0.0, 140.0);
		[addURLSourceAlert setTransform:upTransform];
	}
	
    //[addURLSourceAlert setTransform:upTransform];
    [addURLSourceAlert setTag:2];
    [addURLSourceAlert show];
    [addURLSourceAlert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	
    if ([alertView tag] == 1) {
        if (buttonIndex == 1)
            [self showLinkView];else {
				dismiss = YES;
				[textView touchesBegan:nil withEvent:nil];
				[delegate setAlertRunning:NO];
			}
    }
	
    if ([alertView tag] == 2) {
        if (buttonIndex == 1) {
            if ((urlField.text == nil) || ([urlField.text isEqualToString:@""])) {
                [delegate setAlertRunning:NO];
                return;
            }
			
            if ((infoText.text == nil) || ([infoText.text isEqualToString:@""]))
                infoText.text = urlField.text;
			
            NSString *commentsStr = textView.text;
            NSRange rangeToReplace = [self selectedLinkRange];
            NSString *urlString = [self validateNewLinkInfo:urlField.text];
            NSString *aTagText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, infoText.text];;
            textView.text = [commentsStr stringByReplacingOccurrencesOfString:[commentsStr substringWithRange:rangeToReplace] withString:aTagText options:NSCaseInsensitiveSearch range:rangeToReplace];
        }
		
        dismiss = YES;
        [delegate setAlertRunning:NO];
        [textView touchesBegan:nil withEvent:nil];
    }
	
    return;
}

#pragma mark TextView & TextField Delegates
- (void)textViewDidChangeSelection:(UITextView *)aTextView {
    if (!isTextViewEditing) {
        isTextViewEditing = YES;
		
		if (DeviceIsPad() == NO) {
			// Done button
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] init];
			doneButton.target = self;
			doneButton.style = UIBarButtonItemStyleBordered;
			doneButton.title = @"Done";
			doneButton.action = @selector(endTextEnteringButtonAction:);
			[postDetailViewController setLeftBarButtonItemForEditPost:doneButton];
			[doneButton release];
		}
    }
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
    isEditing = YES;
	if([textView.text isEqualToString:kTextViewPlaceholder] == YES) {
		textView.text = @"";
	}
	[textView setTextColor:[UIColor blackColor]];
	[self positionTextView:nil];
	
    dismiss = NO;
	
    if (!isTextViewEditing) {
        isTextViewEditing = YES;
		
 		if (DeviceIsPad() == NO) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
																		  target:self action:@selector(endTextEnteringButtonAction:)];
			[postDetailViewController setLeftBarButtonItemForEditPost:doneButton];
			[doneButton release];
		}
    }
	[postDetailViewController refreshButtons];
}

//replace "&nbsp" with a space @"&#160;" before Apple's broken TextView handling can do so and break things
//this enables the "http helper" to work as expected
//important is capturing &nbsp BEFORE the semicolon is added.  Not doing so causes a crash in the textViewDidChange method due to array overrun
- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
	//if nothing has been entered yet, return YES to prevent crash when hitting delete
    if (text.length == 0) {
		return YES;
    }
	
    // create final version of textView after the current text has been inserted
    NSMutableString *updatedText = [[NSMutableString alloc] initWithString:aTextView.text];
    [updatedText insertString:text atIndex:range.location];
	
    NSRange replaceRange = range, endRange = range;
	
    if (text.length > 1) {
        // handle paste
        replaceRange.length = text.length;
    } else {
        // handle normal typing
        replaceRange.length = 6;  // length of "&#160;" is 6 characters
        replaceRange.location -= 5; // look back one characters (length of "&#160;" minus one)
    }
	
    // replace "&nbsp" with "&#160;" for the inserted range
    int replaceCount = [updatedText replaceOccurrencesOfString:@"&nbsp" withString:@"&#160;" options:NSCaseInsensitiveSearch range:replaceRange];
	
    if (replaceCount > 0) {
        // update the textView's text
        aTextView.text = updatedText;
		
        // leave cursor at end of inserted text
        endRange.location += text.length + replaceCount * 1; // length diff of "&nbsp" and "&#160;" is 1 character
		
        [updatedText release];
		
        // let the textView know that it should ingore the inserted text
        return NO;
    }
	
    [updatedText release];
	
    // let the textView know that it should handle the inserted text
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
	[postDetailViewController setHasChanges:YES];
	
    if (dismiss == YES) {
        dismiss = NO;
        return;
    }
	
    NSRange range = [aTextView selectedRange];
    NSArray *stringArray = [NSArray arrayWithObjects:@"http:", @"ftp:", @"https:", @"www.", nil];
	//NSString *str = [[aTextView text]stringByReplacingOccurrencesOfString: @"&nbsp;" withString: @"&#160"];
    NSString *str = [aTextView text];
    int i, j, count = [stringArray count];
    BOOL searchRes = NO;
	
    for (j = 4; j <= 6; j++) {
        if (range.location < j)
            return;
		
        NSRange subStrRange;
		// subStrRange.location = range.location - j;
		//I took this out because adding &nbsp; to the post caused a mismatch between the length of the string from the text field and range.location
		//both should be equal, but the OS/Cocoa interprets &nbsp; as ONE space, not 6.
		//This caused NSString *subStr = [str substringWithRange:subStrRange]; to fail if the user entered &nbsp; in the post
		//subStrRange.location = str.length -j;
		subStrRange.location = range.location - j;
        subStrRange.length = j;
        [self setSelectedLinkRange:subStrRange];
		
		NSString *subStr = [str substringWithRange:subStrRange];
		
		for (i = 0; i < count; i++) {
			NSString *searchString = [stringArray objectAtIndex:i];
			
			if (searchRes = [subStr isEqualToString:[searchString capitalizedString]])
				break;else if (searchRes = [subStr isEqualToString:[searchString lowercaseString]])
					break;else if (searchRes = [subStr isEqualToString:[searchString uppercaseString]])
						break;
		}
		
		if (searchRes)
			break;
	}
	
    if (searchRes && dismiss != YES) {
        [textView resignFirstResponder];
        UIAlertView *linkAlert = [[UIAlertView alloc] initWithTitle:@"Make a Link" message:@"Would you like help making a link?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Make a Link", nil];
        [linkAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
        [linkAlert show];
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];
        [linkAlert release];
    }
	else {
		[textView scrollRangeToVisible:textView.selectedRange];
	}
	
	[self preserveUnsavedPost];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	currentEditingTextField = nil;
	textView.frame = normalTextFrame;
	
	if([textView.text isEqualToString:@""] == YES) {
		textView.text = kTextViewPlaceholder;
		[textView setTextColor:[UIColor lightGrayColor]];
	}
	else {
		[textView setTextColor:[UIColor blackColor]];
	}

	
    isEditing = NO;
    dismiss = NO;
	
    if (isTextViewEditing) {
        isTextViewEditing = NO;
		[self positionTextView:nil];
		
        NSString *text = aTextView.text;
        [[[BlogDataManager sharedDataManager] currentPost] setObject:text forKey:@"description"];
		
		if (DeviceIsPad() == NO) {
			if (postDetailViewController.hasChanges == YES) {
				[leftView setTitle:@"Cancel"];
			} else {
				[leftView setTitle:@"Posts"];
			}
			UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:leftView];
			[postDetailViewController setLeftBarButtonItemForEditPost:barItem];
			[barItem release];
		}
    }
	[self preserveUnsavedPost];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	if (DeviceIsPad() == YES) {
		if (textField == categoriesTextField) {
			[self populateSelectionsControllerWithCategories];
			return NO;
		}
		else if (textField == statusTextField) {
			[self populateSelectionsControllerWithStatuses];
			return NO;
		}
	}
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentEditingTextField = textField;
	
    if (postDetailViewController.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
        [self textViewDidEndEditing:textView];
    }
	[self preserveUnsavedPost];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentEditingTextField = nil;
	
    if (textField == titleTextField)
        [[BlogDataManager sharedDataManager].currentPost setValue:textField.text forKey:@"title"];
	else if (textField == tagsTextField)
        [[BlogDataManager sharedDataManager].currentPost setValue:tagsTextField.text forKey:@"mt_keywords"];
	
	[self preserveUnsavedPost];
}

- (void)positionTextView:(NSDictionary *)keyboardInfo {
	CGFloat animationDuration = 0.3;
	UIViewAnimationCurve curve = 0.3;
	if(keyboardInfo != nil) {
		animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
		
		curve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue];
	}
		
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:curve];
	[UIView setAnimationDuration:animationDuration];
	CGRect keyboardFrame;
	
	// Reposition TextView for editing mode or normal mode based on device and orientation
	
	if(isEditing) {
		// Editing mode
		
		// Save time: Uncomment this line when you're debugging UITextView positioning
		//textView.backgroundColor = [UIColor blueColor];
		
		// iPad
		if(DeviceIsPad() == YES) {
			if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
				// Landscape
				keyboardFrame = CGRectMake(0, 0, textView.frame.size.width, 350);
				
				[textView setFrame:keyboardFrame];
			}
			else {
				// Portrait
				keyboardFrame = CGRectMake(0, 0, textView.frame.size.width, 700);
				
				[textView setFrame:keyboardFrame];
			}
			
			[self.view bringSubviewToFront:textView];
		}
		else {
			// iPhone
			if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
				// Landscape
				keyboardFrame = CGRectMake (0, 0, 480, 130);
			}
			else {
				// Portrait
				keyboardFrame = CGRectMake (0, 0, 320, 210);
			}
			
			[textView setFrame:keyboardFrame];
		}
	}
	else {
		// Normal mode
		
		// iPad
		if(DeviceIsPad() == YES) {
			if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
				// Landscape
				keyboardFrame = CGRectMake(0, 180, textView.frame.size.width, normalTextFrame.size.height);
				
				[textView setFrame:keyboardFrame];
			}
			else {
				// Portrait
				keyboardFrame = CGRectMake(0, 180, textView.frame.size.width, normalTextFrame.size.height);
				
				[textView setFrame:keyboardFrame];
			}
			
			[self.view bringSubviewToFront:textView];
		}
		else {
			// iPhone
			if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
				// Landscape
				keyboardFrame = CGRectMake(0, 165, 480, normalTextFrame.size.height);
			}
			else {
				// Portrait
				keyboardFrame = CGRectMake(0, 165, 320, normalTextFrame.size.height);
			}
			
			[textView setFrame:keyboardFrame];
		}
	}
	
	[UIView commitAnimations];
}

- (void)deviceDidRotate:(NSNotification *)notification {
	// If we're editing, adjust the textview
	if(self.isEditing) {
		[self positionTextView:nil];
	}
}

- (void)preserveUnsavedPost {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL hasUnsavedPost = NO;
	
	if([titleTextField.text isEqualToString:@""] == NO) {
		[defaults setObject:titleTextField.text forKey:@"unsavedpost_title"];
		hasUnsavedPost = YES;
	}
	
	if([tagsTextField.text isEqualToString:@""] == NO){
		[defaults setObject:tagsTextField.text forKey:@"unsavedpost_tags"];
		hasUnsavedPost = YES;
	}
	
	if([categoriesTextField.text isEqualToString:@""] == NO) {
		[defaults setObject:categoriesTextField.text forKey:@"unsavedpost_categories"];
		hasUnsavedPost = YES;
	}
	
	if([statusTextField.text isEqualToString:@""] == NO) {
		[defaults setObject:statusTextField.text forKey:@"unsavedpost_status"];
		hasUnsavedPost = YES;	
	}
	
	if(([textView.text isEqualToString:@""] == NO) && ([textView.text isEqualToString:kTextViewPlaceholder] == NO)) {
		[defaults setObject:textView.text forKey:@"unsavedpost_content"];
		hasUnsavedPost = YES;
	}
	
	if(hasUnsavedPost == YES) {
		[defaults setBool:YES forKey:@"unsavedpost_ihasone"];
		[defaults synchronize];
	}
}

- (void)clearUnsavedPost {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults removeObjectForKey:@"unsavedpost_title"];
	[defaults removeObjectForKey:@"unsavedpost_tags"];
	[defaults removeObjectForKey:@"unsavedpost_categories"];
	[defaults removeObjectForKey:@"unsavedpost_status"];
	[defaults removeObjectForKey:@"unsavedpost_content"];
	[defaults removeObjectForKey:@"unsavedpost_ihasone"];
}

- (void)restoreUnsavedPost {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if([defaults boolForKey:@"unsavedpost_ihasone"] == YES) {
		if ([defaults objectForKey:@"unsavedpost_title"] != nil) {
			[[BlogDataManager sharedDataManager].currentPost setValue:[defaults objectForKey:@"unsavedpost_title"] forKey:@"title"];
			titleTextField.text = [defaults objectForKey:@"unsavedpost_title"];
		}
		
		if ([defaults objectForKey:@"unsavedpost_tags"] != nil) {
			[[BlogDataManager sharedDataManager].currentPost setValue:[defaults objectForKey:@"unsavedpost_tags"] forKey:@"mt_keywords"];
			tagsTextField.text = [defaults objectForKey:@"unsavedpost_tags"];
		}
		
		if ([defaults objectForKey:@"unsavedpost_categories"] != nil) {
			categoriesTextField.text = [defaults objectForKey:@"unsavedpost_categories"];
		}
		
		if ([defaults objectForKey:@"unsavedpost_status"] != nil) {
			statusTextField.text = [defaults objectForKey:@"unsavedpost_status"];
		}
		
		if ([defaults objectForKey:@"unsavedpost_content"] != nil) {
			textView.text = [defaults objectForKey:@"unsavedpost_content"];
			textViewPlaceHolderField.hidden = YES;
		}
		postDetailViewController.hasChanges = YES;
	}
	
	[self clearUnsavedPost];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    postDetailViewController.hasChanges = YES;
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    postDetailViewController.hasChanges = YES;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.currentEditingTextField = nil;
    [textField resignFirstResponder];
    return YES;
}

- (void)insertMediaAbove:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br/><br/>";
	
	if(textView.text == nil)
		textView.text = @"";
	else if([textView.text isEqualToString:kTextViewPlaceholder]) {
        textView.textColor = [UIColor blackColor];
		textView.text = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[[NSMutableString alloc] initWithString:media.html] autorelease];
	NSRange imgHTML = [textView.text rangeOfString:content];
	if (imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, textView.text]];
		textView.text = content;
		postDetailViewController.hasChanges = YES;
	}
}

- (void)insertMediaBelow:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br/><br/>";
	
	if(textView.text == nil)
		textView.text = @"";
	else if([textView.text isEqualToString:kTextViewPlaceholder]) {
        textView.textColor = [UIColor blackColor];
		textView.text = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[[NSMutableString alloc] initWithString:textView.text] autorelease];
	NSRange imgHTML = [content rangeOfString:media.html];
	if (imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, media.html]];
		textView.text = content;
		postDetailViewController.hasChanges = YES;
	}
}

- (void)removeMedia:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	textView.text = [textView.text stringByReplacingOccurrencesOfString:media.html withString:@""];
}

- (void)readBookmarksFile {
    bookMarksArray = [[NSMutableArray alloc] init];
    //NSDictionary *bookMarksDict=[NSMutableDictionary dictionaryWithContentsOfFile:@"/Users/sridharrao/Library/Safari/Bookmarks.plist"];
    NSDictionary *bookMarksDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Users/sridharrao/Library/Application%20Support/iPhone%20Simulator/User/Library/Safari/Bookmarks.plist"];
    NSArray *childrenArray = [bookMarksDict valueForKey:@"Children"];
    bookMarksDict = [childrenArray objectAtIndex:0];
    int count = [childrenArray count];
    childrenArray = [bookMarksDict valueForKey:@"Children"];
	
    for (int i = 0; i < count; i++) {
        bookMarksDict = [childrenArray objectAtIndex:i];
		
        if ([[bookMarksDict valueForKey:@"WebBookmarkType"] isEqualToString:@"WebBookmarkTypeLeaf"]) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setValue:[[bookMarksDict valueForKey:@"URIDictionary"] valueForKey:@"title"] forKey:@"title"];
            [dict setValue:[bookMarksDict valueForKey:@"URLString"] forKey:@"url"];
            [bookMarksArray addObject:dict];
            [dict release];
        }
    }
}

#pragma mark  -
#pragma mark Table Data Source Methods (for Custom Fields TableView only)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 25)];
        label.textAlignment = UITextAlignmentLeft;
        //label.tag = kLabelTag;
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        [cell.contentView addSubview:label];
        [label release];
    }
	
    NSUInteger row = [indexPath row];
	
    //UILabel *label = (UILabel *)[cell viewWithTag:kLabelTag];
	
    if (row == 0) {
        //label.text = @"Edit Custom Fields";
        //label.font = [UIFont systemFontOfSize:16 ];
    } else {
        //do nothing because we've only got one cell right now
    }
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    cell.userInteractionEnabled = YES;
    return cell;
}

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
//    return UITableViewCellAccessoryDisclosureIndicator;
//}

#pragma mark -
#pragma mark Table delegate
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark -
#pragma mark Custom Fields methods

- (BOOL)checkCustomFieldsMinusMetadata {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSMutableArray *tempCustomFieldsArray = [dm.currentPost valueForKey:@"custom_fields"];
	
    //if there is anything (>=1) in the array, start proceessing, otherwise return NO
    if (tempCustomFieldsArray.count >= 1) {
        //strip out any underscore-containing NSDicts inside the array, as this is metadata we don't need
        int dictsCount = [tempCustomFieldsArray count];
		
        for (int i = 0; i < dictsCount; i++) {
            NSString *tempKey = [[tempCustomFieldsArray objectAtIndex:i] objectForKey:@"key"];
			
            //if tempKey contains an underscore, remove that object (NSDict with metadata) from the array and move on
            if(([tempKey rangeOfString:@"_"].location != NSNotFound) && ([tempKey rangeOfString:@"geo_"].location == NSNotFound)) {
                [tempCustomFieldsArray removeObjectAtIndex:i];
                //if I remove one, the count goes down and we stop too soon unless we subtract one from i
                //and re-set dictsCount.  Doing this keeps us in sync with the actual array.count
                i--;
                dictsCount = [tempCustomFieldsArray count];
            }
        }
		
        //if the count of everything minus the metedata is one or greater, there is at least one custom field on this post, so return YES
        if (dictsCount >= 1) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark Location methods

- (BOOL)isPostGeotagged {
	if([self getPostLocation] != nil) {
		postDetailViewController.hasChanges = YES;
		return YES;
	}
	else
		return NO;
}

- (IBAction)showLocationMapView:(id)sender {
	WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	PostLocationViewController *locationView = [[PostLocationViewController alloc] initWithNibName:@"PostLocationViewController" bundle:nil];
	[delegate.navigationController presentModalViewController:locationView animated:YES];
	[locationView release];
}

- (CLLocation *)getPostLocation {
	CLLocation *result = nil;
	double latitude = 0.0;
	double longitude = 0.0;
    NSArray *customFieldsArray = [[[BlogDataManager sharedDataManager] currentPost] valueForKey:@"custom_fields"];
	
	// Loop through the post's custom fields
	for(NSDictionary *dict in customFieldsArray)
	{
		// Latitude
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_latitude"])
			latitude = [[dict objectForKey:@"value"] doubleValue];
		
		// Longitude
		if([[dict objectForKey:@"key"] isEqualToString:@"geo_longitude"])
			longitude = [[dict objectForKey:@"value"] doubleValue];
		
		// If we have both lat and long, we have a geotag
		if((latitude != 0.0) && (longitude != 0.0))
		{
			result = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
			break;
		}
		else
			result = nil;
	}
	
	return result;
}

- (void)showAutosaveButton {
	[self.autosaveButton setHidden:NO];
	[self.autosaveButton setAlpha:0.50];
	[self.view bringSubviewToFront:self.autosaveButton];
//	[UIView beginAnimations:nil context:NULL];
//	[UIView setAnimationDuration:2.0];
//	[UIView commitAnimations];
}

- (void)hideAutosaveButton {
	[self.autosaveButton setHidden:YES];
	[self.autosaveButton setAlpha:0.0];
	[self.view sendSubviewToBack:self.autosaveButton];
//	[UIView beginAnimations:nil context:NULL];
//	[UIView setAnimationDuration:5.0];
//	[UIView commitAnimations];
}

- (IBAction)showAutosaves:(id)sender {
	[postDetailViewController showAutosaves];
}

#pragma mark -
#pragma mark Keyboard management 

- (void)keyboardWillShow:(NSNotification *)notification {
	//NSDictionary *keyboardInfo = (NSDictionary *)[notification userInfo];
	postDetailViewController.isShowingKeyboard = YES;
	[postDetailViewController refreshButtons];
	
	[self preserveUnsavedPost];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	//NSDictionary *keyboardInfo = (NSDictionary *)[notification userInfo];
	postDetailViewController.isShowingKeyboard = NO;
	[postDetailViewController refreshButtons];
	
//	CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]; 
//	UIViewAnimationCurve curve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue]; 
//	
//	[UIView beginAnimations:nil context:nil]; 
//	[UIView setAnimationCurve:curve]; 
//	[UIView setAnimationDuration:animationDuration]; 
//	[UIView commitAnimations];
	
	[self preserveUnsavedPost];
}

#pragma mark -
#pragma mark UIPickerView delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {	
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
	return [statuses count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [statuses objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	self.statusTextField.text = [statuses objectAtIndex:row];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[autosaveButton release];
	[statuses release];
	[textView release];
	[contentView release];
	[subView release];
	[textViewContentView release];
	[statusTextField release];
	[categoriesTextField release];
	[titleTextField release];
	[tagsTextField release];
	[textViewPlaceHolderField release];
	[tagsLabel release];
	[statusLabel release];
	[categoriesLabel release];
	[titleLabel release];
	[customFieldsEditButton release];
	[locationButton release];
	[locationSpinner release];
	[newCategoryBarButtonItem release];
    [infoText release];
    [urlField release];
    [leftView release];
    [bookMarksArray release];
    [segmentedTableViewController release];
    [super dealloc];
}


@end
