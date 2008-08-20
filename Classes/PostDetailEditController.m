#import "PostDetailEditController.h"
#import "BlogDataManager.h"

NSTimeInterval kAnimationDuration = 0.3f;

@implementation PostDetailEditController

@synthesize postDetailViewController, selectionTableViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)refreshUIForCompose
{
//	textView.alpha = 0.3f;
//	textView.text = @"Tap here to begin writing";
	titleTextField.text = @"";
	tagsTextField.text = @"";
	textView.text = @"";
	textViewPlaceHolderField.hidden = NO;
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
	status = ( status == nil ? @"" : status );
	statusTextField.text = status ;
	
	NSArray *cats = [[dm currentPost] valueForKey:@"categories"];
	if( status )
		categoriesTextField.text = [cats componentsJoinedByString:@", "];
	else 
		categoriesTextField.text = @"";
}

- (void)refreshUIForCurrentPost
{
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *description = [dm.currentPost valueForKey:@"description"];

	if (!description || [description length] == 0 ) {
		textViewPlaceHolderField.hidden = NO;
		textView.text = @"";
//		textView.alpha = 0.3f;
//		textView.text = @"Tap here to begin writing";
	}
	else {
		textViewPlaceHolderField.hidden = YES;
//		textView.alpha = 1.0f;
		textView.text = description;
	}
	
	titleTextField.text = [dm.currentPost valueForKey:@"title"];
	tagsTextField.text = [dm.currentPost valueForKey:@"mt_keywords"];
	
	NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
	status = ( status == nil ? @"" : status );
	statusTextField.text = status ;

	
	NSArray *cats = [[dm currentPost] valueForKey:@"categories"];
	if( status )
		categoriesTextField.text = [cats componentsJoinedByString:@", "];
	else 
		categoriesTextField.text = @"";
}



- (void)populateSelectionsControllerWithCategories
{
	if (selectionTableViewController == nil)
		selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];
	
	NSArray *dataSource = [cats valueForKey:@"categoryName"];
	dataSource = [dm uniqueArray:dataSource];
	
	NSArray *selObject = [[dm currentPost] valueForKey:@"categories"];
	if( selObject == nil )
		selObject = [NSArray array];
	
	[selectionTableViewController populateDataSource:dataSource
									   havingContext:kSelectionsCategoriesContext
									 selectedObjects:selObject
									   selectionType:kCheckbox
										 andDelegate:self];
	selectionTableViewController.title = @"Categories";
	selectionTableViewController.navigationItem.rightBarButtonItem = newCategoryBarButtonItem;
	WPLog(@"selectionTableViewController navigationItem %@", selectionTableViewController.navigationItem);
	[postDetailViewController.navigationController pushViewController:selectionTableViewController animated:YES];	
}

- (void)populateSelectionsControllerWithStatuses
{
	if (selectionTableViewController == nil)
		selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"postStatusList"];
	
	NSArray *dataSource = [postStatusList allValues] ;
	
	if( dm.isLocaDraftsCurrent || dm.currentPostIndex == -1 )
		dataSource = [dataSource arrayByAddingObject:@"Local Draft"];
	
	NSString *curStatus = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
	NSArray *selObject = ( curStatus == nil ? [NSArray array] : [NSArray arrayWithObject:curStatus] );
	
	[selectionTableViewController populateDataSource:dataSource
									   havingContext:kSelectionsStatusContext
									 selectedObjects:selObject
									   selectionType:kRadio
										 andDelegate:self];
	
	selectionTableViewController.title = @"Status";
	selectionTableViewController.navigationItem.rightBarButtonItem = nil;
	[postDetailViewController.navigationController pushViewController:selectionTableViewController animated:YES];
}


- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged
{
	//	WPLog(@" %@ completedSelectionsWithContext %u isChanged %d selectedObjects %@", [self className], selContext, isChanged, selectedObjects);
	if( !isChanged )
	{
		[selctionController clean];
		return;
	}
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( selContext == kSelectionsStatusContext )
	{
		NSString *curStatus = [selectedObjects lastObject];
		NSString *status = [dm statusForStatusDescription:curStatus fromBlog:dm.currentBlog];
		if( status )
		{
			[[dm currentPost] setObject:status forKey:@"post_status"];
			statusTextField.text = curStatus ;
		}	
	}
	
	if( selContext == kSelectionsCategoriesContext )
	{
		[[dm currentPost] setObject:selectedObjects forKey:@"categories"];
		categoriesTextField.text = [selectedObjects componentsJoinedByString:@", "];
	}
	
	[selctionController clean];
	postDetailViewController.hasChanges = YES;
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification
{
	if( [selectionTableViewController curContext] == kSelectionsCategoriesContext )
	{
		[self populateSelectionsControllerWithCategories];
	}
}

- (IBAction)showAddNewCategoryView:(id)sender
{
	WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
	[selectionTableViewController presentModalViewController:nc animated:YES];
	[nc release];
	[addCategoryViewController release];
}


- (void)endEditingAction:(id)sender
{
	[titleTextField resignFirstResponder];
	[tagsTextField resignFirstResponder];
	[textView resignFirstResponder];
}

//will be called when auto save method is called.
- (void)updateValuesToCurrentPost
{
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *str = textView.text;
	str = ( str	!= nil ? str : @"" );
	[dm.currentPost setValue:str forKey:@"description"];
	
	str = tagsTextField.text;
	str = ( str	!= nil ? str : @"" );
	[dm.currentPost setValue:str forKey:@"mt_keywords"];
	
	str = titleTextField.text;
	str = ( str	!= nil ? str : @"" );
	[dm.currentPost setValue:str forKey:@"title"];
}

- (IBAction)cancelView:(id)sender {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)endTextEnteringButtonAction:(id)sender
{
	[textView resignFirstResponder];
}

- (IBAction)showCategoriesViewAction:(id)sender
{
	[self populateSelectionsControllerWithCategories];
}

- (IBAction)showStatusViewAction:(id)sender
{
	[self populateSelectionsControllerWithStatuses];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	tagsTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	categoriesTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	tagsTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];	
	categoriesLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	tagsLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];

	titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	tagsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	[contentView bringSubviewToFront:textView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
}

