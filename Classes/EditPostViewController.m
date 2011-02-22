#import "EditPostViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "WPNavigationLeftButtonView.h"
#import "CPopoverManager.h"

NSTimeInterval kAnimationDuration = 0.3f;

@implementation EditPostViewController

@synthesize selectionTableViewController, segmentedTableViewController;
@synthesize infoText, urlField, bookMarksArray, selectedLinkRange, currentEditingTextField, isEditing, initialLocation;
@synthesize editingDisabled, editCustomFields, statuses, isLocalDraft;
@synthesize textView, contentView, subView, textViewContentView, statusTextField, categoriesTextField, titleTextField;
@synthesize tagsTextField, textViewPlaceHolderField, tagsLabel, statusLabel, categoriesLabel, titleLabel, customFieldsEditButton;
@synthesize locationButton, locationSpinner, newCategoryBarButtonItem, hasLocation;
@synthesize editMode, apost;
@synthesize hasSaved, isVisible, isPublishing;
@synthesize toolbar;

- (id)initWithPost:(AbstractPost *)aPost {
    NSString *nib;
    if (DeviceIsPad()) {
        nib = @"EditPostViewController-iPad";
    } else {
        nib = @"EditPostViewController";
    }
    
    if (self = [super initWithNibName:nib bundle:nil]) {
        self.apost = aPost;
    }
    
    return self;
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (void)setPost:(Post *)aPost {
    self.apost = aPost;
}

- (void)switchToView:(UIView *)newView {
    if ([newView isEqual:postSettingsController.view])
        [postSettingsController viewWillAppear:YES];
    else 
        [postSettingsController viewWillDisappear:YES];
	
	if(![newView isEqual:postPreviewViewController.view]) {
		 [postPreviewViewController viewWillDisappear:YES];
	}
    if ([newView isEqual:editView]) {
		writeButton.enabled = NO;
		settingsButton.enabled = YES;
		previewButton.enabled = YES;
		if ([self.apost.media count]) attachmentButton.enabled = YES;
		else attachmentButton.enabled = NO;
    } else if ([newView isEqual:postSettingsController.view]) {
		writeButton.enabled = YES;
		settingsButton.enabled = NO;
		previewButton.enabled = YES;
		if ([self.apost.media count]) attachmentButton.enabled = YES;
		else attachmentButton.enabled = NO;
    } else if ([newView isEqual:postPreviewViewController.view]) {
		writeButton.enabled = YES;
		settingsButton.enabled = YES;
		previewButton.enabled = NO;
		if ([self.apost.media count]) attachmentButton.enabled = YES;
		else attachmentButton.enabled = NO;
	} else if ([newView isEqual:postMediaViewController.view]) {
		writeButton.enabled = YES;
		settingsButton.enabled = YES;
		previewButton.enabled = YES;
		attachmentButton.enabled = NO;
	}
	
    newView.frame = currentView.frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];

	CGRect pointerFrame = tabPointer.frame;
    if ([newView isEqual:editView]) {
		pointerFrame.origin.x = 22;
    } else if ([newView isEqual:postSettingsController.view]) {
		pointerFrame.origin.x = 60;
    } else if ([newView isEqual:postPreviewViewController.view]) {
		pointerFrame.origin.x = 100;
	} else if ([newView isEqual:postMediaViewController.view]) {
		pointerFrame.origin.x = 200;
	}
	tabPointer.frame = pointerFrame;
    [currentView removeFromSuperview];
    [contentView addSubview:newView];

    [UIView commitAnimations];
    
    currentView = newView;

    if ([newView isEqual:postSettingsController.view])
        [postSettingsController viewDidAppear:YES];
    else
        [postSettingsController viewDidDisappear:YES];
}

- (IBAction)switchToEdit {
    if (currentView != editView) {
        [self switchToView:editView];
    }
	self.navigationItem.title = @"Write";
}

- (IBAction)switchToSettings {
    if (currentView != postSettingsController.view) {
        [self switchToView:postSettingsController.view];
    }
	self.navigationItem.title = @"Settings";
}

