#import "EditPostViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "WPNavigationLeftButtonView.h"

NSTimeInterval kAnimationDuration = 0.3f;

@interface EditPostViewController (privates)

- (void)clearPickerContrller;
- (void)showEditPostModalViewWithAnimation:(BOOL)animate;

@end

@implementation EditPostViewController

@synthesize postDetailViewController, selectionTableViewController, segmentedTableViewController, leftView, customFieldsTableView;
@synthesize infoText, urlField, bookMarksArray, selectedLinkRange, currentEditingTextField, isEditing, initialLocation;
@synthesize customFieldsEditButton, editCustomFields, isCustomFieldsEnabledForThisPost, locationButton, locationSpinner;

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
    //customFieldsEditButton.hidden = YES;
    //customFieldsEditButton.enabled = NO;
    
    titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    tagsTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    categoriesTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    //tagsTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
    categoriesLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    tagsLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
    
    titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    tagsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [contentView bringSubviewToFront:textView];
    
    if (!leftView) {
        leftView = [WPNavigationLeftButtonView createCopyOfView];
        [leftView setTitle:@"Posts"];
    }
    
    [leftView setTitle:@"Posts"];
    [leftView setTarget:self withAction:@selector(cancelView:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
    
    //JOHNB TODO: Add a check here for the presence of custom fields in the data model
    // if there are, set isCustomFieldsEnabledForThisPost BOOL to true
    isCustomFieldsEnabledForThisPost = [self checkCustomFieldsMinusMetadata];
    //call a helper to set originY for textViewContentView
    [self postionTextViewContentView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self dismissModalViewControllerAnimated:YES];
    //NSLog(@"inside PostDetailEditController:viewWillAppear, just called [super viewWillAppear:YES]");
	//NSLog(@"%@", [[BlogDataManager sharedDataManager] currentPost]);
	//NSLog(@"inside PostDetailEditController:viewWillAppear, hasChanges equals:: %@", self.postDetailViewController.hasChanges);
	//NSLog(@"BOOL = %d", (int)self.postDetailViewController.hasChanges);
	//NSLog(@"hasChanges = %@\n", (self.postDetailViewController.hasChanges ? @"YES" : @"NO")); 
    //isCustomFieldsEnabledForThisPost = [self checkCustomFieldsMinusMetadata];
    isCustomFieldsEnabledForThisPost = YES;
	
    if (isCustomFieldsEnabledForThisPost) {
        customFieldsEditButton.hidden = NO;
        tableViewForSelectingCustomFields.hidden = NO;
        
        customFieldsEditButton.enabled = YES;
    } else {
        customFieldsEditButton.hidden = YES;
        tableViewForSelectingCustomFields.hidden = YES;
        //customFieldsEditButton.enabled = NO;
    }
	
	// Check that Geotagging is enabled
	NSString *geotaggingSettingName = [NSString stringWithFormat:@"%@-Geotagging", [[[BlogDataManager sharedDataManager]  currentBlog] valueForKey:kBlogId]];
	if(![[NSUserDefaults standardUserDefaults] boolForKey:geotaggingSettingName])
	{
		// If disabled, hide our geo button
		locationButton.hidden = YES;
	}
	else {
		// Otherwise, show the geo button, and get this party started
		locationButton.hidden = NO;
		
		// If the post has already been geotagged, reflect this in the icon, and store the
		// location so we can determine any changes to location in the future
		if([self isPostGeotagged])
		{
			[locationButton setImage:[UIImage imageNamed:@"hasLocation.png"] forState:UIControlStateNormal];
			
			CLLocation *postLocation = [self getPostLocation];
			if(postLocation != nil)
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
		
		[locationButton setNeedsLayout];
		[locationButton setNeedsDisplay];
	}
    
    [self postionTextViewContentView];
    [self refreshUIForCurrentPost];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (BOOL)isPostPublished {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
		
	if([[status lowercaseString] isEqualToString:@"published"])
		return YES;
	else
		return NO;
}

- (void)refreshUIForCompose {
    //	textView.alpha = 0.3f;
    //	textView.text = @"Tap here to begin writing";
    titleTextField.text = @"";
    tagsTextField.text = @"";
    textView.text = @"";
    textViewPlaceHolderField.hidden = NO;
    categoriesTextField.text = @"";
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
    status = (status == nil ? @"" : status);
    statusTextField.text = status;
}

- (void)refreshUIForCurrentPost {
//TODO:JOHNBCustomFields: It's possible we want an entry here, not sure yet
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

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

    titleTextField.text = [dm.currentPost valueForKey:@"title"];
    tagsTextField.text = [dm.currentPost valueForKey:@"mt_keywords"];

    NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
    status = (status == nil ? @"" : status);
    statusTextField.text = status;

    NSArray *cats = [[dm currentPost] valueForKey:@"categories"];

    if (status)
        categoriesTextField.text = [cats componentsJoinedByString:@", "];else
        categoriesTextField.text = @"";
	
	// Set our initial location so we can determine if the geotag has been updated later
	initialLocation = [self getPostLocation];
}

- (void)populateSelectionsControllerWithCategories {
    if (segmentedTableViewController == nil)
        segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];

    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];

    NSArray *selObject = [[dm currentPost] valueForKey:@"categories"];

    if (selObject == nil)
        selObject = [NSArray array];

    [segmentedTableViewController populateDataSource:cats    //datasorce
     havingContext:kSelectionsCategoriesContext
     selectedObjects:selObject
     selectionType:kCheckbox
     andDelegate:self];

    segmentedTableViewController.title = @"Categories";
    segmentedTableViewController.navigationItem.rightBarButtonItem = newCategoryBarButtonItem;

    if (isNewCategory != YES) {
        [postDetailViewController.navigationController pushViewController:segmentedTableViewController animated:YES];
    }

    isNewCategory = NO;
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

    if (dm.isLocaDraftsCurrent || dm.currentPostIndex == -1)
        dataSource = [dataSource arrayByAddingObject:@"Local Draft"];

    NSString *curStatus = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
    NSArray *selObject = (curStatus == nil ? [NSArray array] : [NSArray arrayWithObject:curStatus]);

    [selectionTableViewController populateDataSource:dataSource
     havingContext:kSelectionsStatusContext
     selectedObjects:selObject
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = @"Status";
    selectionTableViewController.navigationItem.rightBarButtonItem = nil;
    [postDetailViewController.navigationController pushViewController:selectionTableViewController animated:YES];
    [selectionTableViewController release];
    selectionTableViewController = nil;
}

- (void)populateCustomFieldsTableViewControllerWithCustomFields {
    //initialize the new view if it doesn't exist
    if (customFieldsTableView == nil)
        customFieldsTableView = [[CustomFieldsTableView alloc] initWithNibName:@"CustomFieldsTableView" bundle:nil];

    customFieldsTableView.postDetailViewController = self.postDetailViewController;
    //load the CustomFieldsTableView  Note: customFieldsTableView loads some data in viewDidLoad
    [customFieldsTableView setIsPost:YES]; //since we're dealing with posts here
    [postDetailViewController.navigationController pushViewController:customFieldsTableView animated:YES];
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

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

    [selctionController clean];
    postDetailViewController.hasChanges = YES;
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification {
    if ([segmentedTableViewController curContext] == kSelectionsCategoriesContext) {
        isNewCategory = YES;
        [self populateSelectionsControllerWithCategories];
    }
}

- (IBAction)showAddNewCategoryView:(id)sender {
	
    WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
    [segmentedTableViewController presentModalViewController:nc animated:YES];
    [nc release];
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
	if((postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)){
		//[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationPortrait];
	}
}

- (IBAction)showCategoriesViewAction:(id)sender {
	//[self showEditPostModalViewWithAnimation:YES];
    [self populateSelectionsControllerWithCategories];
	
}

- (IBAction)showStatusViewAction:(id)sender {
    [self populateSelectionsControllerWithStatuses];
	
}

- (IBAction)showCustomFieldsTableView:(id)sender {
    [self populateCustomFieldsTableViewControllerWithCustomFields];
}

- (void)bringTextViewUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kAnimationDuration];

/*   This is for custom fields - IF we keep current UI... out for now until 1.5
	if (isCustomFieldsEnabledForThisPost) {
        CGRect frame = textViewContentView.frame;
        frame.origin.y -= 220.0f; //was 164, 214 is new value to accomodate custom fields "cell + other objects" in IB
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y -= 220.0f; //was 164
        subView.frame = frame;
    } else {
 */
        CGRect frame = textViewContentView.frame;
        frame.origin.y -= 170.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y -= 175.0f;
        //frame.origin.y -= 175.0f;
        subView.frame = frame;
	
   // remove "//" for custom fields }

    [UIView commitAnimations];
    //[self.view setNeedsDisplay];
}

- (void)bringTextViewDown {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    subView.hidden = NO;

/*   This is for custom fields - IF we keep current UI... out for now until 1.5
    if (isCustomFieldsEnabledForThisPost) {
        CGRect frame = textViewContentView.frame;
        frame.origin.y += 220.0f; //was 164
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y += 220.0f; //was 164
        subView.frame = frame;
    } else {
 */
        CGRect frame = textViewContentView.frame;
        frame.origin.y += 170.0f;
        textViewContentView.frame = frame;

        frame = subView.frame;
        frame.origin.y = 0.0f;
        subView.frame = frame;
	
     // remove "//" for custom fields }

    [UIView commitAnimations];
}

- (void)updateTextViewPlacehoderFieldStatus {
    if ([textView.text length] == 0) {
        textViewPlaceHolderField.hidden = NO;
    } else {
        textViewPlaceHolderField.hidden = YES;
    }
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

- (void)setTextViewHeight:(float)height {
    CGRect frame = textView.frame;
    frame.size.height = height;
    textView.frame = frame;
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
		
        if ((postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            [self setTextViewHeight:116];
        }

        [self updateTextViewPlacehoderFieldStatus];

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                       target:self action:@selector(endTextEnteringButtonAction:)];

        postDetailViewController.navigationItem.leftBarButtonItem = doneButton;
        [doneButton release];
        [self bringTextViewUp];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView {
	
    isEditing = YES;

	if ((postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
		|| (postDetailViewController.interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
        [self setTextViewHeight:116];
		

    }
	
    dismiss = NO;

    if (!isTextViewEditing) {
        isTextViewEditing = YES;

        [self updateTextViewPlacehoderFieldStatus];

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                       target:self action:@selector(endTextEnteringButtonAction:)];
        postDetailViewController.navigationItem.leftBarButtonItem = doneButton;
        [doneButton release];

        [self bringTextViewUp];
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
        aTextView.selectedRange = endRange; 
		
        [updatedText release];
		
        // let the textView know that it should ingore the inserted text
        return NO;
    }
	
    [updatedText release];
	
    // let the textView know that it should handle the inserted text
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView {
    postDetailViewController.hasChanges = YES;
    [self updateTextViewPlacehoderFieldStatus];

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
}

- (void)textViewDidEndEditing:(UITextView *)aTextView {
    if ((postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (postDetailViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        [self setTextViewHeight:57];
	}
	

    isEditing = NO;
    dismiss = NO;

    if (isTextViewEditing) {
        isTextViewEditing = NO;

        [self bringTextViewDown];

        if (postDetailViewController.hasChanges == YES) {
            [leftView setTitle:@"Cancel"];
        } else {
            [leftView setTitle:@"Posts"];
        }

        UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:leftView];
        postDetailViewController.navigationItem.leftBarButtonItem = barItem;
        [barItem release];
        [self updateTextViewPlacehoderFieldStatus];
        NSString *text = aTextView.text;
        [[[BlogDataManager sharedDataManager] currentPost] setObject:text forKey:@"description"];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentEditingTextField = textField;
    [self updateTextViewPlacehoderFieldStatus];

    if (postDetailViewController.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
        [self textViewDidEndEditing:textView];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentEditingTextField = nil;

    if (textField == titleTextField)
        [[BlogDataManager sharedDataManager].currentPost setValue:textField.text forKey:@"title"];else if (textField == tagsTextField)
        [[BlogDataManager sharedDataManager].currentPost setValue:tagsTextField.text forKey:@"mt_keywords"];
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

- (IBAction)showPhotoUploadScreen:(id)sender;
{
    [self showPhotoPickerActionSheet];
}

- (WPImagePickerController *)pickerController {
    if (pickerController == nil) {
        pickerController = [[WPImagePickerController alloc] init];
        pickerController.delegate = self;
        pickerController.allowsImageEditing = NO;
    }

    return pickerController;
}

- (void)showPhotoPickerActionSheet {
    isShowPhotoPickerActionSheet = YES;
    // open a dialog with two custom buttons
    UIActionSheet *actionSheet;

    if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:@""
                       delegate:self
                       cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                       otherButtonTitles:@"Add Photo from Library", @"Take Photo with Camera", nil];
    } else {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:@""
                       delegate:self
                       cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                       otherButtonTitles:@"Add Photo from Library", nil];
    }

    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];

    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (isShowPhotoPickerActionSheet) {
        if (buttonIndex == 0)
            [self pickPhotoFromPhotoLibrary:nil];else
            [self pickPhotoFromCamera:nil];
    } else {
        if (buttonIndex == 0) { //add
            [self useImage:currentChoosenImage];
        } else if (buttonIndex == 1) { //add and return
            [self useImage:currentChoosenImage];
            //	[picker popViewControllerAnimated:YES];
            WPImagePickerController *picker = [self pickerController];
            [[picker parentViewController] dismissModalViewControllerAnimated:YES];
            [self clearPickerContrller];
        } else {
            //do nothing
        }

        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:NO];

        [currentChoosenImage release];
        currentChoosenImage = nil;
    }
}

- (void)pickPhotoFromCamera:(id)sender {
    [[BlogDataManager sharedDataManager] makeNewPictureCurrent];

    if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        WPImagePickerController *picker = [self pickerController];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;

        // Picker is displayed asynchronously.
        [[postDetailViewController navigationController] presentModalViewController:picker animated:YES];
    }
}

- (void)pickPhotoFromPhotoLibrary:(id)sender {
    [[BlogDataManager sharedDataManager] makeNewPictureCurrent];

    if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        WPImagePickerController *picker = [self pickerController];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // Picker is displayed asynchronously.
        [postDetailViewController.navigationController presentModalViewController:picker animated:YES];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingImage:(UIImage *)image
editingInfo:(NSDictionary *)editingInfo {
    currentChoosenImage = [image retain];
    isShowPhotoPickerActionSheet = NO;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                  otherButtonTitles:@"Add and Select More", @"Add and Continue Editing", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];

    [actionSheet release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

// Implement this method in your code to do something with the image.
- (void)useImage:(UIImage *)theImage {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    postDetailViewController.hasChanges = YES;

    id currentPost = dataManager.currentPost;

    if (![currentPost valueForKey:@"Photos"])
        [currentPost setValue:[NSMutableArray array] forKey:@"Photos"];

    [[currentPost valueForKey:@"Photos"] addObject:[dataManager saveImage:theImage]];
    [postDetailViewController updatePhotosBadge];
}

- (void)pictureChoosenNotificationReceived:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"WPPhotoChoosen" object:nil];

    NSString *pictureURL = [[aNotification userInfo] valueForKey:@"pictureURL"];
    NSString *curText = textView.text;
    curText = (curText == nil ? @"" : curText);
    textView.text = [curText stringByAppendingString:[NSString stringWithFormat:@"<img src=\"%@\" alt=\"\" />", pictureURL]];
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
        label.tag = kLabelTag;
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        [cell.contentView addSubview:label];
        [label release];
    }

    NSUInteger row = [indexPath row];

    UILabel *label = (UILabel *)[cell viewWithTag:kLabelTag];

    if (row == 0) {
        label.text = @"Edit Custom Fields";
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
#pragma mark Table Delegate Methods
- (NSIndexPath *)tableView:(UITableView *)tableView
willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark -
#pragma mark Custom Fields methods
- (void)postionTextViewContentView {
//removing custom fields code for now.  will integrate into 1.4 if time allows
//    if (isCustomFieldsEnabledForThisPost) {
//        originY = 214.0f;
//        CGRect frame = textViewContentView.frame;
//        frame.origin.y = originY;
//        [textViewContentView setFrame:frame];
//    } else {
        originY = 164.0f;
        CGRect frame = textViewContentView.frame;
        frame.origin.y = originY;
        [textViewContentView setFrame:frame];
//    }
}

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
                NSLog(@"Removing metadata key: %@", tempKey);
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
#pragma mark Show EditPostModalView (Modal View)

- (void)showEditPostModalViewWithAnimation:(BOOL)animate {
	EditPostModalViewController *editPostModalViewController = [[[EditPostModalViewController alloc] initWithNibName:@"EditPostModalViewController" bundle:nil] autorelease];
	[postDetailViewController.navigationController pushViewController:editPostModalViewController animated:animate];
}

#pragma mark -
#pragma mark Location Methods

- (BOOL)isPostGeotagged {
	if([self getPostLocation] != nil)
		return YES;
	else
		return NO;
}

- (IBAction)showLocationMapView:(id)sender {
	// Display the geotag view
	PostLocationViewController *locationView = [[PostLocationViewController alloc] initWithNibName:@"PostLocationViewController" bundle:nil];
	[postDetailViewController presentModalViewController:locationView animated:YES];
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
			result = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
			break;
		}
		else
			result = nil;
	}
	
	return result;
}

#pragma mark -
#pragma mark Memory Stuff

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [infoText release];
    [urlField release];
    [leftView release];
    [bookMarksArray release];
    [segmentedTableViewController release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
    [customFieldsTableView release];
	[locationButton release];
	[locationSpinner release];
    [super dealloc];
}

@end