- (void)bringTextViewUp
{
//	if( subView.hidden )
//		return;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kAnimationDuration];
	
	CGRect frame = textViewContentView.frame;
	frame.origin.y -= 165.0f;
	textViewContentView.frame = frame;
//	subView.hidden = YES;
	
	frame = subView.frame;
	frame.origin.y -= 165.0f;
	subView.frame = frame;
	
	
	[UIView commitAnimations];
	[self.view setNeedsDisplay];	
}

- (void)bringTextViewDown
{
//	if( subView.hidden )
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		subView.hidden = NO;

		CGRect frame = textViewContentView.frame;
		frame.origin.y += 165.0f;
		textViewContentView.frame = frame;	
		
		frame = subView.frame;
		frame.origin.y += 165.0f;
		subView.frame = frame;
		
		[UIView commitAnimations];		
	}
}

- (void)updateTextViewPlacehoderFieldStatus
{
	if ( [textView.text length] == 0 )
	{
		textViewPlaceHolderField.hidden = NO;
	}
	else {
		textViewPlaceHolderField.hidden = YES;
	}	
}

- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	if (!isTextViewEditing) 
	{
		isTextViewEditing = YES;
		
		[self updateTextViewPlacehoderFieldStatus];

//		if ([aTextView.text isEqualToString:@"Tap here to begin writing"]) {
////			textView.alpha = 1.0f;
////			aTextView.text = @"";
//		}
//		else if ([aTextView.text isEqualToString:@""]) {
//			textView.alpha = 0.3f;
//			aTextView.text = @"Tap here to begin writing";
//		}

		postDetailViewController.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
		postDetailViewController.navigationItem.leftBarButtonItem.title = @"Done";
		postDetailViewController.navigationItem.leftBarButtonItem.target = self;
		postDetailViewController.navigationItem.leftBarButtonItem.action = @selector(endTextEnteringButtonAction:);

		[self bringTextViewUp];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView
{	
	if (!isTextViewEditing) {
		isTextViewEditing = YES;
		
		[self updateTextViewPlacehoderFieldStatus];
		
//		if ([aTextView.text isEqualToString:@"Tap here to begin writing"]) {
//			textView.alpha = 1.0f;
//			aTextView.text = @"";
//		}
//		else if ([aTextView.text isEqualToString:@""]) {
//			textView.alpha = 0.3f;
//			aTextView.text = @"Tap here to begin writing";
//		}


		postDetailViewController.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
		postDetailViewController.navigationItem.leftBarButtonItem.title = @"Done";
		postDetailViewController.navigationItem.leftBarButtonItem.target = self;
		postDetailViewController.navigationItem.leftBarButtonItem.action = @selector(endTextEnteringButtonAction:);

		[self bringTextViewUp];
	}
}

- (void)textViewDidChange:(UITextView *)textView {
	postDetailViewController.hasChanges = YES;
	[self updateTextViewPlacehoderFieldStatus];
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{	
	if( isTextViewEditing )
	{
		isTextViewEditing = NO;
		
		[self bringTextViewDown];
		
		postDetailViewController.navigationItem.leftBarButtonItem.target = postDetailViewController;
		postDetailViewController.navigationItem.leftBarButtonItem.action = @selector(cancelView:);
		if (postDetailViewController.hasChanges == YES)
			postDetailViewController.navigationItem.leftBarButtonItem.title = @"Cancel";
		else
			postDetailViewController.navigationItem.leftBarButtonItem.title = @"Posts";
			
		postDetailViewController.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleBordered;
		
		[self updateTextViewPlacehoderFieldStatus];
		NSString *text = aTextView.text;
//		NSString *text = @"";
//		if ([aTextView.text isEqualToString:@"Tap here to begin writing"]) {
//			textView.alpha = 1.0f;
//			aTextView.text = text;
//		} else if ([textView.text isEqualToString:text]) {
//			textView.alpha = 0.3f;
//			textView.text = @"Tap here to begin writing";
//		} else
//			text = aTextView.text;
		
		[[[BlogDataManager sharedDataManager] currentPost] setObject:text forKey:@"description"];		
	}
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
//	if ([textView.text isEqualToString:@""]) {
//		textView.alpha = 0.3f;
//		textView.text = @"Tap here to begin writing";
//	}
	[self updateTextViewPlacehoderFieldStatus];

	if (postDetailViewController.navigationItem.leftBarButtonItem.style == UIBarButtonItemStyleDone) {
		[self textViewDidEndEditing:textView];
	}
	//**postDetailViewController.hasChanges = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	//** postDetailViewController.hasChanges = YES;
	
	if( textField == titleTextField )
		[[BlogDataManager sharedDataManager].currentPost setValue:textField.text forKey:@"title"];
	if( textField == tagsTextField )
		[[BlogDataManager sharedDataManager].currentPost setValue:tagsTextField.text forKey:@"mt_keywords"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}


- (IBAction)showPhotoUploadScreen:(id)sender;
{
	[self showPhotoPickerActionSheet];
}

- (UIImagePickerController*)pickerController
{
	if( pickerController == nil ) {
		pickerController = [[UIImagePickerController alloc] init];
		pickerController.delegate = self;
		pickerController.allowsImageEditing = NO;
	}
	WPLog(@"pickerController %@", pickerController);
	return pickerController;
}

- (void)showPhotoPickerActionSheet
{
	isShowPhotoPickerActionSheet = YES;
	// open a dialog with two custom buttons
	UIActionSheet *actionSheet;
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
	
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
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	if( isShowPhotoPickerActionSheet )
	{
		if (buttonIndex == 0)
			[self pickPhotoFromPhotoLibrary:nil];
		else
			[self pickPhotoFromCamera:nil];		
	}
	else 
	{
		if (buttonIndex == 0) //add
		{
			[self useImage:currentChoosenImage];
		}
		else if (buttonIndex == 1) //add and return
		{
			[self useImage:currentChoosenImage];
			//	[picker popViewControllerAnimated:YES];
			UIImagePickerController* picker = [self pickerController];
			[[picker parentViewController] dismissModalViewControllerAnimated:YES];
		}
		else 
		{
			//do nothing
		}
		[currentChoosenImage release];
		currentChoosenImage = nil;
	}
}

- (void)pickPhotoFromCamera:(id)sender {
	[[BlogDataManager sharedDataManager] makeNewPictureCurrent];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		UIImagePickerController* picker = [self pickerController];
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		
		// Picker is displayed asynchronously.
		[[postDetailViewController navigationController] presentModalViewController:picker animated:YES];
	}
}

- (void)pickPhotoFromPhotoLibrary:(id)sender {
	[[BlogDataManager sharedDataManager] makeNewPictureCurrent];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		UIImagePickerController* picker = [self pickerController];
		picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		// Picker is displayed asynchronously.
		[postDetailViewController.navigationController presentModalViewController:picker animated:YES];
	}
}


- (void)imagePickerController:(UIImagePickerController *)picker
				didFinishPickingImage:(UIImage *)image
									editingInfo:(NSDictionary *)editingInfo
{
	currentChoosenImage = [image retain];
	isShowPhotoPickerActionSheet = NO;
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
															 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
													otherButtonTitles:@"Add and Select More", @"Add and Continue Editing", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	[actionSheet showInView:self.view];
	[actionSheet release];	
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

// Implement this method in your code to do something with the image.
- (void)useImage:(UIImage*)theImage
{
	
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
//	NSString *url = [dataManager pictureURLBySendingToServer:theImage];
//	if( !url )
//		return;
	
//	NSString *curText = textView.text;
//	curText = ( curText == nil ? @"" : curText );
//	textView.text = [curText stringByAppendingString:[NSString stringWithFormat:@"<img src=\"%@\"></img>",url]];
//	[dataManager.currentPost setObject:textView.text forKey:@"description"];
	postDetailViewController.hasChanges = YES;

	id currentPost = dataManager.currentPost;
	if (![currentPost valueForKey:@"Photos"])
		[currentPost setValue:[NSMutableArray array] forKey:@"Photos"];
	
	[[currentPost valueForKey:@"Photos"] addObject:[dataManager saveImage:theImage]];
	[postDetailViewController updatePhotosBadge];
}

- (void)pictureChoosenNotificationReceived:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"WPPhotoChoosen" object:nil];
	
	NSString *pictureURL = [[aNotification userInfo] valueForKey:@"pictureURL"];
	NSString *curText = textView.text;
	curText = ( curText == nil ? @"" : curText );
	textView.text = [curText stringByAppendingString:[NSString stringWithFormat:@"<img src=\"%@\" alt=\"\" />",pictureURL]]; 
}

- (void)didReceiveMemoryWarning {
		WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
	
//	[pickerController release];
//	pickerController = nil;
}


- (void)dealloc 
{	
	[selectionTableViewController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[super dealloc];
}


@end

