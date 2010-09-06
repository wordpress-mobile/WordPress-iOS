//
//  EditPageViewController.m
//  WordPress
//
//  Created by Chris Boyd on 9/4/10.
//

#import "EditPageViewController.h"
#import "PageViewController.h"
#define kUITextViewCellRowHeight 277.0

@implementation EditPageViewController

@synthesize table, dm, appDelegate, statuses, actionSheet, isShowingKeyboard, pageDetailView, delegate;
@synthesize contentTextView, selectedSection, titleTextField, isLocalDraft, originalTitle, originalStatus, originalContent;
@synthesize page, connection, urlRequest, urlResponse, payload, spinner;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Init from XIB
    }
	
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
		
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	pageDetailView = (PageViewController *)self.tabBarController.parentViewController;
	dm = [BlogDataManager sharedDataManager];
	statuses = [[NSMutableArray alloc] init];
	
	[self setupPage];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:@"EditPageViewShouldHideKeyboard" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"EditPageViewShouldSave" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publish) name:@"EditPageViewShouldPublish" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:@"EditPageViewShouldCancel" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisppear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int result = 0;
	
	switch (section) {
		case 0:
			result = 2;
			break;
		case 1:
			result = 1;
			break;
		default:
			break;
	}
	
	return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int result = 45;
	
	switch (indexPath.section) {
		case 0:
			result = 45;
			break;
		case 1:
			result = kUITextViewCellRowHeight;
			break;
		default:
			break;
	}
	
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = 0;
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
	
	UITextViewCell *contentCell = (UITextViewCell *) [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
	if (contentCell == nil) {
        contentCell = [UITextViewCell createNewTextCellFromNib];
    }
    
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.font = [UIFont systemFontOfSize:16.0];
					cell.textLabel.text = @"Title";
					cell.textLabel.textColor = [UIColor grayColor];
					
					CGRect textFrame;
					UIColor *backgroundColor;
					if(DeviceIsPad()){
						textFrame = CGRectMake(50, 14, 350, 42);
						backgroundColor = [UIColor clearColor];
					}
					else {
						textFrame = CGRectMake(50, 12, 185, 30);
						backgroundColor = [UIColor whiteColor];
					}
					
					
					UITextField *cellTextField = [[UITextField alloc] initWithFrame:textFrame];
					cellTextField.font = [UIFont systemFontOfSize:15.0];
					cellTextField.adjustsFontSizeToFitWidth = NO;
					cellTextField.textColor = [UIColor blackColor];
					cellTextField.backgroundColor = backgroundColor;
					cellTextField.placeholder = @"Page Title";
					cellTextField.tag = 1;
					cellTextField.delegate = self;
					if(page.postTitle != nil)
						cellTextField.text = page.postTitle;
					cellTextField.autocorrectionType = UITextAutocorrectionTypeNo;
					cellTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
					cellTextField.textAlignment = UITextAlignmentLeft;
					cellTextField.delegate = self;
					
					cellTextField.clearButtonMode = UITextFieldViewModeNever;
					[cellTextField setEnabled:YES];
					
					[cell addSubview:cellTextField];
					titleTextField = cellTextField;			
					break;
				case 1:
					cell.textLabel.font = [UIFont systemFontOfSize:16.0];
					cell.textLabel.textColor = [UIColor grayColor];
					cell.textLabel.text = @"Status";
					
					cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
					if(page.status != nil)
						cell.detailTextLabel.text = page.status;
					cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
					break;
				default:
					break;
			}
			
			break;
		case 1:
			row = 0;
			UIColor *backgroundColor;
			if(DeviceIsPad()){
				backgroundColor = [UIColor clearColor];
			}
			else {
				backgroundColor = [UIColor whiteColor];
			}
			
			contentCell.textView.backgroundColor = backgroundColor;
			contentCell.textView.tag = 2;
			contentCell.textView.delegate = self;
			
			if(page.content != nil)
				contentCell.textView.text = page.content;
			cell = contentCell;
			contentTextView = [contentCell.textView retain];
			break;
		default:
			break;
	}
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	selectedSection = [NSNumber numberWithInt:indexPath.section];
	
	switch ([selectedSection intValue]) {
		case 0:
			switch (indexPath.row) {
				case 0:
					// Nothing
					break;
				case 1:
					[self refreshStatuses];
					[self showStatusPicker:self];
				default:
					break;
			}
			[contentTextView resignFirstResponder];
			break;
		case 1:
			[titleTextField resignFirstResponder];
			[contentTextView becomeFirstResponder];
			break;
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
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
	[self.page setStatus:[statuses objectAtIndex:row]];
	[self hideStatusPicker:self];
	[self refreshButtons];
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self refreshPage];
	[self refreshTable];
	return YES;	
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	selectedSection = [NSNumber numberWithInt:0];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	selectedSection = nil;
	[textField resignFirstResponder];
	[self refreshPage];
	[self refreshTable];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	selectedSection = [NSNumber numberWithInt:1];
	self.view.frame = CGRectMake(0, 0, 320, 199);
	
	CGRect sectionRect = [self.table rectForSection:1];
	sectionRect.size.height = self.table.frame.size.height;
	[self.table scrollRectToVisible:sectionRect animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	selectedSection = nil;
	self.view.frame = CGRectMake(0, 0, 320, 365);
	
	UITableViewCell *cell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	for(UIView *subview in cell.contentView.subviews) {
		if([subview isKindOfClass:[UITextView class]]) {
			contentTextView = [(UITextView *)subview retain];
			break;
		}
	}
	
	if(contentTextView != nil) {
		contentTextView.frame = CGRectMake(0, 90, 320, contentTextView.contentSize.height);
	}
	
	CGRect sectionRect = [self.table rectForSection:0];
	sectionRect.size.height = self.table.frame.size.height;
	[self.table scrollRectToVisible:sectionRect animated:YES];
	if(textView.text != nil) {
		[self.page setContent:[NSString stringWithFormat:@"%@", textView.text]];
	}
	
	[textView resignFirstResponder];
	[self refreshPage];
	[self refreshTable];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return TRUE;
}

