//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@implementation AddSiteViewController
@synthesize spinner, footerText, addButtonText, url, xmlrpc, username, password, tableView;
@synthesize isAuthenticating, isAuthenticated, isAdding, hasSubsites, subsites, viewDidMove, keyboardIsVisible;
@synthesize hasValidXMLRPCurl, addUsersBlogsView, activeTextField, blogID, host, blogName, hasCheckedForSubsites;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	hasValidXMLRPCurl = YES;	// Assume true until proven wrong.
	addButtonText = @"Add Site";
	self.navigationItem.title = @"Add Site";
	[spinner initWithLabel:@"Saving..."];
	addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
	addUsersBlogsView.isWPcom = NO;
	
	// Setup WPorg table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wporg";
	if(DeviceIsPad() == YES) {
		logoFile = @"logo_wporg.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	else if([[UIDevice currentDevice] platformString] == IPHONE_1G_NAMESTRING) {
		logoFile = @"logo_wporg.png";
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
	self.tableView.backgroundColor = [UIColor clearColor];
	
	if(DeviceIsPad()) {
		[self.tableView setBackgroundView:nil];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	if(appDelegate.currentBlog == nil)
		appDelegate.currentBlog = [[NSMutableDictionary alloc] init];
	
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
			CGRect textFrame = CGRectMake(110, 10, 185, 30);
			if(DeviceIsPad()){
				textFrame = CGRectMake(150, 12, 350, 42);
			}
			UITextField *addTextField = [[UITextField alloc] initWithFrame:textFrame];
			//addTextField.adjustsFontSizeToFitWidth = YES;
			addTextField.textColor = [UIColor blackColor];
			if ([indexPath section] == 0) {
				if (indexPath.row == 0) {
					addTextField.placeholder = @"http://example.com";
					addTextField.keyboardType = UIKeyboardTypeURL;
					if(url != nil)
						addTextField.text = url;
				}
				else if(indexPath.row == 1) {
					addTextField.placeholder = @"WordPress username";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					if(username != nil)
						addTextField.text = username;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"WordPress password";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.secureTextEntry = YES;
					if(password != nil)
						addTextField.text = password;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"http://example.com/xmlrpc.php";
					addTextField.keyboardType = UIKeyboardTypeURL;
					if(xmlrpc != nil)
						addTextField.text = xmlrpc;
				}
				
				if(DeviceIsPad() == YES)
					addTextField.backgroundColor = [UIColor clearColor];
				else
					addTextField.backgroundColor = [UIColor whiteColor];
				addTextField.tag = indexPath.row;
				addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
				addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				addTextField.textAlignment = UITextAlignmentLeft;
				addTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
				addTextField.delegate = self;
				addTextField.returnKeyType = UIReturnKeyDone;
				[addTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
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
				if(DeviceIsPad() == YES) {
					activityCell.textLabel.frame = CGRectMake(90, 4, 300, 40);
				}
				
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
		if(isAdding)
			[activityCell.spinner startAnimating];
		else
			[activityCell.spinner stopAnimating];
		cell = activityCell;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
	return nil;
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
				footerText = @"XMLRPC endpoint wasn't found. Please enter it manually.";
			}
			addButtonText = @"Add Site";
			
			for(UIView *subview in cell.subviews) {
				if(subview.class == [UITextField class]) {
					[subview becomeFirstResponder];
					[tv deselectRowAtIndexPath:indexPath animated:YES];
					break;
				}
			}
			
			break;
		case 1:
			if(isAdding == NO) {
				if((hasSubsites) && (indexPath.row == 0)) {
					// Select Sites
					[self.navigationController pushViewController:addUsersBlogsView animated:YES];
					[tv deselectRowAtIndexPath:indexPath animated:YES];
				}
				else if(((!hasSubsites) && (indexPath.row == 0)) || (indexPath.row == 1)) {
					// Settings
					if(url != nil)
						[appDelegate.currentBlog setObject:url forKey:@"url"];
					if(username != nil)
						[appDelegate.currentBlog setObject:username forKey:@"username"];
					if(activeTextField != nil) {
						[activeTextField becomeFirstResponder];
						[activeTextField resignFirstResponder];
					}
					BlogSettingsViewController *settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController" bundle:nil];
					[self.navigationController pushViewController:settingsView animated:YES];
					[settingsView release];
					
					[tv deselectRowAtIndexPath:indexPath animated:YES];
				}
			}
			break;
		case 2:
			// Add Site
			if(([self blogExists] == NO) && (isAdding == NO)) {
				footerText = @" ";
				addButtonText = @"Adding Site...";
				isAdding = YES;
				[tv deselectRowAtIndexPath:indexPath animated:YES];
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				
				if(isAuthenticated == NO)
					[self performSelectorInBackground:@selector(authenticate) withObject:nil];
				else if(hasCheckedForSubsites == NO) {
					[self performSelectorInBackground:@selector(getSubsites) withObject:nil];
				}
				else if(isAuthenticated == YES) {
					[tv deselectRowAtIndexPath:indexPath animated:YES];
					[self performSelectorInBackground:@selector(addSite) withObject:nil];
				}
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
	[textField endEditing:YES];
	[textField resignFirstResponder];
	return YES;	
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (void)textFieldDidEndEditing: (UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if(((username != nil) && (password != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"URL is required.";
				[self setUrl:textField.text];
			}
			else {
				[self setUrl:textField.text];
                [self urlDidChange];
				footerText = nil;
				[self performSelectorInBackground:@selector(getXMLRPCurl) withObject:nil];
			}
			break;
		case 1:
			if(((url != nil) && (password != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"Username is required.";
				[self setUsername:textField.text];
			}
			else {
				footerText = nil;
				[self setUsername:textField.text];
			}
			break;
		case 2:
			if(((username != nil) && (username != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"Password is required.";
				[self setPassword:textField.text];
			}
			else {
				footerText = nil;
				[self setPassword:textField.text];
			}
			break;
		case 3:
			if(((!hasValidXMLRPCurl) && (username != nil) && (password != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"XMLRPC endpoint wasn't found. Please enter it manually.";
			}
			else {
				[self setXMLRPCUrl:activeTextField.text];
				hasValidXMLRPCurl = YES;
				footerText = nil;
			}
			break;
		default:
			break;
	}
	
	[self refreshTable];
	
	if((url != nil) && (username != nil) && (password != nil) && (xmlrpc != nil)) {
		[self authenticate];
	}
	
	activeTextField = nil;
}

- (void)textFieldDidChange:(UITextField *)textField {
//	switch (textField.tag) {
//		case 0:
//			url = textField.text;
//			break;
//		case 1:
//			username = textField.text;
//			break;
//		case 2:
//			password = textField.text;
//			break;
//		case 3:
//			xmlrpc = textField.text;
//			break;
//		default:
//			break;
//	}
}

#pragma mark -
#pragma mark Custom methods

- (void)getSubsites {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	footerText = @"Checking for sites...";
	[self refreshTable];
	
	subsites = [[[WPDataController sharedInstance] getBlogsForUrl:xmlrpc username:username password:password] retain];
	[self performSelectorOnMainThread:@selector(didGetSubsitesSuccessfully:) withObject:subsites waitUntilDone:NO];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (void)didGetSubsitesSuccessfully:(NSArray *)results {
	hasCheckedForSubsites = YES;
	if((results != nil) && (results.count > 1)) {
		hasSubsites = YES;
		[self setSubsites:results];
		[addUsersBlogsView setUrl:xmlrpc];
		[addUsersBlogsView setUsername:username];
		[addUsersBlogsView setPassword:password];
	}
	
	if([self blogExists] == NO) {
		if(isAuthenticated) 
			footerText = @"Good to go.";
		else
			footerText = @"";
	}
	else
		footerText = @"Site has already been added.";
	
	[self refreshTable];
	
	@try {
		Blog *blog = [subsites objectAtIndex:0];
		[self setHost:blog.hostURL];
		[self setBlogID:blog.blogID];
		[self setBlogName:blog.blogName];
		
		if(isAdding)
			[self performSelectorInBackground:@selector(addSite) withObject:nil];
	}
	@catch (NSException * e) {
		NSLog(@"Error adding site: %@", e);
	}
}

- (void)authenticate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	footerText = @"Authenticating...";
	[self refreshTable];
	
	XMLRPCResponse *xmlrpcCheck = [[WPDataController sharedInstance] checkXMLRPC:xmlrpc username:username password:password];
	if(![xmlrpcCheck isKindOfClass:[NSError class]]) {
		isAuthenticated = [[WPDataController sharedInstance] authenticateUser:xmlrpc username:username password:password];
		if(isAuthenticated == YES) {
			footerText = @"Authenticated successfully.";
			[self performSelectorOnMainThread:@selector(didAuthenticateSuccessfully) withObject:nil waitUntilDone:NO];
		}
		else {
			isAdding = NO;
			addButtonText = @"Add Site";
			footerText = @"Incorrect username or password.";
		}
	}
	else {
		NSError *error = (NSError *)xmlrpcCheck;
		if([[[error localizedDescription] lowercaseString] isEqualToString:@"404 not found"] == YES)
			footerText = @"XML-RPC endpoint not found. Please enter it manually.";
		else
			footerText = [error localizedDescription];
		isAdding = NO;
		addButtonText = @"Add Site";
	}
	[self refreshTable];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (void)didAuthenticateSuccessfully {
	if((isAdding == NO) || ((username == nil) || (password == nil) || (xmlrpc == nil)))
		[self performSelectorInBackground:@selector(getSubsites) withObject:nil];
	else if((username != nil) && (password != nil) && (xmlrpc != nil) && (host != nil) && (blogID!= nil))
		[self performSelectorInBackground:@selector(addSite) withObject:nil];
}

- (void)getXMLRPCurl {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[BlogDataManager sharedDataManager].shouldDisplayErrors = NO;
	
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
			NSString *regEx = @"http(s)?://[^\"]*\\.php";
			NSString *html = [NSString stringWithContentsOfURL:[NSURL URLWithString:url]];
			NSString *match = [html stringByMatching:regEx];
			if([match isEqual:@""] == NO) {
				XMLRPCRequest *xmlrpcMethodsRequest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:match]];
				[xmlrpcMethodsRequest setMethod:@"system.listMethods" withObjects:[NSArray array]];
				NSArray *xmlrpcMethods = [[BlogDataManager sharedDataManager] executeXMLRPCRequest:xmlrpcMethodsRequest byHandlingError:YES];
				[xmlrpcMethodsRequest release];
				
				if(![xmlrpcMethods isKindOfClass:[NSError class]]) {
					[self performSelectorOnMainThread:@selector(setXMLRPCUrl:) 
										   withObject:match
										waitUntilDone:YES];
					hasValidXMLRPCurl = YES;
				}
				else {
					hasValidXMLRPCurl = NO;
				}

			}
			else {
				hasValidXMLRPCurl = NO;
			}
		}
		else {
			hasValidXMLRPCurl = YES;
		}
	}

	[BlogDataManager sharedDataManager].shouldDisplayErrors = YES;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (BOOL)blogExists {
	BOOL result = NO;
	//NSString *authPassword = password;
	NSNumber *authEnabled = [NSNumber numberWithBool:NO];
	//NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 username, @"authUsername", 
									 nil] retain];
	result = [[BlogDataManager sharedDataManager] doesBlogExist:newBlog];
	
	[newBlog release];
	
	return result;
}

- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl {
	xmlrpc = [xmlrpcUrl retain];
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

- (void)addSite {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[spinner show];
	
	NSString *authUsername = [appDelegate.currentBlog valueForKey:@"authUsername"];
	NSString *authPassword = [appDelegate.currentBlog valueForKey:@"authPassword"];
	NSNumber *authEnabled = [appDelegate.currentBlog valueForKey:@"authEnabled"];
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil] retain];
	
	[[BlogDataManager sharedDataManager] resetCurrentBlog];
	[newBlog setValue:blogID forKey:kBlogId];
	NSString *hostURL = [[NSString alloc] initWithFormat:@"%@", 
						 [host stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
	self.host = hostURL;
	
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", self.host];
	[newBlog setValue:hostURL forKey:kBlogHostName];
	[hostURL release];
	
	[newBlog setValue:blogName forKey:@"blogName"];
	[newBlog setValue:url forKey:@"url"];
	[newBlog setValue:xmlrpc forKey:@"xmlrpc"];
	[newBlog setValue:username forKey:@"username"];
	[newBlog setValue:authEnabled forKey:@"authEnabled"];
	
	[[BlogDataManager sharedDataManager] saveBlogPasswordToKeychain:self.password 
														andUserName:self.username 
														 andBlogURL:[self.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
	
	if([authEnabled isEqualToNumber:[NSNumber numberWithInt:1]]) {
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
														  andUserName:authUsername
														   andBlogURL:authBlogURL];
	}
	[newBlog setValue:[appDelegate.currentBlog valueForKey:kResizePhotoSetting] forKey:kResizePhotoSetting];
	if ([appDelegate.currentBlog valueForKey:kResizePhotoSetting] == nil){
		[newBlog setValue:[NSNumber numberWithInt:10] forKey:kPostsDownloadCount];
	}
	else {
		[newBlog setValue:[appDelegate.currentBlog valueForKey:kPostsDownloadCount] forKey:kPostsDownloadCount];
	}
	[newBlog setValue:[appDelegate.currentBlog valueForKey:kGeolocationSetting] forKey:kGeolocationSetting];
	[newBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
	
	[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
	[newBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[newBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] setCurrentBlog:newBlog];
	[BlogDataManager sharedDataManager].currentBlogIndex = -1;
	[[BlogDataManager sharedDataManager] saveCurrentBlog];
	[[BlogDataManager sharedDataManager] syncCategoriesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[[BlogDataManager sharedDataManager] syncStatusesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[newBlog release];
	
	[self performSelectorOnMainThread:@selector(didAddSiteSuccessfully) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void)didAddSiteSuccessfully {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[appDelegate syncBlogs];
	if(activeTextField != nil) {
		[activeTextField becomeFirstResponder];
		[activeTextField resignFirstResponder];
	}
	if(DeviceIsPad())
		[appDelegate.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
	appDelegate.currentBlog = nil;
	isAdding = NO;
}

- (void)addSiteFailed {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[self refreshTable];
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (keyboardIsVisible)
        return;
	
	NSDictionary *info = [notification userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	
	NSTimeInterval animationDuration = 0.300000011920929;
	CGRect frame = self.view.frame;
	frame.origin.y -= keyboardSize.height-140;
	frame.size.height += keyboardSize.height-140;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	self.view.frame = frame;
	[UIView commitAnimations];
	
	viewDidMove = YES;
	keyboardIsVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    if(viewDidMove) {
        NSDictionary *info = [aNotification userInfo];
        NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
        CGSize keyboardSize = [aValue CGRectValue].size;
		
        NSTimeInterval animationDuration = 0.300000011920929;
        CGRect frame = self.view.frame;
        frame.origin.y += keyboardSize.height-140;
        frame.size.height -= keyboardSize.height-140;
        [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        self.view.frame = frame;
        [UIView commitAnimations];
		
        viewDidMove = NO;
    }
	
    keyboardIsVisible = NO;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}


- (void)dealloc {
	[tableView release];
	[subsites release];
	subsites = nil;
	[addUsersBlogsView release];
	[spinner release];
	[footerText release];
	[addButtonText release];
	[url release];
	url = nil;
	[xmlrpc release];
	xmlrpc = nil;
	[username release];
	username = nil;
	[password release];
	password = nil;
	[blogID release];
	[blogName release];
	[host release];
    [super dealloc];
}


@end

