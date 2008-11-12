//
//  PageDetailViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import "PageDetailViewController.h"
#import "WPSelectionTableViewController.h"
#import "BlogDataManager.h"
#import "WPNavigationLeftButtonView.h"
#import "PageDetailsController.h"
#import "WPPhotosListViewController.h"
#import "WordPressAppDelegate.h"


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
@synthesize infoText,urlField,selectedLinkRange;
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
	NSString *statusValue=[dm pageStatusDescriptionForStatus:status fromBlog:dm.currentBlog];
	statusValue = ( statusValue == nil ? @"" : statusValue );
	statusTextField.text = statusValue;

	
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
	
	[photosListController refreshData];
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
	WPLog(@"Page textViewDidChangeSelection");
	pageDetailsController.hasChanges = YES;
	hasChanges = YES;
	if (!isTextViewEditing) 		
		isTextViewEditing = YES;
				
	[self updateTextViewPlacehoderFieldStatus];
	
	WPLog(@"Page textViewDidChangeSelection : ");   
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone 
																  target:self action:@selector(endTextEnteringButtonAction:)];
	
	pageDetailsController.navigationItem.leftBarButtonItem = doneButton;
	[doneButton release];
	
}

- (void)textViewDidBeginEditing:(UITextView *)aTextView
{	
	dismiss=NO;

	if (!isTextViewEditing) 
		isTextViewEditing = YES;
		
	[self updateTextViewPlacehoderFieldStatus];
	WPLog(@"PAGE textViewDidBeginEditing : ");   
	
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
	WPLog(@"Link Creation Alert ");
		WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		[delegate setAlertRunning:TRUE];
		[textView resignFirstResponder];
        UIAlertView *linkAlert = [[UIAlertView alloc] initWithTitle:@"Link Creation" message:@"Do you want to create link?" delegate:self cancelButtonTitle:@"Create Link" otherButtonTitles:@"Dismiss", nil];                                                
        [linkAlert setTag:1];  // for UIAlertView Delegate to handle which view is popped.
        [linkAlert show];
        [linkAlert release];
    }
	
	
	
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
	dismiss=NO;
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
	
	//	WPLog(@" %@ completedSelectionsWithContext %u isChanged %d selectedObjects %@", [self className], selContext, isChanged, selectedObjects);
	if( !isChanged ){
		[selctionController clean];
		return;
	}
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	if( selContext == kSelectionsStatusContext1 ){
		NSString *curStatus = [selectedObjects lastObject];
		NSString *status = [dm pageStatusForStatusDescription:curStatus fromBlog:dm.currentBlog];
		if( status ){
			[[dm currentPage] setObject:status forKey:@"page_status"];
			statusTextField.text = curStatus ;
		}	
	}
	
	[selctionController clean];
	pageDetailsController.hasChanges = YES;
	
}	

- (void)populateSelectionsControllerWithStatuses
{
	if (selectionTableViewController == nil)
		selectionTableViewController = [[WPSelectionTableViewController alloc] initWithNibName:@"WPSelectionTableViewController" bundle:nil];
	
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"pageStatusList"];
    NSArray *dataSource = [postStatusList allValues] ;
	if(dm.currentPageIndex == -1 || dm.isLocaDraftsCurrent)
		dataSource = [dataSource arrayByAddingObject:@"Local Draft"];
	
	NSString *curStatus = [dm.currentPage valueForKey:@"page_status"];

	NSString *statusValue=[dm statusDescriptionForStatus:curStatus  fromBlog:dm.currentBlog];
	
	NSArray *selObject = ( statusValue == nil ? [NSArray array] : [NSArray arrayWithObject:statusValue] );

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
				return;
			if((infoText.text == nil)||([infoText.text isEqualToString:@""]))
				infoText.text=urlField.text;
			
			NSString *commentsStr = textView.text;
			NSRange rangeToReplace=[self selectedLinkRange];
			//WPLog(@" Entered Text %@ and The Link %@ selected text is %@ ******* %d,%d",infoText.text,urlField.text,[commentsStr substringWithRange:rangeToReplace],rangeToReplace.location,rangeToReplace.length);
			NSString *urlString=[self validateNewLinkInfo:urlField.text];
			NSString *aTagText=[NSString stringWithFormat:@"<a href=\"%@\">%@</a>",urlString,infoText.text];;
			textView.text = [commentsStr stringByReplacingOccurrencesOfString:[commentsStr substringWithRange:rangeToReplace] withString:aTagText options:NSCaseInsensitiveSearch range:rangeToReplace];
		
			BlogDataManager *dm = [BlogDataManager sharedDataManager];
			NSString *str = textView.text;
			str = ( str	!= nil ? str : @"" );
			[dm.currentPage setValue:str forKey:@"description"];
			
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

//code to Show the link view
//when create link button of the create hyperlink alert is clicked. 

-(void)showLinkView
{
    WPLog(@"   Show the Link  View . ");
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
@end