#pragma mark -
#pragma mark Custom methods

- (void)setupPage {
	if(self.page == nil) {
		if(delegate.selectedPostID != nil) {
			self.page = [[delegate.draftManager get:delegate.selectedPostID] retain];
			if(self.page.uniqueID == delegate.selectedPostID) {
				// Load from Core Data
				
				// Change this line when we rid ourselves of BlogDataManager
				self.isLocalDraft = YES;
			}
			else {
				// Load from PageManager
				NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
				[nf setNumberStyle:NSNumberFormatterDecimalStyle];
				NSDictionary *existingPage = [delegate.pageManager getPage:[nf numberFromString:delegate.selectedPostID]];
				[nf release];
				
				self.page.postTitle = [existingPage objectForKey:@"title"];
				self.page.status = [dm pageStatusDescriptionForStatus:[existingPage objectForKey:@"page_status"] fromBlog:dm.currentBlog];
				self.page.content = [existingPage objectForKey:@"description"];
			}
		}
		else {
			// New page
			self.isLocalDraft = YES;
			[self setPage:[[delegate.draftManager get:nil] retain]];
			[self.page setStatus:@"Local Draft"];
			[self.page setIsPublished:[NSNumber numberWithInt:0]];
			[self.page setIsLocalDraft:[NSNumber numberWithInt:1]];
			[self.page setPostType:@"page"];
			[self.page setBlogID:[dm.currentBlog objectForKey:@"blogid"]];
			[self.page setDateCreated:[NSDate date]];
		}
		[self setOriginalTitle:self.page.postTitle];
		[self setOriginalStatus:self.page.status];
		[self setOriginalContent:self.page.content];
	}
	
	[self refreshStatuses];
	[self refreshButtons];
}

- (void)refreshTable {
	[self.table reloadData];
	[self refreshButtons];
}

- (void)refreshButtons {
	[delegate refreshButtons:[self hasChanges] keyboard:self.isShowingKeyboard];
}

- (void)refreshStatuses {
    NSDictionary *postStatusList = [[dm currentBlog] valueForKey:@"postStatusList"];
	for (id key in postStatusList) {
		if(![statuses containsObject:[postStatusList objectForKey:key]]) {
			[statuses addObject:[[postStatusList objectForKey:key] retain]];
		}
	}
	
	if((self.isLocalDraft == YES) && (![statuses containsObject:@"Local Draft"]))
		[statuses addObject:@"Local Draft"];
}

- (void)refreshPage {
	[self.page setPostTitle:titleTextField.text];
	[self.page setContent:contentTextView.text];
}

