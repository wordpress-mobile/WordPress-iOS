//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "EditSiteViewController.h"

@implementation EditSiteViewController
@synthesize spinner, footerText, addButtonText, url, xmlrpc, username, password, isWPcom;
@synthesize isAuthenticating, isAuthenticated, isSaving, hasSubsites, subsites, viewDidMove, keyboardIsVisible;
@synthesize hasValidXMLRPCurl, blogID, blogName, host, activeTextField, blogIndex, tableView;
//@synthesize addUsersBlogsView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	NSMutableDictionary *currentBlog = (NSMutableDictionary *)[[BlogDataManager sharedDataManager] blogAtIndex:blogIndex];
	appDelegate.currentBlog = currentBlog;
	
    NSString *logoName = @"logo_wporg";
	NSRange range = [self.url rangeOfString:@"wordpress.com"];
	if(range.location != NSNotFound)
		isWPcom = YES;
	
	if(isWPcom == YES) {
		self.navigationItem.title = @"Edit Blog";
        logoName = @"logo_wpcom";
	}
	else {
		self.navigationItem.title = @"Edit Site";
	}
	
	hasValidXMLRPCurl = YES;
	addButtonText = @"Save";
	[spinner initWithLabel:@"Saving..."];
	self.tableView.backgroundColor = [UIColor clearColor];
	
	if(DeviceIsPad() == YES) {
		self.tableView.backgroundView = nil;
		
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
											style:UIBarButtonItemStyleBordered 
											target:self action:@selector(cancel:)];
		self.navigationItem.leftBarButtonItem = cancelButton;
		[cancelButton release];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[self loadSiteData];
	
	NSRange range = [self.url rangeOfString:@"wordpress.com"];
	if(range.location != NSNotFound)
		isWPcom = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification
											   object:self.view.window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) 
												 name:UIKeyboardWillHideNotification
											   object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIKeyboardWillHideNotification object:nil];
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return NO;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
			if(hasValidXMLRPCurl)
				return 3;	// URL, username, password
			else
				return 4;	// URL, username, password, XMLRPC url
			break;
		case 1:
			if(hasSubsites)
				return 2;	// Select Subsites
			else
				return 1;	// Settings
			break;
		case 2:
			return 1;		// Add Site
			break;
		default:
			break;
	}
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	static NSString *activityCellIdentifier = @"ActivityCell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:activityCellIdentifier];
    if (cell == nil) {
		UITableViewCellStyle cellStyle;
		if((indexPath.section == 1) && (hasSubsites))
			cellStyle = UITableViewCellStyleValue1;
		else
			cellStyle = UITableViewCellStyleDefault;
		cell = [[[UITableViewCell alloc] initWithStyle:cellStyle
									   reuseIdentifier:@"MyCell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if ([indexPath section] == 0) {
			UITextField *addTextField = [[UITextField alloc] initWithFrame:CGRectMake(140, 10, 185, 30)];
			addTextField.adjustsFontSizeToFitWidth = YES;
			addTextField.textColor = [UIColor blackColor];
			if ([indexPath section] == 0) {
				if (indexPath.row == 0) {
					activeTextField = addTextField;
					addTextField.placeholder = @"http://example.com";
					addTextField.keyboardType = UIKeyboardTypeEmailAddress;
					addTextField.returnKeyType = UIReturnKeyDone;
					if(url != nil)
						addTextField.text = url;
				}
				else if(indexPath.row == 1) {
					addTextField.placeholder = @"WordPress username.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					if(username != nil)
						addTextField.text = username;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"WordPress password.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					if(xmlrpc != nil)
						addTextField.returnKeyType = UIReturnKeyDone;
					else
						addTextField.returnKeyType = UIReturnKeyDone;
					addTextField.secureTextEntry = YES;
					if(password != nil)
						addTextField.text = password;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"http://example.com/xmlrpc.php";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					if(xmlrpc != nil)
						addTextField.text = xmlrpc;
				}
				
				addTextField.tag = indexPath.row;
				addTextField.backgroundColor = [UIColor clearColor];
				addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
				addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				addTextField.textAlignment = UITextAlignmentLeft;
				addTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
				addTextField.delegate = self;
				
				addTextField.clearButtonMode = UITextFieldViewModeNever;
				[addTextField setEnabled: YES];
				
				[cell addSubview:addTextField];
			}
			[addTextField release];
		}
	}
	
	if(activityCell == nil) {
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}
	}
    
	if (indexPath.section == 0) {
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = @"URL";
				break;
			case 1:
				cell.textLabel.text = @"Username";
				break;
			case 2:
				cell.textLabel.text = @"Password";
				break;
			case 3:
				cell.textLabel.text = @"XMLRPC";
				break;
			default:
				break;
		}
	}
	else if(indexPath.section == 1) {
		if((indexPath.row == 0) && (hasSubsites)) {
			cell.textLabel.text = @"Select Sites";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", subsites.count];
		}
		else if(((indexPath.row == 0) && (!hasSubsites)) || (indexPath.row == 1)) {
			cell.textLabel.text = @"Settings";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	else if(indexPath.section == 2) {
		activityCell.textLabel.text = addButtonText;
		cell = activityCell;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	switch (section) {
		case 0:
			result = blogName;
			break;
		default:
			break;
	}
	return result;
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section {
	if(section == 0)
		return footerText;
	
	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	switch (indexPath.section) {
		case 0:
			if(url == nil) {
				footerText = @"URL is required.";
			}
			else if(username == nil) {
				footerText = @"Username is required.";
			}
			else if(password == nil) {
				footerText = @"Password is required.";
			}
			else if((!hasValidXMLRPCurl) && (xmlrpc == nil)) {
				footerText = @"XMLRPC endpoint not found. Please enter it manually.";
			}
			addButtonText = @"Add Blog";
			
			for(UIView *subview in cell.subviews) {
				if(subview.class == [UITextField class]) {
					[subview becomeFirstResponder];
					[tv deselectRowAtIndexPath:indexPath animated:YES];
					break;
				}
			}
			
			break;
		case 1:
			if((hasSubsites) && (indexPath.row == 0)) {
				// Select Sites
				//[self.navigationController pushViewController:addUsersBlogsView animated:YES];
				[tv deselectRowAtIndexPath:indexPath animated:YES];
			}
			else if(((!hasSubsites) && (indexPath.row == 0)) || (indexPath.row == 1)) {
				// Settings
				if(url != nil)
					[appDelegate.currentBlog setObject:url forKey:@"url"];
				if(username != nil)
					[appDelegate.currentBlog setObject:username forKey:@"username"];
				[activeTextField becomeFirstResponder];
				[activeTextField resignFirstResponder];
				BlogSettingsViewController *settingsView;
				
				if (DeviceIsPad())
					settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController-iPad" bundle:nil];
				else 
					settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController" bundle:nil];
				
				[self.navigationController pushViewController:settingsView animated:YES];
				[settingsView release];
				
				[tv deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 2:
			// Save Site
			if([self blogExists]) {
				footerText = @" ";
				addButtonText = @"Saving Site...";
				isSaving = YES;
				[tv deselectRowAtIndexPath:indexPath animated:YES];
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				
				[self performSelectorInBackground:@selector(saveSite) withObject:nil];
			}
			[tv deselectRowAtIndexPath:indexPath animated:YES];
			break;
		default:
			[tv deselectRowAtIndexPath:indexPath animated:YES];
			break;
	}
}

#pragma mark -
#pragma mark UITextField methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;	
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (void)textFieldDidEndEditing: (UITextField *) textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if(((username != nil) && (password != nil)) && ([textField.text isEqualToString:@""]))
				footerText = @"URL is required.";
			else {
				[self setUrl:textField.text];
                [self urlDidChange];
				footerText = nil;
				if(isWPcom == NO)
					[self performSelectorInBackground:@selector(getXMLRPCurl) withObject:nil];
			}
			break;
		case 1:
			if(((url != nil) && (password != nil)) && ([textField.text isEqualToString:@""]))
				footerText = @"Username is required.";
			else {
				[self setUsername:textField.text];
				footerText = nil;
			}
			break;
		case 2:
			if(((username != nil) && (username != nil)) && ([textField.text isEqualToString:@""]))
				footerText = @"Password is required.";
			else {
				[self setPassword:textField.text];
				footerText = nil;
			}
			break;
		case 3:
			if(((isWPcom == NO) && (!hasValidXMLRPCurl) && (username != nil) && (password != nil)) && ([textField.text isEqualToString:@""]))
				footerText = @"XMLRPC endpoint wasn't found. Please enter it manually.";
			else {
				[self setXmlrpc:textField.text];
				hasValidXMLRPCurl = YES;
				footerText = nil;
			}
			break;
		default:
			break;
	}
	
	if((url != nil) && (username != nil) && (password != nil) && (xmlrpc != nil)) {
		[self performSelectorInBackground:@selector(authenticate) withObject:nil];
	}
	
	activeTextField = nil;
}

#pragma mark -
#pragma mark Custom methods

- (void)getSubsites {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	footerText = @"Checking for sites...";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	subsites = [[[WPDataController sharedInstance] getBlogsForUrl:xmlrpc username:username password:password] copy];
	if(subsites.count > 1) {
		hasSubsites = YES;
		//[addUsersBlogsView setUrl:xmlrpc];
		//[addUsersBlogsView setUsername:username];
		//[addUsersBlogsView setPassword:password];
	}
	else if(subsites.count == 1) {
		Blog *blog = [subsites objectAtIndex:0];
		host = blog.hostURL;
		blogID = blog.blogID;
		blogName = blog.blogName;
	}
	
	if([self blogExists] && isAuthenticated) {
		footerText = @"Good to go.";
	}
	
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (void)authenticate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	footerText = @"Authenticating...";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	isAuthenticated = [[WPDataController sharedInstance] authenticateUser:xmlrpc username:username password:password];
	if(isAuthenticated) {
		footerText = @"Authenticated successfully.";
		[self didAuthenticateSuccessfully];
	}
	else
		footerText = @"Incorrect username or password.";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[pool release];
}

- (void)didAuthenticateSuccessfully {
	if(isWPcom == NO)
		[self getSubsites];
}

- (void)getXMLRPCurl {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((url != nil) && (![url isEqualToString:@""])) {
		if(![url hasPrefix:@"http"])
			url = [[NSString stringWithFormat:@"http://%@", url] retain];
		NSString *tempURL = url;
		if(![tempURL hasSuffix:@"/"])
			tempURL = [[NSString stringWithFormat:@"%@/xmlrpc.php", tempURL] retain];
		[self performSelectorOnMainThread:@selector(setXMLRPCUrl:) 
                               withObject:tempURL
                            waitUntilDone:YES];
		
		XMLRPCRequest *xmlrpcMethodsRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpc]];
		[xmlrpcMethodsRequest setMethod:@"system.listMethods" withObjects:[NSArray array]];
		NSArray *xmlrpcMethods = [[BlogDataManager sharedDataManager] executeXMLRPCRequest:xmlrpcMethodsRequest byHandlingError:YES];
		[xmlrpcMethodsRequest release];
		
		if([xmlrpcMethods isKindOfClass:[NSError class]]) {
			hasValidXMLRPCurl = NO;
		}
		else {
			hasValidXMLRPCurl = YES;
		}
	}
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (BOOL)blogExists {
	if([[BlogDataManager sharedDataManager] indexForBlogid:blogID url:url] > -1)
		return YES;
	else
		return NO;
}

- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl {
	xmlrpc = xmlrpcUrl;
}

- (void)urlDidChange {
    NSInteger numSections = [self numberOfSectionsInTableView:self.tableView];
    BOOL didFindUrlTextField = NO;
	for(NSInteger s = 0; s < numSections; s++) { 
		NSInteger numRowsInSection = [self tableView:self.tableView numberOfRowsInSection:s]; 
		for(NSInteger r = 0; r < numRowsInSection; r++) {
			UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]]; 
			for(UIView *subview in cell.contentView.subviews) {
                if([subview isKindOfClass:[UITextField class]]) {
                    UITextField *textField = (UITextField *)subview;
                    textField.text = url;
                    didFindUrlTextField = YES;
                    break;
                }
            }
            if(didFindUrlTextField)
                break;
        }
    }
}