- (IBAction)switchToMedia {
    if (currentView != postMediaViewController.view) {
        [self switchToView:postMediaViewController.view];
    }
	self.navigationItem.title = @"Media";
}

- (IBAction)switchToPreview {
    if (currentView != postPreviewViewController.view) {
		[postPreviewViewController refreshWebView];
        [self switchToView:postPreviewViewController.view];
    }
	self.navigationItem.title = @"Preview";
}

- (IBAction)addVideo:(id)sender {
    [postMediaViewController showVideoPickerActionSheet:sender];
}

- (IBAction)addPhoto:(id)sender {
    [postMediaViewController showPhotoPickerActionSheet:sender];
}

#pragma mark -
#pragma mark View lifecycle

- (CGRect)normalTextFrame {
    if (DeviceIsPad())
        if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
            || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
            return CGRectMake(0, 143, 768, 537);
        else // Portrait
            return CGRectMake(0, 143, 768, 773);
		else if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				 || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
			return CGRectMake(0, 136, 480, 236);
		else // Portrait
			return CGRectMake(0, 136, 320, 236);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"EditPost"];

    postSettingsController = [[PostSettingsViewController alloc] initWithNibName:@"PostSettingsViewController" bundle:nil];
    postSettingsController.postDetailViewController = self;
    postSettingsController.view.frame = editView.frame;
    
    postMediaViewController = [[PostMediaViewController alloc] initWithNibName:@"PostMediaViewController" bundle:nil];
    postMediaViewController.postDetailViewController = self;
    postMediaViewController.view.frame = editView.frame;
	
	postPreviewViewController = [[PostPreviewViewController alloc] initWithNibName:@"PostPreviewViewController" bundle:nil];
    postPreviewViewController.postDetailViewController = self;
    postPreviewViewController.view.frame = editView.frame;
    
	self.navigationItem.title = @"Write";
	statuses = [NSArray arrayWithObjects:@"Local Draft", @"Draft", @"Private", @"Pending Review", @"Published", nil];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"EditPostViewShouldSave" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publish) name:@"EditPostViewShouldPublish" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];
	
	
    isTextViewEditing = NO;
    spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	hasSaved = NO;
    
    currentView = editView;
	writeButton.enabled = NO;
	if ([self.apost.media count]) attachmentButton.enabled = YES;
	else attachmentButton.enabled = NO;

    if (iOs4OrGreater()) {
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    }
	
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	
	if (version < 3.2){
		//no video icon for older devices
		NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:toolbar.items];
		NSLog(@"toolbar items: %@", toolbarItems);
		
		[toolbarItems removeObjectAtIndex:4];
		[toolbar setItems:toolbarItems];
	}
	
	if (self.post && self.post.geolocation != nil) {
		self.hasLocation.enabled = YES;
	} else {
		self.hasLocation.enabled = NO;
	}

    if(self.editMode == kEditPost)
        [self refreshUIForCurrentPost];
	else if(self.editMode == kNewPost)
        [self refreshUIForCompose];
	else if (self.editMode == kAutorecoverPost) {
        [self refreshUIForCurrentPost];
	}
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
	
	isVisible = YES;
		
	[self refreshButtons];
	
    textView.frame = self.normalTextFrame;
    CGRect frame = self.normalTextFrame;
    frame.origin.x += 7;
    frame.origin.y += 7;
    textViewPlaceHolderField.frame = frame;
	self.navigationItem.title = @"Write";
}

