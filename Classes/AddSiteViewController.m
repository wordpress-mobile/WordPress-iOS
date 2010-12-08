//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@implementation AddSiteViewController
@synthesize spinner, footerText, addButtonText, url, xmlrpc, username, password, tableView, isGettingXMLRPCURL;
@synthesize isAuthenticating, isAuthenticated, isAdding, hasSubsites, subsites, viewDidMove, keyboardIsVisible;
@synthesize hasValidXMLRPCurl, addUsersBlogsView, activeTextField, blogID, host, blogName, hasCheckedForSubsites;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	footerText = @" ";
	
	hasValidXMLRPCurl = YES;	// Assume true until proven wrong.
	addButtonText = @"Add Blog";
	self.navigationItem.title = @"Add Blog";
	[spinner initWithLabel:@"Saving..."];
	addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
	addUsersBlogsView.isWPcom = NO;
    isAuthenticating = NO;
	
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
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = YES;
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
	[BlogDataManager sharedDataManager].shouldStopSyncingBlogs = NO;
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
			CGRect textFrame = CGRectMake(110, 11, 200, 22);
			if(DeviceIsPad()){
				textFrame = CGRectMake(150, 12, 350, 42);
			}
			UITextField *addTextField = [[UITextField alloc] initWithFrame:textFrame];
			addTextField.adjustsFontSizeToFitWidth = NO;
			addTextField.textColor = [UIColor blackColor];
			addTextField.font = [UIFont systemFontOfSize:16.0];
            if (indexPath.row == 0) {
                addTextField.placeholder = @"yourawesomeblog.com";
                addTextField.keyboardType = UIKeyboardTypeURL;
                addTextField.returnKeyType = UIReturnKeyNext;
                if(url != nil)
                    addTextField.text = self.url;
                urlTextField = addTextField;
            }
            else if(indexPath.row == 1) {
                addTextField.placeholder = @"WordPress username";
                addTextField.keyboardType = UIKeyboardTypeDefault;
                if(username != nil)
                    addTextField.text = username;
                addTextField.returnKeyType = UIReturnKeyNext;
            }
            else if(indexPath.row == 2) {
                addTextField.placeholder = @"WordPress password";
                addTextField.keyboardType = UIKeyboardTypeDefault;
                addTextField.secureTextEntry = YES;
                if(password != nil)
                    addTextField.text = password;
                addTextField.returnKeyType = UIReturnKeyDone;
            }
            else if(indexPath.row == 2) {
                addTextField.placeholder = @"http://example.com/xmlrpc.php";
                addTextField.keyboardType = UIKeyboardTypeURL;
                if(xmlrpc != nil)
                    addTextField.text = xmlrpc;
                addTextField.returnKeyType = UIReturnKeyDone;
            }

            if(DeviceIsPad() == YES)
                addTextField.backgroundColor = [UIColor clearColor];
            else
                addTextField.backgroundColor = [UIColor whiteColor];
            addTextField.tag = indexPath.row;
            addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            addTextField.textAlignment = UITextAlignmentLeft;
            addTextField.clearButtonMode = UITextFieldViewModeAlways;
            addTextField.delegate = self;
            [addTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [addTextField setEnabled: YES];

            [cell addSubview:addTextField];
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
				cell.textLabel.text = @"XML-RPC";
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
        if (isAuthenticating) {
            activityCell.textLabel.textColor = [UIColor lightGrayColor];
            activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            activityCell.textLabel.textColor = [UIColor blackColor];
            activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }

		if(isAdding)
			[activityCell.spinner startAnimating];
		else
			[activityCell.spinner stopAnimating];
		cell = activityCell;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
	return @"";
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section {
	if((section == 0) && (footerText != nil))
		return footerText;
	
	return @"";
}

#pragma mark -
#pragma mark Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 2) && isAuthenticating) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	switch (indexPath.section) {
		case 0:
			if(url == nil) {
				footerText = @"The URL field is empty.";
			}
			else if(username == nil) {
				footerText = @"The username field is empty.";
			}
			else if(password == nil) {
				footerText = @"The password field is empty.";
			}
			else if((!hasValidXMLRPCurl) && (xmlrpc == nil)) {
				footerText = @"XMLRPC endpoint wasn't found. Please enter it manually.";
			}

			if(hasSubsites)
				addButtonText = @"Add Blogs";
			else
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
					
					BlogSettingsViewController *settingsView;
					if(DeviceIsPad())
						settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsView-iPad" bundle:nil];
					else
						settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController" bundle:nil];
					[self.navigationController pushViewController:settingsView animated:YES];
					[settingsView release];
					
					[tv deselectRowAtIndexPath:indexPath animated:YES];
				}
			}
			break;
		case 2:
			// Add Site
			if(([self blogExists] == NO) && (isAdding == NO) && (url != nil) && (![url isEqualToString:@""])) {
				if(isAuthenticated == YES && hasSubsites) {
					// shows the Select Sites screen
					[self.navigationController pushViewController:addUsersBlogsView animated:YES];
					[tv deselectRowAtIndexPath:indexPath animated:YES];
					[tv reloadData];
				} else {
					footerText = @" ";
					addButtonText = @"Adding Blog...";
					isAdding = YES;
					[tv deselectRowAtIndexPath:indexPath animated:YES];
					[NSThread sleepForTimeInterval:0.15];
					[tv reloadData];

					if(isAuthenticated == NO)
						[self authenticateInBackground];
					else if(hasCheckedForSubsites == NO) {
						[self performSelectorInBackground:@selector(getSubsites) withObject:nil];
					}
					else if(isAuthenticated == YES) {
						[tv deselectRowAtIndexPath:indexPath animated:YES];
						[self performSelectorInBackground:@selector(addSite) withObject:nil];
					}
				}
			}
			else if((url == nil) || ([url isEqualToString:@""])) {
				footerText = @"The URL field is empty.";
				[tv reloadData];
			}
			else if((username == nil) || ([username isEqualToString:@""])) {
				footerText = @"The username field is empty.";
				[tv reloadData];
			}
			else if((password == nil) || ([password isEqualToString:@""])) {
				footerText = @"The password field is empty.";
				[tv reloadData];
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
	UITableViewCell *cell = nil;
	UITextField *nextField = nil;
	switch (textField.tag) {
		case 0:
			[textField endEditing:YES];
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
			if(cell != nil) {
				nextField = (UITextField*)[cell viewWithTag:1];
				if(nextField != nil)
					[nextField becomeFirstResponder];
			}
			break;
		case 1:
			[textField endEditing:YES];
			cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2
																	   inSection:0]];
			if(cell != nil) {
				nextField = (UITextField*)[cell viewWithTag:2];
				if(nextField != nil)
					[nextField becomeFirstResponder];
			}
			break;
		default:
			[textField endEditing:YES];
			[textField resignFirstResponder];
			break;
	}
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
				footerText = @"The URL field is empty.";
				self.url = nil;
			}
			else {
				[self setUrl:textField.text];
                [self urlDidChange];
				self.hasCheckedForSubsites = NO;
				footerText = @" ";
				xmlrpc = nil;
				[self performSelectorInBackground:@selector(getXMLRPCurl) withObject:nil];
			}
			break;
		case 1:
			if(((self.url != nil) && (password != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"The username field is empty.";
				[self setUsername:textField.text];
			}
			else {
				footerText = @" ";
				[self setUsername:textField.text];
			}
			break;
		case 2:
			if(((username != nil) && (username != nil)) && ([textField.text isEqualToString:@""])) {
				footerText = @"The password field is empty.";
				[self setPassword:textField.text];
			}
			else {
				footerText = @" ";
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
				footerText = @" ";
			}
			break;
		default:
			break;
	}
	if((self.url != nil) && (username != nil) && (password != nil) && (xmlrpc != nil)) {
        [self authenticateInBackground];
	}
	
	[self refreshTable];
	
	activeTextField = nil;
}

