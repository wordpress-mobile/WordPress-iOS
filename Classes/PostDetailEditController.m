#import "PostDetailEditController.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "WPNavigationLeftButtonView.h"


NSTimeInterval kAnimationDuration = 0.3f;

@interface PostDetailEditController (privates)

- (void)clearPickerContrller;

@end

@implementation PostDetailEditController

@synthesize postDetailViewController, selectionTableViewController,segmentedTableViewController,leftView;
@synthesize infoText,urlField,bookMarksArray,selectedLinkRange,currentEditingTextField;

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
	categoriesTextField.text = @"";
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *status = [dm statusDescriptionForStatus:[dm.currentPost valueForKey:@"post_status"] fromBlog:dm.currentBlog];
	status = ( status == nil ? @"" : status );
	statusTextField.text = status ;
}

- (void)refreshUIForCurrentPost
{

	BlogDataManager *dm = [BlogDataManager sharedDataManager];

	NSString *description = [dm.currentPost valueForKey:@"description"];
	NSString *moreText = [dm.currentPost valueForKey:@"mt_text_more"];
	
	if (!description || [description length] == 0 ) {
		textViewPlaceHolderField.hidden = NO;
		textView.text = @"";
	} else {
		textViewPlaceHolderField.hidden = YES;
		if((moreText!=NULL)&&([moreText length]>0))
			textView.text = [NSString stringWithFormat:@"%@\n<!--more-->%@",description,moreText];
		else
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
	if (segmentedTableViewController == nil)
		segmentedTableViewController = [[WPSegmentedSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
    
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSArray *cats = [[dm currentBlog] valueForKey:@"categories"];
	
    //Start Extracting and constructing the Categories in an array of arrays in which the '0' index is a parent.   
    NSMutableArray *parentIds = [[NSMutableArray alloc] initWithCapacity:[cats count]];
    int i,j,categoryCount = [cats count];
    for(i = 0;i < categoryCount; i++){
        
		int parent = [[[cats objectAtIndex:i] valueForKey:@"parentId"] intValue];
      	if(parent == 0){
            [parentIds addObject:[cats objectAtIndex:i]]; 
        }
    }
    
    NSMutableArray *childIds = [[NSMutableArray alloc] init];
    int parentCount = [parentIds count];
    for(i = 0;i < parentCount; i++){
		
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        [tempArray addObject:[parentIds objectAtIndex:i]];
        for(j = 0;j < categoryCount; j++){
            int parent = [[[parentIds objectAtIndex:i] objectForKey:@"categoryId"] intValue];
            int child = [[[cats objectAtIndex:j] valueForKey:@"parentId"] intValue];
            if(parent == child){
                [tempArray addObject:[cats objectAtIndex:j]];
            }
        }
        [childIds addObject:tempArray];
        [tempArray release];
    }
	
	NSArray *selObject = [[dm currentPost] valueForKey:@"categories"];
	if( selObject == nil )
        selObject = [NSArray array];
    [segmentedTableViewController populateDataSource:childIds    //datasorce
									   havingContext:kSelectionsCategoriesContext
									 selectedObjects:selObject
									   selectionType:kCheckbox
										 andDelegate:self];
	
    segmentedTableViewController.title = @"Categories";
	segmentedTableViewController.navigationItem.rightBarButtonItem = newCategoryBarButtonItem;
	if(isNewCategory!=YES) {
		[postDetailViewController.navigationController pushViewController:segmentedTableViewController animated:YES];
	}
	isNewCategory=NO;
	[parentIds release];
	[childIds release];
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
	[selectionTableViewController release];
}


- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged
{
	if( !isChanged ){
		[selctionController clean];
		return;
	}
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( selContext == kSelectionsStatusContext ){
		NSString *curStatus = [selectedObjects lastObject];
		NSString *status = [dm statusForStatusDescription:curStatus fromBlog:dm.currentBlog];
		if( status ){
			[[dm currentPost] setObject:status forKey:@"post_status"];
			statusTextField.text = curStatus ;
		}	
	}
	
	if( selContext == kSelectionsCategoriesContext ){
		[[dm currentPost] setObject:selectedObjects forKey:@"categories"];
		categoriesTextField.text = [selectedObjects componentsJoinedByString:@", "];
	}
	
	[selctionController clean];
	postDetailViewController.hasChanges = YES;
}

- (void)newCategoryCreatedNotificationReceived:(NSNotification *)notification
{
	if( [segmentedTableViewController curContext] == kSelectionsCategoriesContext ){
		isNewCategory=YES;
		[self populateSelectionsControllerWithCategories];
	}
}

- (IBAction)showAddNewCategoryView:(id)sender
{
	WPAddCategoryViewController *addCategoryViewController = [[WPAddCategoryViewController alloc] initWithNibName:@"WPAddCategoryViewController" bundle:nil];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:addCategoryViewController];
	[segmentedTableViewController presentModalViewController:nc animated:YES];
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
	
    [postDetailViewController cancelView:sender];
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
	
	if(!leftView)
	{   
        leftView = [WPNavigationLeftButtonView createView];
        [leftView setTitle:@"Posts"];
    }   
	[leftView setTitle:@"Posts"];
    [leftView setTarget:self withAction:@selector(cancelView:)];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCategoryCreatedNotificationReceived:) name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
}

- (void)bringTextViewUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kAnimationDuration];
	
	CGRect frame = textViewContentView.frame;
	frame.origin.y -= 165.0f;
	textViewContentView.frame = frame;
	
	frame = subView.frame;
	frame.origin.y -= 165.0f;
	subView.frame = frame;
	
	
	[UIView commitAnimations];
	[self.view setNeedsDisplay];	
}