- (void)viewWillDisappear:(BOOL)animated {	
	if(self.editMode != kNewPost)
		self.editMode = kRefreshPost;
	isVisible = NO;
	
	[titleTextField resignFirstResponder];
	[textView resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if(DeviceIsPad()) {
		return YES;
	}
	else if ((toInterfaceOrientation == UIInterfaceOrientationPortrait) || (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
		return YES;
	}
	else if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
		if (self.interfaceOrientation != toInterfaceOrientation) {
			if (isEditing)
				return YES;
			else
				return NO;
		}
	}
	
	return NO;	
}

- (void)disableInteraction {
	editingDisabled = YES;
}

#pragma mark -

- (void)dismissEditView {
	if (DeviceIsPad() == NO) {
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.navigationController popViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];		
	}
	[postSettingsController release]; postSettingsController = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[FlurryAPI logEvent:@"EditPost#dismissEditView"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostEditorDismissed" object:self];
}


- (void)refreshButtons {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelView:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] init];
    saveButton.title = @"Save";
    saveButton.target = self;
    saveButton.style = UIBarButtonItemStyleDone;
    saveButton.action = @selector(saveAction:);
    
    if(![self.apost hasRemote]) {
        if ([self.apost.status isEqualToString:@"publish"] && ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)) {
            saveButton.title = @"Schedule";
		} else if ([self.apost.status isEqualToString:@"publish"]){
			saveButton.title = @"Publish";
		} else {
            saveButton.title = @"Save";
        }
    } else {
        saveButton.title = @"Update";
    }
    self.navigationItem.rightBarButtonItem = saveButton;
    
    [saveButton release];
}

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
	self.navigationItem.title = @"Write";
    titleTextField.text = @"";
    textView.text = @"";
    textViewPlaceHolderField.hidden = NO;
	self.isLocalDraft = YES;
}

- (void)refreshUIForCurrentPost {
    if ([self.apost.postTitle length] > 0) {
        self.navigationItem.title = self.apost.postTitle;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                style:UIBarButtonItemStyleBordered target:nil action:nil];

    titleTextField.text = self.apost.postTitle;
    if (self.post) {
        // FIXME: tags should be an array/set of Tag objects
        tagsTextField.text = self.post.tags;
        categoriesTextField.text = [self.post categoriesText];
    }
    
    if(self.apost.content == nil) {
        textViewPlaceHolderField.hidden = NO;
        textView.text = @"";
    }
    else {
        textViewPlaceHolderField.hidden = YES;
        if ((self.apost.mt_text_more != nil) && ([self.apost.mt_text_more length] > 0)){
			textView.text = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.apost.content, self.apost.mt_text_more];
		} else	
			textView.text = self.apost.content;
		
    }

	// workaround for odd text view behavior on iPad
	[textView setContentOffset:CGPointZero animated:NO];
}

