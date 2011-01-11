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
@synthesize locationButton, locationSpinner, newCategoryBarButtonItem;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"EditPost"];

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia:) name:@"ShouldRemoveMedia" object:nil];
	
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
	
    isTextViewEditing = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	//WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [super viewWillAppear:animated];
	//[self dismissModalViewControllerAnimated:YES];
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
	self.navigationItem.title = @"Write";
    titleTextField.text = @"";
    tagsTextField.text = @"";
	[textView setText:kTextViewPlaceholder];
	[textView setTextColor:[UIColor lightGrayColor]];
    textViewPlaceHolderField.hidden = NO;
    categoriesTextField.text = @"";
	self.isLocalDraft = YES;
	statusTextField.text = postDetailViewController.post.statusTitle;
}

- (void)refreshUIForCurrentPost {
    Post *post = postDetailViewController.post;

    if ([post.postTitle length] > 0) {
        postDetailViewController.navigationItem.title = post.postTitle;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                style:UIBarButtonItemStyleBordered target:nil action:nil];

    titleTextField.text = post.postTitle;
    tagsTextField.text = post.tags;
    statusTextField.text = post.statusTitle;
    categoriesTextField.text = [post categoriesText];
    
    if(post.content == nil) {
        textViewPlaceHolderField.hidden = NO;
        textView.text = @"";
    }
    else {
        textViewPlaceHolderField.hidden = YES;
        textView.text = post.content;
    }

	// workaround for odd text view behavior on iPad
	[textView setContentOffset:CGPointZero animated:NO];

	// Set our initial location so we can determine if the geotag has been updated later
	[self setInitialLocation:[self getPostLocation]];
}

- (void)refreshCurrentPostForUI {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if(self.isLocalDraft == YES) {
		[postDetailViewController.post setPostTitle:titleTextField.text];
		[postDetailViewController.post setTags:tagsTextField.text];
		[postDetailViewController.post setStatus:statusTextField.text];
		[postDetailViewController.post setContent:textView.text];
	}
	if(titleTextField.text != nil)
		[dm.currentPost setObject:titleTextField.text forKey:@"title"];
	if(tagsTextField.text != nil)
		[dm.currentPost setObject:tagsTextField.text forKey:@"mt_keywords"];
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
	
	NSArray *cats = [postDetailViewController.post.blog.categories allObjects];
	NSArray *selObject;
	
    selObject = [postDetailViewController.post.categories allObjects];
	
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
			[self refreshCurrentPostForUI];
			postDetailViewController.editMode = kEditPost;
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
		statusTextField.text = postDetailViewController.post.statusTitle;
	}
}

- (void)populateSelectionsControllerWithStatuses {
    if (selectionTableViewController == nil)
        selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
    NSArray *dataSource = [self.postDetailViewController.post availableStatuses];
	
    NSString *curStatus = postDetailViewController.post.statusTitle;
	
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

    if (selContext == kSelectionsStatusContext) {
        NSString *curStatus = [selectedObjects lastObject];
        postDetailViewController.post.statusTitle = curStatus;
        statusTextField.text = curStatus;
    }
    
    if (selContext == kSelectionsCategoriesContext) {
        NSLog(@"selected categories: %@", selectedObjects);
        NSLog(@"post: %@", postDetailViewController.post);
        postDetailViewController.post.categories = [NSMutableSet setWithArray:selectedObjects];
        categoriesTextField.text = [postDetailViewController.post categoriesText];
    }
	
    [selctionController clean];
    postDetailViewController.hasChanges = YES;
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
    addCategoryViewController.blog = postDetailViewController.post.blog;
	if (DeviceIsPad() == YES) {
		[self refreshCurrentPostForUI];
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

- (void)showDoneButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                                                  target:self action:@selector(endTextEnteringButtonAction:)];
    postDetailViewController.navigationItem.leftBarButtonItem = doneButton;
    postDetailViewController.navigationItem.rightBarButtonItem = nil;
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
        postDetailViewController.post.content = text;
		
		if (DeviceIsPad() == NO) {
            [postDetailViewController refreshButtons];
		}
    }
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
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentEditingTextField = nil;
	
    if (textField == titleTextField) {
        postDetailViewController.post.postTitle = textField.text;
        
        // FIXME: this should be -[PostsViewController updateTitle]
        if ([postDetailViewController.post.postTitle length] > 0) {
            postDetailViewController.navigationItem.title = postDetailViewController.post.postTitle;
        } else {
            postDetailViewController.navigationItem.title = @"Write";
        }

    }
	else if (textField == tagsTextField)
        postDetailViewController.post.tags = tagsTextField.text;
    
    [postDetailViewController.post autosave];
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
		textViewPlaceHolderField.hidden = YES;
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
		textViewPlaceHolderField.hidden = YES;
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

#pragma mark -
#pragma mark Keyboard management 

- (void)keyboardWillShow:(NSNotification *)notification {
	postDetailViewController.isShowingKeyboard = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
	postDetailViewController.isShowingKeyboard = NO;
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