- (void)bringTextViewDown
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

- (void)updateTextViewPlacehoderFieldStatus
{
	if ( [textView.text length] == 0 ){
		textViewPlaceHolderField.hidden = NO;
	}
	else {
		textViewPlaceHolderField.hidden = YES;
	}	
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if([alertView tag] == 1){
     	if ( buttonIndex == 0 ) 
            [self showLinkView];
		else{
			dismiss=YES;
			[textView touchesBegan:nil withEvent:nil];
			[delegate setAlertRunning:NO];
		}
	}
	
    if([alertView tag] == 2){
     	if ( buttonIndex == 1){
            if((urlField.text == nil)||([urlField.text isEqualToString:@""]))
			{
				[delegate setAlertRunning:NO];
				return;
			}
			if((infoText.text == nil)||([infoText.text isEqualToString:@""]))
				infoText.text=urlField.text;
			
			NSString *commentsStr = textView.text;
			NSRange rangeToReplace=[self selectedLinkRange];
			NSString *urlString=[self validateNewLinkInfo:urlField.text];
			NSString *aTagText=[NSString stringWithFormat:@"<a href=\"%@\">%@</a>",urlString,infoText.text];;
			textView.text = [commentsStr stringByReplacingOccurrencesOfString:[commentsStr substringWithRange:rangeToReplace] withString:aTagText options:NSCaseInsensitiveSearch range:rangeToReplace];
		}
		dismiss = YES;
		[delegate setAlertRunning:NO];
		[textView touchesBegan:nil withEvent:nil];
	}
    return;
}
//code to append http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText{
	NSArray *stringArray=[NSArray arrayWithObjects:@"http:",@"ftp:",@"https:",nil];
	int i,count=[stringArray count];
	BOOL searchRes=NO;
	
	for(i = 0; i < count; i++){
		NSString *searchString=[stringArray objectAtIndex:i];
		
		if(searchRes = [urlText hasPrefix:[searchString capitalizedString]])
			break;
		else if (searchRes = [urlText hasPrefix:[searchString lowercaseString]])
			break;
		else if (searchRes = [urlText hasPrefix:[searchString uppercaseString]])
			break;				
	}
	NSString *returnStr;
	if(searchRes)
		returnStr=[NSString stringWithString:urlText];
	else
		returnStr=[NSString stringWithFormat:@"http://%@",urlText];
	
	return returnStr;
}
-(void)showLinkView
{
    UIAlertView *addURLSourceAlert = [[UIAlertView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.0)];
    infoText = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 36.0, 260.0, 29.0)];
    urlField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 70.0, 260.0, 29.0)];
    infoText.placeholder = @"\n\nEnter Text For Link";
    urlField.placeholder = @"\n\nEnter Link";
    //infoText.enabled = YES;
    
    infoText.autocapitalizationType= UITextAutocapitalizationTypeNone;
    urlField.autocapitalizationType= UITextAutocapitalizationTypeNone;
    infoText.borderStyle = UITextBorderStyleRoundedRect;
    urlField.borderStyle = UITextBorderStyleRoundedRect;
    infoText.keyboardAppearance = UIKeyboardAppearanceAlert;         
    urlField.keyboardAppearance = UIKeyboardAppearanceAlert;
    [addURLSourceAlert addButtonWithTitle:@"Cancel"];
    [addURLSourceAlert addButtonWithTitle:@"OK"];
    addURLSourceAlert.title = @"Make Hyperlink\n\n\n";
    addURLSourceAlert.delegate = self;
    [addURLSourceAlert addSubview:infoText];
    [addURLSourceAlert addSubview:urlField];
    [infoText becomeFirstResponder];
    CGAffineTransform upTransform = CGAffineTransformMakeTranslation(0.0, 140.0);
    [addURLSourceAlert setTransform:upTransform];
    [addURLSourceAlert setTag:2];
    [addURLSourceAlert show];
    [addURLSourceAlert release];
}