- (void)populateSelectionsControllerWithCategories {
    if (segmentedTableViewController == nil)
        segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	NSArray *cats = [self.post.blog.categories allObjects];
	NSArray *selObject;
	
    selObject = [self.post.categories allObjects];
	
    [segmentedTableViewController populateDataSource:cats    //datasorce
									   havingContext:kSelectionsCategoriesContext
									 selectedObjects:selObject
									   selectionType:kCheckbox
										 andDelegate:self];
	
    segmentedTableViewController.title = @"Categories";
    segmentedTableViewController.navigationItem.rightBarButtonItem = newCategoryBarButtonItem;
	
    if (isNewCategory != YES) {
		if (DeviceIsPad() == YES) {
            UINavigationController *navController;
            if (segmentedTableViewController.navigationController) {
                navController = segmentedTableViewController.navigationController;
            } else {
                navController = [[[UINavigationController alloc] initWithRootViewController:segmentedTableViewController] autorelease];
            }
 			UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
            popover.delegate = self;			CGRect popoverRect = [self.view convertRect:[categoriesTextField frame] fromView:[categoriesTextField superview]];
			popoverRect.size.width = MIN(popoverRect.size.width, 100); // the text field is actually really big
			[popover presentPopoverFromRect:popoverRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			[[CPopoverManager instance] setCurrentPopoverController:popover];
		}
		else {
			WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
			self.editMode = kEditPost;
			[delegate.navigationController pushViewController:segmentedTableViewController animated:YES];
		}
    }
	
	isNewCategory = NO;
}

- (void)refreshStatus {
	if(isLocalDraft == YES) {
		statusTextField.text = @"Local Draft";
	}
	else {
		statusTextField.text = self.apost.statusTitle;
	}
}

- (void)populateSelectionsControllerWithStatuses {
    if (selectionTableViewController == nil)
        selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
    NSArray *dataSource = [self.apost availableStatuses];
	
    NSString *curStatus = self.apost.statusTitle;
	
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
		[delegate.navigationController pushViewController:selectionTableViewController animated:YES];
	}
    [selectionTableViewController release], selectionTableViewController = nil;
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    if (selContext == kSelectionsStatusContext) {
        NSString *curStatus = [selectedObjects lastObject];
        self.apost.statusTitle = curStatus;
        statusTextField.text = curStatus;
    }
    
    if (selContext == kSelectionsCategoriesContext) {
        NSLog(@"selected categories: %@", selectedObjects);
        NSLog(@"post: %@", self.post);
        self.post.categories = [NSMutableSet setWithArray:selectedObjects];
        categoriesTextField.text = [self.post categoriesText];
    }
	
    [selctionController clean];
	[self refreshButtons];
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
    addCategoryViewController.blog = self.post.blog;
	if (DeviceIsPad() == YES) {
        [segmentedTableViewController pushViewController:addCategoryViewController animated:YES];
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


- (BOOL)isAFreshlyCreatedDraft {
	if( [self.apost.original.postID isEqualToNumber:[NSNumber numberWithInteger:-1]] ) 
		if( self.apost.original.postTitle == nil )
			return YES;
	
	return NO;
}

- (void)discard {
    [FlurryAPI logEvent:@"Post#actionSheet_discard"];
    
    [self.apost.original deleteRevision];

	//remove the original post in case of local draft unsaved
	if([self isAFreshlyCreatedDraft]) 
		[self.apost.original removeWithError:nil]; //we can pass nil because this is a local draft. no remote errors.
	
	self.apost = nil; // Just in case
    [self dismissEditView];
}

- (IBAction)saveAction:(id)sender {
	[self savePost:YES];
}

- (void)savePost: (BOOL)upload{
	self.apost.postTitle = titleTextField.text;
    self.apost.content = textView.text;
	if ([self.apost.content rangeOfString:@"<!--more-->"].location != NSNotFound)
		self.apost.mt_text_more = @"";
    
    [self.view endEditing:YES];
    [self.apost.original applyRevision];
	if (upload)
		[self.apost.original upload];
    [self dismissEditView];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet tag] == 201) {
        if (buttonIndex == 0) {
            [self discard];
        }
        
        if (buttonIndex == 1) {  
			if ([actionSheet numberOfButtons] == 2)
				[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
			else {
				if([self isAFreshlyCreatedDraft])
					self.apost.statusTitle = @"Draft";
				
				if (![self.apost hasRemote])
					[self savePost:NO];
				else
					[self savePost:YES];
			}
        }
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:NO];
}

- (IBAction)cancelView:(id)sender {
    [FlurryAPI logEvent:@"EditPost#cancelView"];
    if (!self.hasChanges) {
        [self discard];
        return;
    }
    [FlurryAPI logEvent:@"EditPost#cancelView(actionSheet)"];
	[postSettingsController endEditingAction:nil];
	[self endEditingAction:nil];
    
	UIActionSheet *actionSheet;
	if (![self.apost hasRemote])
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
                                                             delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
                                                    otherButtonTitles:@"Save", nil];
	else
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
												  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
										 otherButtonTitles:nil];
    actionSheet.tag = 201;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setAlertRunning:YES];
    
    [actionSheet release];
}

- (IBAction)endTextEnteringButtonAction:(id)sender {
    [textView resignFirstResponder];
	if (DeviceIsPad() == NO) {
		if((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			//#615 -- trick to rotate the interface back to portrait. 
				UIViewController *garbageController = [[[UIViewController alloc] init] autorelease]; 
				[self.navigationController pushViewController:garbageController animated:NO]; 
				[self.navigationController popViewControllerAnimated:NO];
		}
	}
}

/*
- (IBAction)showCategoriesViewAction:(id)sender {
	//[self showEditPostModalViewWithAnimation:YES];
    [self populateSelectionsControllerWithCategories];
}

- (IBAction)showStatusViewAction:(id)sender {
    [self populateSelectionsControllerWithStatuses];
}
*/
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
    UIAlertView *addURLSourceAlert = [[UIAlertView alloc] init];
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
	
	//move the alert dialog up for older devices
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version < 3.2){
		CGAffineTransform myTransform = CGAffineTransformMakeTranslation(0, 100);
		[addURLSourceAlert setTransform:myTransform];
	}
    [addURLSourceAlert setTag:2];
    [addURLSourceAlert show];
    [addURLSourceAlert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
	
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
			self.apost.content = textView.text;
        }
		
        dismiss = YES;
        [delegate setAlertRunning:NO];
        [textView touchesBegan:nil withEvent:nil];
    }
	
    return;
}

