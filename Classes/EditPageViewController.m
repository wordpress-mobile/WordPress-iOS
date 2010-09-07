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

@synthesize table, dm, appDelegate, actionSheet, isShowingKeyboard, pageDetailView, delegate;
@synthesize contentTextView, selectedSection, titleTextField, isLocalDraft, originalTitle, originalStatus, originalContent;
@synthesize page, connection, urlRequest, urlResponse, payload, spinner, resignTextFieldButton;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
		
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	pageDetailView = (PageViewController *)self.tabBarController.parentViewController;
	dm = [BlogDataManager sharedDataManager];
	[delegate.pageManager syncStatuses];
	
	[self setupPage];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignTextField:) name:UITextViewTextDidBeginEditingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:@"EditPageViewShouldHideKeyboard" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"EditPageViewShouldSave" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publish) name:@"EditPageViewShouldPublish" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:@"EditPageViewShouldCancel" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillDisppear:) name:@"EditPageViewShouldDisappear" object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisppear:(BOOL)animated {
	if((self.isLocalDraft == YES) && ([self hasChanges] == NO))
		[appDelegate.managedObjectContext rollback];
	
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
	
	UITextFieldCell *textCell = (UITextFieldCell *) [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
	if (textCell == nil) {
        textCell = [UITextFieldCell createNewTextCellFromNib];
    }
	
	UITextViewCell *contentCell = (UITextViewCell *) [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
	if (contentCell == nil) {
        contentCell = [UITextViewCell createNewTextCellFromNib];
    }
    
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					textCell.titleLabel.text = @"Title";
					//textCell.titleLabel.textColor = [UIColor grayColor];
					textCell.textField.placeholder = @"Page Title";
					textCell.textField.tag = 1;
					textCell.textField.delegate = self;
					if(page.postTitle != nil)
						textCell.textField.text = page.postTitle;
					titleTextField = [textCell.textField retain];
					cell = textCell;
					break;
				case 1:
					cell.textLabel.font = [UIFont systemFontOfSize:16.0];
					cell.textLabel.textColor = [UIColor grayColor];
					cell.textLabel.text = @"Status";
					
					cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
					if(self.page.status != nil)
						cell.detailTextLabel.text = [delegate.pageManager.statuses objectForKey:self.page.status];
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
	return [delegate.pageManager.statuses count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[delegate.pageManager.statuses allValues] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	[self.page setStatus:[[[delegate.pageManager.statuses allKeys] objectAtIndex:row] retain]];
	[self hideStatusPicker:self];
	[self checkPublishable];
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	//[textField resignFirstResponder];
	return YES;	
	[self refreshPage];
	[self refreshTable];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	selectedSection = [NSNumber numberWithInt:0];
	[self checkPublishable];
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
	[self checkPublishable];
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
	[self refreshPage];
    return TRUE;
}

#pragma mark -
#pragma mark Custom methods

- (void)setupPage {
	if(self.page == nil) {
		if(delegate.pageManager == nil)
			delegate.pageManager = [[PageManager alloc] initWithXMLRPCUrl:[dm.currentBlog objectForKey:@"xmlrpc"]];
		
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
				
				self.page.postID = delegate.selectedPostID;
				self.page.postTitle = [existingPage objectForKey:@"title"];
				[self.page setStatus:[existingPage objectForKey:@"page_status"]];
				self.page.content = [existingPage objectForKey:@"description"];
				
				[delegate.pageManager.statuses removeObjectForKey:kLocalDraftKey];
			}
		}
		else {
			// New page
			self.isLocalDraft = YES;
			[self setPage:[[delegate.draftManager get:nil] retain]];
			[self.page setIsPublished:[NSNumber numberWithInt:0]];
			[self.page setIsLocalDraft:[NSNumber numberWithInt:1]];
			[self.page setPostType:@"page"];
			[self.page setBlogID:[dm.currentBlog objectForKey:@"blogid"]];
			[self.page setDateCreated:[NSDate date]];
			[self.page setStatus:@"local-draft"];
		}
		[self setOriginalTitle:self.page.postTitle];
		[self setOriginalStatus:self.page.status];
		[self setOriginalContent:self.page.content];
	}
	
	[self checkPublishable];
}

- (void)refreshTable {
	[self.table reloadData];
	[self checkPublishable];
}

- (void)refreshButtons {
	[delegate refreshButtons:[self hasChanges] keyboard:self.isShowingKeyboard];
}

- (void)refreshPage {
	[self.page setPostTitle:titleTextField.text];
	[self.page setContent:contentTextView.text];
	[self checkPublishable];
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
	[self checkPublishable];
}

- (IBAction)hideStatusPicker:(id)sender {
	[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	[self refreshTable];
	[self checkPublishable];
}

- (NSInteger)indexForStatus:(NSString *)status {
	NSInteger result = -1;
	
	int index = 0;
	for(NSString *item in delegate.pageManager.statuses) {
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
	[self checkPublishable];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	self.isShowingKeyboard = YES;
	[self checkPublishable];
	[self.view bringSubviewToFront:resignTextFieldButton];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	self.isShowingKeyboard = NO;
	[self checkPublishable];
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
	
	if(![[self.page.status lowercaseString] isEqualToString:@"local-draft"]) {
		self.isLocalDraft = NO;
		
		// If the page started out as a Local Draft, remove the selectedPostID field so it will move forward as a Create.
		if([originalStatus isEqualToString:@"local-draft"] == YES)
			delegate.selectedPostID = nil;
		
		[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
	}
	
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	[spinner show];
}

- (void)saveInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self.page setPostType:@"page"];
	
	if(self.isLocalDraft == YES) {
		[delegate.draftManager save:self.page];
		[self performSelectorOnMainThread:@selector(didSavePageInBackground) withObject:nil waitUntilDone:NO];
	}
	else {
		if(delegate.selectedPostID == nil)
			[delegate.pageManager createPage:self.page];
		else
			[delegate.pageManager savePage:self.page];
		
		[self performSelectorOnMainThread:@selector(didSavePageInBackground) withObject:nil waitUntilDone:NO];
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
	
	if((result == NO) && (self.isLocalDraft)) {
		if(page.postTitle != nil)
			result = YES;
		if(page.status != nil)
			result = YES;
		if(page.content != nil)
			result = YES;
	}
	
	return result;
}

- (void)checkPublishable {
	if((page.postTitle != nil) && (![page.postTitle isEqualToString:@""]) &&
	   (page.status != nil) && (![page.status isEqualToString:@""]) &&
	   (page.content != nil) && (![page.content isEqualToString:@""])) {
		delegate.canPublish = YES;
	}
	[self refreshButtons];
}

- (IBAction)resignTextField:(id)sender {
	[titleTextField resignFirstResponder];
	UITableViewCell *cell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	for(UIView *subview in cell.contentView.subviews) {
		if([subview isKindOfClass:[UITextView class]]) {
			[subview becomeFirstResponder];
			break;
		}
	}
	[self.view sendSubviewToBack:resignTextFieldButton];
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
	[resignTextFieldButton release];
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
	[table release];
    [super dealloc];
}

@end