- (void)saveSite {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[spinner show];
	
	[self performSelectorInBackground:@selector(saveSiteInBackground) withObject:nil];
}

- (void)saveSiteInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *authUsername = [appDelegate.currentBlog valueForKey:@"authUsername"];
	NSString *authPassword = [appDelegate.currentBlog valueForKey:@"authPassword"];
	NSNumber *authEnabled = [appDelegate.currentBlog valueForKey:@"authEnabled"];
	
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	NSMutableDictionary *updatedBlog = [[BlogDataManager sharedDataManager] blogAtIndex:blogIndex];
	
	[updatedBlog setValue:blogID forKey:kBlogId];
	[updatedBlog setValue:host forKey:kBlogHostName];
	[updatedBlog setValue:blogName forKey:@"blogName"];
	[updatedBlog setValue:url forKey:@"url"];
	[updatedBlog setValue:xmlrpc forKey:@"xmlrpc"];
	[updatedBlog setValue:username forKey:@"username"];
	[updatedBlog setValue:authEnabled forKey:@"authEnabled"];
	[[BlogDataManager sharedDataManager] updatePasswordInKeychain:password andUserName:username andBlogURL:host];
	
	if([authEnabled isEqualToNumber:[NSNumber numberWithInt:1]]) {
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
														  andUserName:authUsername
														   andBlogURL:authBlogURL];
	}
	[updatedBlog setValue:[appDelegate.currentBlog valueForKey:kResizePhotoSetting] forKey:kResizePhotoSetting];
	[updatedBlog setValue:[appDelegate.currentBlog valueForKey:kPostsDownloadCount] forKey:kPostsDownloadCount];
	[updatedBlog setValue:[appDelegate.currentBlog valueForKey:kGeolocationSetting] forKey:kGeolocationSetting];
	[updatedBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
	
	[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
	[updatedBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[updatedBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] setCurrentBlog:updatedBlog];
	[[BlogDataManager sharedDataManager] saveCurrentBlog];
	[[BlogDataManager sharedDataManager] syncCategoriesForBlog:updatedBlog];
	[[BlogDataManager sharedDataManager] syncStatusesForBlog:updatedBlog];
	
	[self performSelectorOnMainThread:@selector(didSaveSiteSuccessfully) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didSaveSiteSuccessfully {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	if(DeviceIsPad() == YES)
		[self dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
	appDelegate.currentBlog = nil;
	
	[pool release];
}

- (IBAction)cancel:(id)sender {
	if(DeviceIsPad() == YES)
		[self dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)saveSiteFailed {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (keyboardIsVisible)
        return;
	
	if(activeTextField.tag > 0) {
		NSDictionary *info = [notification userInfo];
		NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
		CGSize keyboardSize = [aValue CGRectValue].size;
		
		NSTimeInterval animationDuration = 0.300000011920929;
		CGRect frame = self.view.frame;
		frame.origin.y -= keyboardSize.height-104;
		frame.size.height += keyboardSize.height-104;
		[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
		[UIView setAnimationDuration:animationDuration];
		self.view.frame = frame;
		[UIView commitAnimations];
		
		viewDidMove = YES;
		keyboardIsVisible = YES;
	}
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    if(viewDidMove) {
        NSDictionary *info = [aNotification userInfo];
        NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
        CGSize keyboardSize = [aValue CGRectValue].size;
		
        NSTimeInterval animationDuration = 0.300000011920929;
        CGRect frame = self.view.frame;
        frame.origin.y += keyboardSize.height-104;
        frame.size.height -= keyboardSize.height-104;
        [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        self.view.frame = frame;
        [UIView commitAnimations];
		
        viewDidMove = NO;
    }
	
    keyboardIsVisible = NO;
}

- (void)loadSiteData {
	NSDictionary *site = [[BlogDataManager sharedDataManager] blogForId:blogID hostName:host];
	self.blogName = [site valueForKey:@"blogName"];
	self.url = [site valueForKey:@"url"];
	self.username = [site valueForKey:@"username"];
	[self setPassword:[[BlogDataManager sharedDataManager] getPasswordFromKeychainInContextOfCurrentBlog:site]];
	xmlrpc = [site valueForKey:@"xmlrpc"];
	
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}


- (void)dealloc {
	[subsites release], subsites = nil;
	//[addUsersBlogsView release];
	[tableView release];
	[blogID release];
	[blogName release];
	[host release];
	[spinner release];
	[footerText release];
	[addButtonText release];
	[url release], url = nil;
	[xmlrpc release], xmlrpc = nil;
	[username release], username = nil;
	[password release], password = nil;
    [super dealloc];
}


@end