- (IBAction)showStatusPicker:(id)sender {
	actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	[actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	
	CGRect pickerFrame = CGRectMake(0, 40, 0, 0);
	UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
	pickerView.showsSelectionIndicator = YES;
	pickerView.delegate = self;
	pickerView.dataSource = self;
    [pickerView selectRow:[self indexForStatus:page.status] inComponent:0 animated:YES];
	[actionSheet addSubview:pickerView];
	[pickerView release];
	
	UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Cancel"]];
	closeButton.momentary = YES; 
	closeButton.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
	closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
	closeButton.tintColor = [UIColor blackColor];
	[closeButton addTarget:self action:@selector(hideStatusPicker:) forControlEvents:UIControlEventValueChanged];
	[actionSheet addSubview:closeButton];
	[closeButton release];
	
	[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
}

- (IBAction)hideStatusPicker:(id)sender {
	[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	[self refreshTable];
}

- (NSInteger)indexForStatus:(NSString *)status {
	NSInteger result = -1;
	
	int index = 0;
	for(NSString *item in statuses) {
		if([[item lowercaseString] isEqualToString:[status lowercaseString]]) {
			result = index;
			break;
		}
		index++;
	}
	
	return result;
}

- (void)hideKeyboard:(NSNotification *)notification {
	UITableViewCell *cell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	for(UIView *subview in cell.contentView.subviews) {
		if([subview isKindOfClass:[UITextView class]]) {
			contentTextView = [(UITextView *)subview retain];
			break;
		}
	}
	
	if(contentTextView != nil) {
		[contentTextView resignFirstResponder];
	}
	[titleTextField resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	self.isShowingKeyboard = YES;
	[self refreshButtons];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	self.isShowingKeyboard = NO;
	[self refreshButtons];
}

- (void)publish {
	[titleTextField resignFirstResponder];
	[contentTextView resignFirstResponder];
	
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Publishing..."];
	[spinner show];
	
	self.isLocalDraft = NO;
	self.page.status = @"publish";
	[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
}

- (void)save {
	[titleTextField resignFirstResponder];
	[contentTextView resignFirstResponder];
	
	if(![[self.page.status lowercaseString] isEqualToString:@"local draft"])
		self.isLocalDraft = NO;
	
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	[spinner show];
	[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
}

- (void)saveInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self.page setPostType:@"page"];
	
	if(self.isLocalDraft == YES) {
		[delegate.draftManager save:self.page];
		[self performSelectorOnMainThread:@selector(didSavePageInBackground) withObject:nil waitUntilDone:NO];
	}
	else {
//		if(delegate.selectedBDMIndex > -1)
//			[dm makePageAtIndexCurrent:delegate.selectedBDMIndex];
//		else
//			[dm makeNewPageCurrent];
//		
//		[dm.currentPage setObject:self.page.postTitle forKey:@"title"];
//		[dm.currentPage setObject:self.page.status forKey:@"post_status"];
//		[dm.currentPage setObject:self.page.status forKey:@"page_status"];
//		[dm.currentPage setObject:self.page.content forKey:@"description"];
//		
//		BOOL result = [dm savePage:dm.currentPage];
//		if(result == YES) {
//			[self.page setPostID:[NSString stringWithFormat:@"%@", [dm.currentPage objectForKey:@"pageid"]]];
//			[self performSelectorOnMainThread:@selector(verifyPublishSuccessful) withObject:nil waitUntilDone:NO];
//		}
	}
	
	[pool release];
}

- (void)didSavePageInBackground {
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[delegate dismiss:self];
}

- (void)cancel {
	[appDelegate.managedObjectContext rollback];
	[delegate dismiss:self];
}

- (BOOL)hasChanges {
	BOOL result = NO;
	
	if((page.postTitle != nil) && (![page.postTitle isEqualToString:originalTitle]))
		result = YES;
	if((page.status != nil) && (![page.status isEqualToString:originalStatus]))
		result = YES;
	if((page.content != nil) && (![page.content isEqualToString:originalContent]))
		result = YES;
	
	return result;
}

- (void)verifyPublishSuccessful {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSArray *params = [NSArray arrayWithObjects:
					   [dm.currentBlog valueForKey:@"blogid"],
					   self.page.postID,
					   [[dm currentBlog] objectForKey:@"username"],
					   [dm getPasswordFromKeychainInContextOfCurrentBlog:dm.currentBlog],
					   nil];
	
	// Execute the XML-RPC request
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:[dm.currentBlog valueForKey:@"xmlrpc"]]];
	[request setMethod:@"wp.getPage" withObjects:params];
	[params release];
	
	connection = [[NSURLConnection alloc] initWithRequest:[request request] delegate:self];
	if (connection) {
		payload = [[NSMutableData data] retain];
	}
}

- (void)stop {
	[connection cancel];
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {	
	[self.payload setLength:0];
	[self setUrlResponse:response];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
	[self.payload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	conn = nil;
	
	if(payload != nil)
	{
		NSString  *str = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
		if ( ! str ) {
			str = [[NSString alloc] initWithData:payload encoding:[NSString defaultCStringEncoding]];
			payload = (NSMutableData *)[[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] retain];
		}
		
		if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			if ([(NSHTTPURLResponse *)urlResponse statusCode] < 400) {
				XMLRPCResponse *xmlrpcResponse = [[XMLRPCResponse alloc] initWithData:payload];
				
				if (![xmlrpcResponse isKindOfClass:[NSError class]]) {
					NSDictionary *responseMeta = [xmlrpcResponse object];
					NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
					[f setNumberStyle:NSNumberFormatterDecimalStyle];
					NSNumber *publishedPageID = [f numberFromString:self.page.postID];
					NSNumber *newPageID = [responseMeta valueForKey:@"page_id"];
					[f release];
					if([publishedPageID isEqualToNumber:newPageID]) {
						// Publish was successful
						NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.page.uniqueID, @"uniqueID", nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalDraftWasPublishedSuccessfully" object:nil userInfo:info];
						[self didSavePageInBackground];
					}
				}
				
				[xmlrpcResponse release];
			}
			
		}
		
		[str release];
	}
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[spinner release];
	[connection release];
	[urlRequest release];
	[urlResponse release];
	[payload release];
	[page release];
	[titleTextField release];
	[selectedSection release];
	[contentTextView release];
	[actionSheet release];
	[statuses release];
	[table release];
    [super dealloc];
}

@end