- (void)setTextViewHeight:(float)height
{
	if(isEditing==YES)
	{
		CGRect frame = textView.frame;
		frame.size.height+=height;
		textView.frame=frame;
	}
}

#pragma mark TextView & TextField Delegates
- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	
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

- (void)textViewDidBeginEditing:(UITextView *)aTextView
{	
	isEditing=YES;
	if((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight))
	{
		CGRect frame = textView.frame;
		frame.size.height-=60;
		textView.frame=frame;
	}
	
	dismiss=NO;
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

- (void)textViewDidChange:(UITextView *)aTextView {
	postDetailViewController.hasChanges = YES;
	[self updateTextViewPlacehoderFieldStatus];
	if(dismiss==YES) {
		dismiss = NO;
		return;
	}	

	NSRange range=[aTextView selectedRange]; 
	NSArray *stringArray=[NSArray arrayWithObjects:@"http:",@"ftp:",@"https:",@"www.",nil];
	NSString *str=[aTextView text];
	int i,j,count=[stringArray count];
	BOOL searchRes=NO;
	for(j = 4;j <= 6; j++){

		if(range.location < j)
			return;

		NSRange subStrRange;
		subStrRange.location=range.location-j;
		subStrRange.length=j;
		[self setSelectedLinkRange:subStrRange];
		NSString *subStr=[str substringWithRange:subStrRange];
		
		for(i = 0; i < count; i++){
			NSString *searchString=[stringArray objectAtIndex:i];
			
			if(searchRes = [subStr isEqualToString:[searchString capitalizedString]])
				break;
			else if (searchRes = [subStr isEqualToString:[searchString lowercaseString]])
				break;
			else if (searchRes = [subStr isEqualToString:[searchString uppercaseString]])
				break;				
		}
		if(searchRes)
			break;
	}
	
	if(searchRes && dismiss!=YES){
		[textView resignFirstResponder];
        UIAlertView *linkAlert = [[UIAlertView alloc] initWithTitle:@"Link Creation" message:@"Do you want to create link?" delegate:self cancelButtonTitle:@"Create Link" otherButtonTitles:@"Dismiss", nil];                                                
        [linkAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
        [linkAlert show];
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:YES];
        [linkAlert release];
    }
	
}
- (void)textViewDidEndEditing:(UITextView *)aTextView
{	
	if((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)||(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight))
	{
		CGRect frame = textView.frame;
		frame.size.height+=60;
		textView.frame=frame;
	}
	
	isEditing=NO;
	dismiss=NO;
	if( isTextViewEditing ){
		
		isTextViewEditing = NO;
		
		[self bringTextViewDown];
		if (postDetailViewController.hasChanges == YES){
			[leftView setTitle:@"Cancel"];
        }else{
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

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	self.currentEditingTextField = nil;
	if( textField == titleTextField )
		[[BlogDataManager sharedDataManager].currentPost setValue:textField.text forKey:@"title"];
	else if( textField == tagsTextField )
		[[BlogDataManager sharedDataManager].currentPost setValue:tagsTextField.text forKey:@"mt_keywords"];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	postDetailViewController.hasChanges = YES;
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	postDetailViewController.hasChanges = YES;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	self.currentEditingTextField = nil;
	[textField resignFirstResponder];
	return YES;
}


- (IBAction)showPhotoUploadScreen:(id)sender;
{
	[self showPhotoPickerActionSheet];
}

- (WPImagePickerController*)pickerController
{
	if( pickerController == nil ) {
		pickerController = [[WPImagePickerController alloc] init];
		pickerController.delegate = self;
		pickerController.allowsImageEditing = NO;
	}
	return pickerController;
}

- (void)showPhotoPickerActionSheet
{
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
			WPImagePickerController* picker = [self pickerController];
			[[picker parentViewController] dismissModalViewControllerAnimated:YES];
			[self clearPickerContrller];
		}
		else 
		{
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
		WPImagePickerController* picker = [self pickerController];
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		
		// Picker is displayed asynchronously.
		[[postDetailViewController navigationController] presentModalViewController:picker animated:YES];
	}
}

- (void)pickPhotoFromPhotoLibrary:(id)sender {
	[[BlogDataManager sharedDataManager] makeNewPictureCurrent];
	if ([WPImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		WPImagePickerController* picker = [self pickerController];
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
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];

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
- (void)readBookmarksFile{
	bookMarksArray=[[NSMutableArray alloc]init];
	//NSDictionary *bookMarksDict=[NSMutableDictionary dictionaryWithContentsOfFile:@"/Users/sridharrao/Library/Safari/Bookmarks.plist"];
	NSDictionary *bookMarksDict=[NSMutableDictionary dictionaryWithContentsOfFile:@"/Users/sridharrao/Library/Application%20Support/iPhone%20Simulator/User/Library/Safari/Bookmarks.plist"];
	NSArray *childrenArray=[bookMarksDict valueForKey:@"Children"];
	bookMarksDict=[childrenArray objectAtIndex:0];
	int count=[childrenArray count];
	childrenArray=[bookMarksDict valueForKey:@"Children"];
	for(int i=0;i<count;i++)
	{
		bookMarksDict=[childrenArray objectAtIndex:i];
		if([[bookMarksDict valueForKey:@"WebBookmarkType"] isEqualToString:@"WebBookmarkTypeLeaf"]){
			NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
			[dict setValue:[[bookMarksDict valueForKey:@"URIDictionary"] valueForKey:@"title"] forKey:@"title"];
			[dict setValue:[bookMarksDict valueForKey:@"URLString"] forKey:@"url"];
			[bookMarksArray addObject:dict];
			[dict release];
		}
		
	}
}
- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc 
{	
    [infoText release];
    [urlField release];
    [leftView release];
	[bookMarksArray release];
    [segmentedTableViewController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WPNewCategoryCreatedAndUpdatedInBlogNotificationName object:nil];
	[super dealloc];
}


@end

