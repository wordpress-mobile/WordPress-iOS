#import "PageDetailViewController.h"
#import "WPSelectionTableViewController.h"
#import "BlogDataManager.h"
#import "WPNavigationLeftButtonView.h"
#import "PageDetailsController.h"
#import "WPPhotosListViewController.h"


@interface PageDetailViewController (private)
- (void)_savePageWithBlog:(NSMutableArray *)arrayPage;
- (void)updateTextViewPlacehoderFieldStatus;
- (void)populateSelectionsControllerWithStatuses;
- (void)bringTextViewUp;
- (void)bringTextViewDown;
@end

#define kSelectionsStatusContext1 ((void*)1000)
NSTimeInterval kAnimationDuration1 = 0.3f;

@implementation PageDetailViewController

@synthesize mode,selectionTableViewController,pageDetailsController,photosListController;
//@synthesize photosListController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)refreshUIForCurrentPage
{
	WPLog(@"PDVC refreshUIForCurrentPage");
	self.navigationItem.rightBarButtonItem = nil;
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	WPLog(@"PDVC refreshUIForCurrentPage-------%@",dm.currentPage);

	NSString *description = [dm.currentPage valueForKey:@"description"];
	
	if (!description || [description length] == 0 ) {
		textViewPlaceHolderField.hidden = NO;
		textView.text = @"";
	} else {
		textViewPlaceHolderField.hidden = YES;
		textView.text = description;
	}
	
	titleTextField.text = [dm.currentPage valueForKey:@"title"];
	
	NSString *status = [dm.currentPage valueForKey:@"page_status"];
	status = ( status == nil ? @"" : status );
	statusTextField.text = status;
	
//	if (photosListController == nil) {
//		photosListController = [[WPPhotosListViewController alloc] initWithNibName:@"WPPhotosListViewController" bundle:nil];
//		WPLog(@"1111111-----PDVC refreshUIForCurrentPage ------tableView------%@",photosListController);
//
//	}

	//WPLog(@"PDVC refreshUIForCurrentPage ------tableView------%@",photosListController.view.subviews);
	photosListController.tabBarItem.badgeValue = nil;	
	
	[photosListController refreshData];
}
- (void)refreshUIForNewPage
{
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSString *description = [dm.currentPage valueForKey:@"description"];
	
	if (!description || [description length] == 0 ) {
		textViewPlaceHolderField.hidden = NO;
		textView.text = @"";
	} else {
		textViewPlaceHolderField.hidden = YES;
		textView.text = description;
	}
	
	titleTextField.text = [dm.currentPage valueForKey:@"title"];
	
	NSString *status = [dm pageStatusDescriptionForStatus:[dm.currentPage valueForKey:@"page_status"] fromBlog:dm.currentBlog];

	status = ( status == nil ? @"" : status );
	statusTextField.text = status ;
	
	photosListController.tabBarItem.badgeValue = nil;	

}

- (void)viewWillAppear:(BOOL)animated {
	WPLog(@"viewWillAppear for PAGE DETAILS ");
	pageDetailsController.hasChanges = NO;
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( mode == 1 )
		[self refreshUIForCurrentPage];
	else if( mode == 0 )
		[self refreshUIForNewPage];
	
	CGRect frame = subView.frame;
	frame.origin.y = 0.0f;
	subView.frame = frame;
	
	frame=textViewContentView.frame;
	frame.origin.y = 81.0f;
	textViewContentView.frame = frame;
	
	NSString *status=[[dm currentPage] valueForKey:@"page_status"];
	statusTextField.text = status ;
	
	[super viewWillAppear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	WPLog(@"viewDidLoad from page details");
	//photosListController.pageDetailViewController = self;

	titleTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	statusTextField.font = [UIFont fontWithName:@"Helvetica" size:15.0f];
	statusLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	titleLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0f];
	
	titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	[contentView bringSubviewToFront:textView];
	
}
- (IBAction)endTextEnteringButtonAction:(id)sender
{
	[textView resignFirstResponder];
	UIBarButtonItem *barButton  = [[UIBarButtonItem alloc] initWithCustomView:pageDetailsController.leftView];
    pageDetailsController.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
}

- (IBAction)cancelView:(id)sender 
{
	if (!pageDetailsController.hasChanges) {
		[pageDetailsController.navigationController popViewControllerAnimated:YES]; 
		return;
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
															 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
													otherButtonTitles:nil];		
	actionSheet.tag = 202;
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	[actionSheet showInView:self.view];
	[actionSheet release];	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ([actionSheet tag])
	{
		case 202:
		{
			if( buttonIndex == 0 ){
				pageDetailsController.hasChanges = NO;
				pageDetailsController.navigationItem.rightBarButtonItem = nil;
				[pageDetailsController.navigationController popViewControllerAnimated:YES];
			}
			
			if( buttonIndex == 1 ){
				pageDetailsController.hasChanges = YES;
			}			
			break;
		}
		default:
			break;
	}
}