- (BOOL)hasChanges {
    return self.apost.hasChanges;
}

#pragma mark TextView & TextField Delegates

- (void)showDoneButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                                                  target:self action:@selector(endTextEnteringButtonAction:)];
    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItem = nil;
    [doneButton release];
}

- (void)textViewDidChangeSelection:(UITextView *)aTextView {
    if (!isTextViewEditing) {
        isTextViewEditing = YES;
		
		if (DeviceIsPad() == NO) {
            [self showDoneButton];
		}
    }
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
    [textViewPlaceHolderField removeFromSuperview];
    isEditing = YES;

	[self positionTextView:nil];
	
    dismiss = NO;
	
    if (!isTextViewEditing) {
        isTextViewEditing = YES;
		
 		if (!DeviceIsPad()) {
            [self showDoneButton];
		}
    }
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
        self.apost.content = updatedText;
		
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
    if (dismiss == YES) {
        dismiss = NO;
        return;
    }
	
    NSRange range = [aTextView selectedRange];
	if (range.location == NSNotFound)
		return;
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
	
    self.apost.content = textView.text;
    if (searchRes && dismiss != YES) {
        [textView resignFirstResponder];
        UIAlertView *linkAlert = [[UIAlertView alloc] initWithTitle:@"Make a Link" message:@"Would you like help making a link?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Make a Link", nil];
        [linkAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
        [linkAlert show];
        WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];
        [linkAlert release];
    }
	else {
		[textView scrollRangeToVisible:textView.selectedRange];
	}	
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
	currentEditingTextField = nil;
	
	if([textView.text isEqualToString:@""] == YES) {
        [editView addSubview:textViewPlaceHolderField];
	}
	
    isEditing = NO;
    dismiss = NO;
	
    if (isTextViewEditing) {
        isTextViewEditing = NO;
		[self positionTextView:nil];
		
        self.apost.content = textView.text;
		
		if (!DeviceIsPad()) {
            [self refreshButtons];
		}
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == categoriesTextField) {
        [self populateSelectionsControllerWithCategories];
        return NO;
    }
    if (textField == textViewPlaceHolderField) {
        [textView becomeFirstResponder];
        return NO;
    }
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentEditingTextField = textField;
	
    if (self.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
        [self textViewDidEndEditing:textView];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentEditingTextField = nil;
	
    if (textField == titleTextField) {
        self.apost.postTitle = textField.text;
        
        // FIXME: this should be -[PostsViewController updateTitle]
        if ([self.apost.postTitle length] > 0) {
            self.navigationItem.title = self.apost.postTitle;
        } else {
            self.navigationItem.title = @"Write";
        }

    }
	else if (textField == tagsTextField)
        self.post.tags = tagsTextField.text;
    
    [self.post autosave];
}

- (CGRect)frameForTextView {
	CGRect keyboardFrame;

	// Reposition TextView for editing mode or normal mode based on device and orientation

	if(isEditing) // Editing mode
		if(DeviceIsPad() == YES)
			if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
				keyboardFrame = CGRectMake(0, 0, self.normalTextFrame.size.width, self.view.frame.size.height - 352);
			else // Portrait
				keyboardFrame = CGRectMake(0, 0, self.normalTextFrame.size.width, self.view.frame.size.height - 264);
		else // iPhone
			if ((self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
				|| (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)) // Landscape
				keyboardFrame = CGRectMake (0, 0, 480, 130);
			else // Portrait
				keyboardFrame = CGRectMake (0, 0, 320, 210);
	else // Normal mode
        keyboardFrame = self.normalTextFrame;

    return keyboardFrame;
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

    // Save time: Uncomment this line when you're debugging UITextView positioning
    //textView.backgroundColor = [UIColor blueColor];

    CGRect keyboardFrame = [self frameForTextView];
    [textView setFrame:keyboardFrame];
	
	[UIView commitAnimations];
}

- (void)deviceDidRotate:(NSNotification *)notification {
	// If we're editing, adjust the textview
	if(self.isEditing) {
		[self positionTextView:nil];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
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
	
	if(self.apost.content == nil || [self.apost.content isEqualToString:@""]) {
		self.apost.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[[NSMutableString alloc] initWithString:media.html] autorelease];
	NSRange imgHTML = [textView.text rangeOfString: content];
	
	NSRange imgHTMLPre = [textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br/><br/>", content]]; 
 	NSRange imgHTMLPost = [textView.text rangeOfString:[NSString stringWithFormat:@"%@%@", content, @"<br/><br/>"]]; 
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, self.apost.content]];
        self.post.content = content;
	}
	else { 
		NSMutableString *processedText = [[[NSMutableString alloc] initWithString:textView.text] autorelease]; 
		if (imgHTMLPre.location != NSNotFound) 
			[processedText replaceCharactersInRange:imgHTMLPre withString:@""];
		else if (imgHTMLPost.location != NSNotFound) 
			[processedText replaceCharactersInRange:imgHTMLPost withString:@""];
		else  
			[processedText replaceCharactersInRange:imgHTML withString:@""];  
		 
		[content appendString:[NSString stringWithFormat:@"<br/><br/>%@", processedText]]; 
		self.post.content = content;
	}
    [self refreshUIForCurrentPost];
}

- (void)insertMediaBelow:(NSNotification *)notification {
	Media *media = (Media *)[notification object];
	NSString *prefix = @"<br/><br/>";
	
	if(self.apost.content == nil || [self.apost.content isEqualToString:@""]) {
		self.apost.content = @"";
		prefix = @"";
	}
	
	NSMutableString *content = [[[NSMutableString alloc] initWithString:self.apost.content] autorelease];
	NSRange imgHTML = [content rangeOfString: media.html];
	NSRange imgHTMLPre = [content rangeOfString:[NSString stringWithFormat:@"%@%@", @"<br/><br/>", media.html]]; 
 	NSRange imgHTMLPost = [content rangeOfString:[NSString stringWithFormat:@"%@%@", media.html, @"<br/><br/>"]];
	
	if (imgHTMLPre.location == NSNotFound && imgHTMLPost.location == NSNotFound && imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"%@%@", prefix, media.html]];
        self.apost.content = content;
	}
	else {
		if (imgHTMLPre.location != NSNotFound) 
			[content replaceCharactersInRange:imgHTMLPre withString:@""]; 
		else if (imgHTMLPost.location != NSNotFound) 
			[content replaceCharactersInRange:imgHTMLPost withString:@""];
		else  
			[content replaceCharactersInRange:imgHTML withString:@""];
		[content appendString:[NSString stringWithFormat:@"<br/><br/>%@", media.html]];
		self.apost.content = content;
	}
    [self refreshUIForCurrentPost];
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
/*
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

/*
#pragma mark -
#pragma mark Location methods

- (BOOL)isPostGeotagged {
	if([self getPostLocation] != nil) {
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
*/

#pragma mark -
#pragma mark Keyboard management 

- (void)keyboardWillShow:(NSNotification *)notification {
	isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
	isShowingKeyboard = NO;
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
#pragma mark UIPopoverController delegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if ((popoverController.contentViewController) && ([popoverController.contentViewController class] == [UINavigationController class])) {
        UINavigationController *nav = (UINavigationController *)popoverController.contentViewController;
        if ([nav.viewControllers count] == 2) {
            WPSegmentedSelectionTableViewController *selController = [nav.viewControllers objectAtIndex:0];
            [selController popViewControllerAnimated:YES];
        }
    }
    return YES;
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
	self.hasLocation = nil;
//	[statuses release];
    [postMediaViewController release];
	[postPreviewViewController release];
    [postSettingsController release];
    [writeButton release];
    [settingsButton release];
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
    [bookMarksArray release];
    [segmentedTableViewController release];
    [super dealloc];
}


@end
