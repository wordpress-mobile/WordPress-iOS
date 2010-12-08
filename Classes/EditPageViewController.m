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

@synthesize table, dm, appDelegate, actionSheet, isShowingKeyboard, pageDetailView, delegate, statuses, pickerViewController;
@synthesize contentTextView, selectedSection, titleTextField, isLocalDraft, originalTitle, originalStatus, originalContent;
@synthesize page, connection, urlRequest, urlResponse, payload, spinner, resignTextFieldButton, statusPopover, normalTableFrame;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
		
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	pageDetailView = (PageViewController *)self.tabBarController.parentViewController;
	dm = [BlogDataManager sharedDataManager];
	statuses = [[NSMutableDictionary alloc] init];
	
	if((delegate.pageManager.statuses == nil) || (delegate.pageManager.statuses.count == 0)) {
		[statuses setObject:@"Local Draft" forKey:[NSString stringWithString:kLocalDraftKey]];
		[delegate.pageManager syncStatuses];
	}
	else {
		statuses = [delegate.pageManager.statuses mutableCopy];
	}
	
	[self setupPage];
	
	if(DeviceIsPad() == YES) {
		[resignTextFieldButton removeFromSuperview];
		normalTableFrame = CGRectMake(0, 0, 320, 367);
	}
	else {
		normalTableFrame = CGRectMake(0, 0, 768, 900);
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignTextField:) name:UITextViewTextDidBeginEditingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:@"EditPageViewShouldHideKeyboard" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:@"EditPageViewShouldSave" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publish) name:@"EditPageViewShouldPublish" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:@"EditPageViewShouldCancel" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillDisppear:) name:@"EditPageViewShouldDisappear" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaAbove:) name:@"ShouldInsertMediaAbove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insertMediaBelow:) name:@"ShouldInsertMediaBelow" object:nil];
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
			if(DeviceIsPad() == YES)
				result = self.view.frame.size.height - 90;
			else
				result = kUITextViewCellRowHeight;
			break;
		default:
			break;
	}
	
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
					textCell.textField.placeholder = @"Page Title";
					textCell.textField.tag = 1;
					textCell.textField.delegate = self;
					if(page.postTitle != nil)
						textCell.textField.text = page.postTitle;
					titleTextField = [textCell.textField retain];
					
					if(DeviceIsPad() == YES)
						titleTextField.frame = CGRectMake(80, 5, self.view.frame.size.width - 50, titleTextField.frame.size.height);
					
					cell = textCell;
					break;
				case 1:
					cell.textLabel.font = [UIFont systemFontOfSize:16.0];
					cell.textLabel.textColor = [UIColor grayColor];
					cell.textLabel.text = @"Status";
					
					cell.detailTextLabel.font = [UIFont systemFontOfSize:16.0];
					if(self.page.status != nil)
						cell.detailTextLabel.text = [statuses objectForKey:self.page.status];
					cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
					break;
				default:
					break;
			}
			
			break;
		case 1:
        {
			UIColor *backgroundColor;
			if(DeviceIsPad()){
				backgroundColor = [UIColor clearColor];
			}
			else {
				backgroundColor = [UIColor whiteColor];
			}
			
			// Uncomment the following line for debugging UITextView position
			// backgroundColor = [UIColor blueColor];
			
			contentCell.textView.backgroundColor = backgroundColor;
			contentCell.textView.tag = 2;
			contentCell.textView.delegate = self;
			
			if(DeviceIsPad() == YES)
				contentCell.textView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 90);
			
			if(page.content != nil)
				contentCell.textView.text = page.content;
			cell = contentCell;
			contentTextView = [contentCell.textView retain];
			break;
        }
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
					if(DeviceIsPad() == YES)
						[self showStatusPopover:self];
					else
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
	return statuses.count;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [[statuses allValues] objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	[self.page setStatus:[[statuses allKeys] objectAtIndex:row]];
	
	if(DeviceIsPad() == YES)
		[statusPopover dismissPopoverAnimated:YES];
	else
		[self hideStatusPicker:self];
	
	[self refreshTable];
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
	[self.view bringSubviewToFront:resignTextFieldButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	selectedSection = nil;
	[textField resignFirstResponder];
	[self refreshPage];
	[self refreshTable];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	selectedSection = [NSNumber numberWithInt:1];
	
    UITableViewCell *cell = (UITableViewCell*) [[textView superview] superview];
    [table scrollToRowAtIndexPath:[table indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	[self checkPublishable];
	[self preserveUnsavedPage];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	selectedSection = nil;
	
	UITableViewCell *cell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	for(UIView *subview in cell.contentView.subviews) {
		if([subview isKindOfClass:[UITextView class]]) {
			contentTextView = [(UITextView *)subview retain];
			break;
		}
	}
	
	[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	if(textView.text != nil) {
		[self.page setContent:[NSString stringWithFormat:@"%@", textView.text]];
	}
	
	[textView resignFirstResponder];
	[self preserveUnsavedPage];
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
				[self.page setIsPublished:[NSNumber numberWithInt:1]];
				delegate.isPublished = YES;
				
				[statuses removeObjectForKey:kLocalDraftKey];
			}
		}
		else {
			// New page
			self.isLocalDraft = YES;
			[self setPage:[[delegate.draftManager get:nil] retain]];
			[self.page setIsPublished:[NSNumber numberWithInt:0]];
			delegate.isPublished = NO;
			[self.page setIsLocalDraft:[NSNumber numberWithInt:1]];
			[self.page setPostType:@"page"];
			[self.page setBlogID:[dm.currentBlog objectForKey:@"blogid"]];
			[self.page setDateCreated:[NSDate date]];
			[self.page setStatus:@"local-draft"];
			
			[self restoreUnsavedPage];
		}
		[self setOriginalTitle:self.page.postTitle];
		[self setOriginalStatus:self.page.status];
		[self setOriginalContent:self.page.content];
	}
	
	[self refreshTable];
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
	[self preserveUnsavedPage];
}

- (IBAction)showStatusPopover:(id)sender {
	CGRect pickerFrame = CGRectMake(0, 0, 300, 200);
	UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
	pickerView.showsSelectionIndicator = YES;
	pickerView.delegate = self;
	pickerView.dataSource = self;
    [pickerView selectRow:[self indexForStatus:page.status] inComponent:0 animated:YES];
	pickerViewController = [[UIViewController alloc] init];
	pickerViewController.view.frame = pickerFrame;
	[pickerViewController.view addSubview:pickerView];
    [pickerView release];
	
	statusPopover = [[UIPopoverController alloc] initWithContentViewController:pickerViewController];
	[statusPopover setPopoverContentSize:CGSizeMake(300.0, 200.0)];
	[statusPopover presentPopoverFromRect:CGRectMake(self.view.frame.size.width-210, 30, 50, 50) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	
	[self checkPublishable];
	[self preserveUnsavedPage];
}

- (IBAction)hideStatusPicker:(id)sender {
	[actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	[self refreshTable];
	[self preserveUnsavedPage];
	[self checkPublishable];
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
	if(page != nil)
		[self checkPublishable];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	NSDictionary *keyboardInfo = (NSDictionary *)[notification userInfo];
	self.isShowingKeyboard = YES;
	
	if(DeviceIsPad() == NO) {
		CGRect keyboardBounds;
		[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue: &keyboardBounds];
		float keyboardHeight = keyboardBounds.size.height;
		
		CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
		UIViewAnimationCurve curve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue];
		
		[UIView beginAnimations:nil context:nil]; 
		[UIView setAnimationCurve:curve]; 
		[UIView setAnimationDuration:animationDuration]; 
        [UIView setAnimationBeginsFromCurrentState:YES];
		
        CGRect frame = self.view.frame;
        frame.size.height -= keyboardHeight;
        self.view.frame = frame;
		
		[UIView commitAnimations];
	}
	
	[self checkPublishable];
	[self preserveUnsavedPage];
	[self.view bringSubviewToFront:resignTextFieldButton];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	NSDictionary *keyboardInfo = (NSDictionary *)[notification userInfo];
	self.isShowingKeyboard = NO;
	if((contentTextView != nil) && (DeviceIsPad() == NO)) {
		CGRect keyboardBounds;
		[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue: &keyboardBounds];
		float keyboardHeight = keyboardBounds.size.height;
		
		CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
		UIViewAnimationCurve curve = [[keyboardInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] floatValue];
		
		[UIView beginAnimations:nil context:nil]; 
		[UIView setAnimationCurve:curve]; 
		[UIView setAnimationDuration:animationDuration]; 
        [UIView setAnimationBeginsFromCurrentState:YES];
		
        CGRect frame = self.view.frame;
        frame.size.height += keyboardHeight;
        self.view.frame = frame;
		
		[UIView commitAnimations];
	}
	[self checkPublishable];
	[self preserveUnsavedPage];
}

- (void)publish {
	[titleTextField resignFirstResponder];
	[contentTextView resignFirstResponder];
	
	self.page.status = @"publish";
	if(self.isLocalDraft == YES) {
		self.isLocalDraft = NO;
		
		// If the page started out as a Local Draft, remove the selectedPostID field so it will move forward as a Create.
		if([originalStatus isEqualToString:@"local-draft"] == YES)
			delegate.selectedPostID = nil;
	}
	
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Publishing..."];
	[spinner show];
	[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
}

- (void)save {
	[titleTextField resignFirstResponder];
	[contentTextView resignFirstResponder];
	
	if((self.isLocalDraft == YES) && (![[self.page.status lowercaseString] isEqualToString:@"local-draft"])) {
		self.isLocalDraft = NO;
		
		// If the page started out as a Local Draft, remove the selectedPostID field so it will move forward as a Create.
		if([originalStatus isEqualToString:@"local-draft"] == YES)
			delegate.selectedPostID = nil;
	}
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	[spinner show];
	[self performSelectorInBackground:@selector(saveInBackground) withObject:nil];
}

- (void)saveInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	self.page.postTitle = titleTextField.text;
	self.page.content = contentTextView.text;
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
	[self clearUnsavedPage];
	[pool release];
}

- (void)didSavePageInBackground {
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(DeviceIsPad() == YES) {
		
		// Make sure our Pages list refreshes
		if(page.wasLocalDraft)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PagesUpdated" object:nil ];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AsynchronousPostIsPosted" object:nil ];
	}
	
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

- (void)insertMediaAbove:(NSNotification *)notification {
	Media *media = [notification object];
	
	if((contentTextView.text == nil) || ([contentTextView.text isEqualToString:kTextViewPlaceholder]))
		contentTextView.text = @"";

	NSMutableString *content = [[[NSMutableString alloc] initWithString:media.html] autorelease];
	NSRange imgHTML = [contentTextView.text rangeOfString:content];
	if (imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"<br/><br/>%@", contentTextView.text]];
		contentTextView.text = content;
		[delegate refreshButtons:YES keyboard:NO];
	}
}