- (void)endEditingAction:(id)sender
{
	[titleTextField resignFirstResponder];
	[textView resignFirstResponder];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark TextView & TextField Delegates
- (void)textViewDidChangeSelection:(UITextView *)aTextView {
	WPLog(@"textViewDidChangeSelection");
	pageDetailsController.hasChanges = YES;
	hasChanges = YES;
	if (!isTextViewEditing) 		
		isTextViewEditing = YES;
				
	[self updateTextViewPlacehoderFieldStatus];
	
	WPLog(@"textViewDidChangeSelection : ");   
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone 
																  target:self action:@selector(endTextEnteringButtonAction:)];
	
	pageDetailsController.navigationItem.leftBarButtonItem = doneButton;
	[doneButton release];
	
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView
{	
		if (!isTextViewEditing) 
			isTextViewEditing = YES;
			
		[self updateTextViewPlacehoderFieldStatus];
		WPLog(@"textViewDidBeginEditing : ");   
		
		[self bringTextViewUp];
}
- (void)bringTextViewUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kAnimationDuration1];
	
	CGRect frame = textViewContentView.frame;
	frame.origin.y -= 80.0f;
	textViewContentView.frame = frame;
	
	frame = subView.frame;
	frame.origin.y -= 80.0f;
	subView.frame = frame;
	
	[UIView commitAnimations];
	[self.view setNeedsDisplay];	
}

- (void)textViewDidChange:(UITextView *)aTextView {
	WPLog(@"textViewDidChange");
	[self updateTextViewPlacehoderFieldStatus];
	if(![aTextView hasText])
		return;
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
- (void)textViewDidEndEditing:(UITextView *)aTextView
{	
	if( isTextViewEditing )
		isTextViewEditing = NO;
		[self bringTextViewDown];
		NSString *text = aTextView.text;
		[[[BlogDataManager sharedDataManager] currentPage] setObject:text forKey:@"description"];		
}

- (void)bringTextViewDown
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
	subView.hidden = NO;
	
	CGRect frame = textViewContentView.frame;
	frame.origin.y = 81.0f;
	textViewContentView.frame = frame;	
	
	frame = subView.frame;
	frame.origin.y = 0.0f;
	subView.frame = frame;
	
	[UIView commitAnimations];		
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self textViewDidEndEditing:textView];
	//pageDetailsController.hasChanges = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if( textField == titleTextField )
		[[BlogDataManager sharedDataManager].currentPage setValue:textField.text forKey:@"title"];

	CGRect frame = subView.frame;
	frame.origin.y = 0.0f;
	subView.frame = frame;
	
	frame=textViewContentView.frame;
	frame.origin.y = 81.0f;
	textViewContentView.frame = frame;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string 
{
	pageDetailsController.hasChanges = YES;
	hasChanges = YES;
	return YES;
}

- (IBAction)showStatusViewAction:(id)sender
{
	[self populateSelectionsControllerWithStatuses];
}

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged
{
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( selContext == kSelectionsStatusContext1 ){
		NSString *curStatus = [selectedObjects lastObject];
		WPLog(@"-----curStatus-----%@",curStatus);
		NSString *status = curStatus;
		if( status ){
			WPLog(@"-----status-----%@",status);

			[[dm currentPage] setObject:status forKey:@"page_status"];
			statusTextField.text = curStatus ;
		}	
	}
}	

- (void)populateSelectionsControllerWithStatuses
{
	if (selectionTableViewController == nil)
		selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"pageStatusList"];
    NSArray *dataSource = [postStatusList allValues] ;
    
	if(dm.currentPageIndex == -1 )
		dataSource = [dataSource arrayByAddingObject:@"Local Draft"];
	
	NSString *curStatus = [dm.currentPage valueForKey:@"page_status"];

	NSArray *selObject = ( curStatus == nil ? [NSArray array] : [NSArray arrayWithObject:curStatus] );
	
	[selectionTableViewController populateDataSource:dataSource
									   havingContext:kSelectionsStatusContext1
									 selectedObjects:selObject
									   selectionType:kRadio
										 andDelegate:self];
	
	selectionTableViewController.title = @"Status";
	selectionTableViewController.navigationItem.rightBarButtonItem = nil;
	[pageDetailsController.navigationController pushViewController:selectionTableViewController animated:YES];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	pageDetailsController.hasChanges = YES;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	pageDetailsController.hasChanges = YES;
	return YES;
}
- (void)viewWillDisappear:(BOOL)animated
{
	WPLog(@"PageDVC viewWillDisappear");
	[super viewWillDisappear:animated];
	pageDetailsController.hasChanges = NO;
	[titleTextField resignFirstResponder];
	[textView resignFirstResponder];
	 mode = 3;
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)dealloc 
{
	[pageDetailsController release];
	[selectionTableViewController release];
	[super dealloc];
}

@end