- (void)textFieldDidChange:(UITextField *)textField {
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
	
	if(hasSubsites)
		addButtonText = @"Add Blogs";
	else
		addButtonText = @"Add Blog";

	if([self blogExists] == NO) {
		if(isAuthenticated) 
			footerText = @"Good to go.";
		else
			footerText = @" ";
	}
	else
		footerText = @"Blog has already been added.";
	
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
	
	[self refreshTable];
}

- (void)authenticate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((username != nil) && (password != nil) && (![username isEqualToString:@""]) && (![password isEqualToString:@""])) {
		footerText = @"Authenticating...";
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
		
		if(xmlrpc == nil)
			[self getXMLRPCUrlSynchronously];
		
		// Check for HTTP auth first
		if(xmlrpc != nil) {
			ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpc]];
			[request setShouldPresentCredentialsBeforeChallenge:NO];
			[request startSynchronous];
            [request release];
			
			if(xmlrpc != nil) {
				isAuthenticated = [[WPDataController sharedInstance] authenticateUser:xmlrpc username:username password:password];
				if(isAuthenticated == YES) {
					footerText = @"Authenticated successfully.";
					[self performSelectorOnMainThread:@selector(didAuthenticateSuccessfully) withObject:nil waitUntilDone:NO];
				}
				else {
					isAdding = NO;
					addButtonText = @"Add Blog";
					footerText = @"Incorrect username or password.";
				}
			}
			else {
				footerText = @"XML-RPC endpoint not found. Please enter it manually.";
				isAdding = NO;
				addButtonText = @"Add Blog";
			}
			[self performSelectorOnMainThread:@selector(didFailAuthentication) withObject:nil waitUntilDone:NO];
		}
	}
	else if((username == nil) || ([username isEqualToString:@""])) {
		isAdding = NO;
		addButtonText = @"Add Blog";
		footerText = @"The username field is empty.";
		[self performSelectorOnMainThread:@selector(didFailAuthentication) withObject:nil waitUntilDone:NO];
	}
	else if((password == nil) || ([password isEqualToString:@""])) {
		isAdding = NO;
		addButtonText = @"Add Blog";
		footerText = @"The password field is empty.";
		[self performSelectorOnMainThread:@selector(didFailAuthentication) withObject:nil waitUntilDone:NO];
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (void)authenticateInBackground {
    isAuthenticating = YES;
    [self performSelectorInBackground:@selector(authenticate) withObject:nil];
}

- (void)didAuthenticateSuccessfully {
    isAuthenticating = NO;
	if((isAdding == NO) || ((username == nil) || (password == nil) || (xmlrpc == nil) || (hasCheckedForSubsites == NO)))
		[self performSelectorInBackground:@selector(getSubsites) withObject:nil];
	else if((username != nil) && (password != nil) && (xmlrpc != nil))
		[self performSelectorInBackground:@selector(addSite) withObject:nil];
}

- (void)didFailAuthentication {
    isAuthenticating = NO;
    [self refreshTable];
}

- (void)getXMLRPCurl {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((!isGettingXMLRPCURL) && (xmlrpc == nil)) {
		isGettingXMLRPCURL = YES;
		[BlogDataManager sharedDataManager].shouldDisplayErrors = NO;
		
		if((self.url != nil) && (![url isEqualToString:@""])) {
			if(![self.url hasPrefix:@"http"])
				self.url = [NSString stringWithFormat:@"http://%@", self.url];
			
			// Grab our XML-RPC url
			ASIHTTPRequest *htmlRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:self.url]];
			[htmlRequest setShouldPresentCredentialsBeforeChallenge:NO];
			[htmlRequest setShouldPresentAuthenticationDialog:YES];
			[htmlRequest setUseKeychainPersistence:YES];
            [htmlRequest setShouldUseRFC2616RedirectBehaviour:YES];
			[htmlRequest setDelegate:self];
			[htmlRequest startAsynchronous];
			[htmlRequest release];
		}
		
		[BlogDataManager sharedDataManager].shouldDisplayErrors = YES;
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (void)getXMLRPCUrlSynchronously {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((self.url != nil) && (![url isEqualToString:@""])) {
		if(![self.url hasPrefix:@"http"])
			self.url = [NSString stringWithFormat:@"http://%@", self.url];
	}
	
	// Start by just trying URL + /xmlrpc.php
	NSString *xmlrpcURL = [self.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if(![xmlrpcURL hasSuffix:@"/"])
		xmlrpcURL = [NSString stringWithFormat:@"%@/xmlrpc.php", xmlrpcURL];
	else
		xmlrpcURL = [NSString stringWithFormat:@"%@xmlrpc.php", xmlrpcURL];
	
	ASIHTTPRequest *xmlrpcRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpcURL]];
	[xmlrpcRequest setShouldPresentCredentialsBeforeChallenge:NO];
	[xmlrpcRequest setShouldPresentAuthenticationDialog:YES];
	[xmlrpcRequest setUseKeychainPersistence:YES];
	[xmlrpcRequest setDelegate:self];
	[xmlrpcRequest startSynchronous];
	
	NSError *error = [xmlrpcRequest error];
	if(!error) {
		NSString *responseString = [xmlrpcRequest responseString];
		
		if([responseString rangeOfString:@"XML-RPC server accepts POST requests only."].location != NSNotFound)
			[self performSelectorInBackground:@selector(verifyXMLRPCurlInBackground:) withObject:xmlrpcURL];
		else {
			// We're looking for: <link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://myblog.com/xmlrpc.php?rsd" />
			NSString *rsdURL = [responseString stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
			
			// We found a valid RSD document, now try to parse the XML
			NSError *rsdError;
			if(rsdURL != nil) {
				CXMLDocument *rsdXML = [[[CXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:rsdURL] options:0 error:&rsdError] autorelease];
				if(!rsdError) {
					CXMLElement *serviceXML = [[[rsdXML rootElement] children] objectAtIndex:1];
					for(CXMLElement *api in [[[serviceXML elementsForName:@"apis"] objectAtIndex:0] elementsForName:@"api"]) {
						if([[[api attributeForName:@"name"] stringValue] isEqualToString:@"WordPress"]) {
							// Bingo! We found the WordPress XML-RPC element
							[self verifyXMLRPCurl:[[api attributeForName:@"apiLink"] stringValue]];
						}
					}
				}
				else {
					// RSD document was invalid
					footerText = [rsdError localizedDescription];
					[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
				}
			}
			else {
				self.hasValidXMLRPCurl = NO;
				[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
			}
		}
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)requestStarted:(ASIHTTPRequest *)request {
}

- (void)requestReceivedResponseHeaders:(ASIHTTPRequest *)request {
    NSDictionary *headers = [request responseHeaders];
    NSString *redirect = [headers objectForKey:@"Location"];
    if (redirect != nil) {
        [self setUrl:redirect];
        [self urlDidChange];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	//NSLog(@"requestFinished: %@", [request responseString]);
	
	// Success.
	// Check to see if we should store HTTP Auth credentials
	NSDictionary *credentials = [request findCredentials];
	if(credentials != nil) {
		[appDelegate.currentBlog setObject:[credentials objectForKey:@"kCFHTTPAuthenticationUsername"] forKey:@"authUsername"];
		[appDelegate.currentBlog setObject:[credentials objectForKey:@"kCFHTTPAuthenticationPassword"] forKey:@"authPassword"];
		[appDelegate.currentBlog setObject:[NSNumber numberWithInt:1] forKey:@"authEnabled"];
	}
	else {
		[appDelegate.currentBlog setObject:[NSNumber numberWithInt:0] forKey:@"authEnabled"];
	}
	
	// Start by just trying URL + /xmlrpc.php
	NSString *xmlrpcURL = [self.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if(![xmlrpcURL hasSuffix:@"/"])
		xmlrpcURL = [NSString stringWithFormat:@"%@/xmlrpc.php", xmlrpcURL];
	else
		xmlrpcURL = [NSString stringWithFormat:@"%@xmlrpc.php", xmlrpcURL];
	
	ASIHTTPRequest *xmlrpcRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpcURL]];
	[xmlrpcRequest setRequestMethod:@"GET"];
	[xmlrpcRequest setShouldPresentAuthenticationDialog:YES];
	[xmlrpcRequest setUseKeychainPersistence:YES];
	[xmlrpcRequest startSynchronous];
	
	NSError *error = [xmlrpcRequest error];
	if(!error) {
		NSString *responseString = [xmlrpcRequest responseString];
		if([responseString rangeOfString:@"XML-RPC server accepts POST requests only."].location != NSNotFound)
			[self performSelectorInBackground:@selector(verifyXMLRPCurlInBackground:) withObject:xmlrpcURL]; // Success
		else if([responseString isEqualToString:@""]) {
			// XML-RPC isn't enabled
			self.footerText = @"It looks like XML-RPC isn't enabled on your blog. You can enable it by going to "
			"Settings > Writing > Remote Publishing.\n\nIf you're sure XML-RPC is enabled, try setting the XML-RPC endpoint manually using the field above.";
			self.hasValidXMLRPCurl = NO;
			self.isGettingXMLRPCURL = NO;
			[self refreshTable];
		}
		else {
			// We're looking for: <link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://myblog.com/xmlrpc.php?rsd" />
			NSString *rsdURL = [[request responseString] stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
			
			[self performSelectorInBackground:@selector(verifyRSDurl:) withObject:rsdURL];
		}
	}
    [xmlrpcRequest release];
	
	self.isGettingXMLRPCURL = NO;
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	self.hasValidXMLRPCurl = NO;
	
	NSError *error = [request error];
	NSString *errorMessage = [error localizedDescription];
	if((ASIConnectionFailureErrorType == [error code]) || (ASIRequestTimedOutErrorType == [error code])) {
		errorMessage = @"Couldn't connect to URL";
		
		// Fake out hasValidXMLRPCurl so we don't confuse the user.
		// Right now the main problem is the URL field.
		self.hasValidXMLRPCurl = YES;
	}
	
	self.footerText = [NSString stringWithFormat:@"%@.", errorMessage];
	self.isGettingXMLRPCURL = NO;
	self.isAdding = NO;
	addButtonText = @"Add Blog";
	[self refreshTable];
}

- (void)verifyRSDurl:(NSString *)rsdURL {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// We found a valid RSD document, now try to parse the XML
	NSError *rsdError;
	if(rsdURL != nil) {
		CXMLDocument *rsdXML = [[[CXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:rsdURL] options:0 error:&rsdError] autorelease];
		if(!rsdError) {
			CXMLElement *serviceXML = [[[rsdXML rootElement] children] objectAtIndex:1];
			for(CXMLElement *api in [[[serviceXML elementsForName:@"apis"] objectAtIndex:0] elementsForName:@"api"]) {
				if([[[api attributeForName:@"name"] stringValue] isEqualToString:@"WordPress"]) {
					// Bingo! We found the WordPress XML-RPC element
					[self verifyXMLRPCurl:[[api attributeForName:@"apiLink"] stringValue]];
				}
			}
		}
		else {
			// RSD document was invalid
			footerText = [rsdError localizedDescription];
			[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
		}
	}
	else {
		self.hasValidXMLRPCurl = NO;
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}

	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[pool release];
}

- (void)verifyXMLRPCurl:(NSString *)xmlrpcURL {
	xmlrpcURL = [xmlrpcURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	ASIHTTPRequest *xmlrpcRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpcURL]];
	[xmlrpcRequest setRequestMethod:@"POST"];
	[xmlrpcRequest setShouldPresentCredentialsBeforeChallenge:NO];
	[xmlrpcRequest setShouldPresentAuthenticationDialog:YES];
	[xmlrpcRequest setUseKeychainPersistence:YES];
	
	XMLRPCRequest *xmlrpcTest = [[XMLRPCRequest alloc] initWithHost:[NSURL URLWithString:xmlrpcURL]];
	[xmlrpcTest setMethod:@"system.listMethods" withObjects:[NSArray array]];
	[xmlrpcRequest appendPostData:[[xmlrpcTest source] dataUsingEncoding:NSUTF8StringEncoding]];
    [xmlrpcTest release];
	[xmlrpcRequest startSynchronous];
	
	NSError *error = [xmlrpcRequest error];
	if(!error) {
		// Let's double check our XML-RPC endpoint for validity
		CXMLDocument *xml = [[[CXMLDocument alloc] initWithXMLString:[xmlrpcRequest responseString] options:0 error:nil] autorelease];
		NSArray *xmlrpcMethods = [xml nodesForXPath:@"//params/param/value/array/data/*" error:nil];
		if(xmlrpcMethods.count > 0) {
			self.hasValidXMLRPCurl = YES;
			self.xmlrpc = xmlrpcURL;
		}
		else {
			self.hasValidXMLRPCurl = NO;
			[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
		}
	}
	else {
		self.hasValidXMLRPCurl = NO;
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}
	[xmlrpcRequest release];

	isGettingXMLRPCURL = NO;
}

- (void)verifyXMLRPCurlInBackground:(NSString *)xmlrpcURL {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self verifyXMLRPCurl:xmlrpcURL];
	
	[pool release];
}

- (BOOL)blogExists {
	BOOL result = NO;
	//NSString *authPassword = password;
	NSNumber *authEnabled = [NSNumber numberWithBool:NO];
	//NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 self.url, @"url", 
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
    if (urlTextField != nil) {
        urlTextField.text = self.url;
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
									 self.url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil] retain];
	
	[[BlogDataManager sharedDataManager] resetCurrentBlog];
	[newBlog setValue:blogID forKey:kBlogId];
	
	if(self.host == nil)
		self.host = [NSString stringWithString:self.url];
		
	NSString *hostURL = [[NSString alloc] initWithFormat:@"%@", 
						 [self.host stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
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
	
	NSLog(@"saving newBlog: %@", newBlog);
	
	[BlogDataManager sharedDataManager].currentBlogIndex = -1;
	[[BlogDataManager sharedDataManager] saveCurrentBlog];
	[[BlogDataManager sharedDataManager] syncCategoriesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[[BlogDataManager sharedDataManager] syncStatusesForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[[BlogDataManager sharedDataManager] syncPostsForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[newBlog release];
	
	[self performSelectorOnMainThread:@selector(didAddSiteSuccessfully) withObject:nil waitUntilDone:NO];
	[pool release];
}

- (void)didAddSiteSuccessfully {
	if(!DeviceIsPad())
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	if(activeTextField != nil) {
		[activeTextField becomeFirstResponder];
		[activeTextField resignFirstResponder];
	}
	
	appDelegate.currentBlog = nil;
	isAdding = NO;
	
	if(DeviceIsPad())
		[appDelegate.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
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
	
	if(!DeviceIsPad()) {
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
	}
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
    [urlTextField release];
	[subsites release], subsites = nil;
	[addUsersBlogsView release];
	[spinner release];
	[footerText release];
	[addButtonText release];
	[url release], url = nil;
	[xmlrpc release], xmlrpc = nil;
	[username release], username = nil;
	[password release], password = nil;
	[blogID release];
	[blogName release];
	[host release];
    [super dealloc];
}


@end