- (void)insertMediaBelow:(NSNotification *)notification {
	Media *media = [notification object];
	
	if((contentTextView.text == nil) || ([contentTextView.text isEqualToString:kTextViewPlaceholder]))
		contentTextView.text = @"";

	NSMutableString *content = [[[NSMutableString alloc] initWithString:contentTextView.text] autorelease];
	NSRange imgHTML = [content rangeOfString:media.html];
	if (imgHTML.location == NSNotFound) {
		[content appendString:[NSString stringWithFormat:@"<br/><br/>%@", media.html]];
		contentTextView.text = content;
		[delegate refreshButtons:YES keyboard:NO];
	}
}

#pragma mark -
#pragma mark Page recovery

- (void)preserveUnsavedPage {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL hasUnsavedPage = NO;
	
	if((titleTextField.text != nil) && ([titleTextField.text isEqualToString:@""] == NO)) {
		[defaults setObject:titleTextField.text forKey:@"unsavedpage_title"];
		hasUnsavedPage = YES;
	}
	
	if((contentTextView.text != nil) && ([contentTextView.text isEqualToString:@""] == NO) && 
	   ([contentTextView.text isEqualToString:kTextViewPlaceholder] == NO)) {
		[defaults setObject:contentTextView.text forKey:@"unsavedpage_content"];
		hasUnsavedPage = YES;
	}
	
	if(hasUnsavedPage == YES) {
		[defaults setObject:[NSNumber numberWithBool:YES] forKey:@"unsavedpage_ihasone"];
		[defaults synchronize];
	}
}

- (void)clearUnsavedPage {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"unsavedpage_title"];
	[defaults removeObjectForKey:@"unsavedpage_content"];
	[defaults removeObjectForKey:@"unsavedpage_ihasone"];
}

- (void)restoreUnsavedPage {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if([defaults objectForKey:@"unsavedpage_ihasone"] != nil) {
		if ([defaults objectForKey:@"unsavedpage_title"] != nil) {
			self.page.postTitle = [defaults objectForKey:@"unsavedpage_title"];
		}
		
		if ([defaults objectForKey:@"unsavedpage_content"] != nil) {
			self.page.content = [defaults objectForKey:@"unsavedpage_content"];
		}
		[self refreshTable];
		
		NSLog(@"restoring unsaved post:\ntitle:%@\ncontent:%@", 
			  titleTextField.text, contentTextView.text);
	}
	
	[self clearUnsavedPage];
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
	[pickerViewController release];
	[statusPopover release];
	[statuses release];
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

