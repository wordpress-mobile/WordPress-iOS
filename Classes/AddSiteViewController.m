//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@interface AddSiteViewController(PrivateMethods)
- (void)getSubsites;
- (void)didGetSubsitesSuccessfully:(NSArray *)subsites;
- (void)authenticate;
- (void)didAuthenticateSuccessfully;
- (void)didFailAuthentication;
- (void)addSite;
- (void)didAddSiteSuccessfully;
- (void)addSiteFailed;
- (void)refreshTable;
- (void)getXMLRPCurl;
- (void) updateUIAfterXMLRPCFails:(NSString *)errorMsg;
- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl;
- (void)verifyXMLRPCurl:(NSString *)xmlrpcURL;
- (BOOL)blogExists;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)urlDidChange;
@end


@implementation AddSiteViewController
@synthesize spinner, footerText, addButtonText, url, xmlrpc, username, password, tableView;
@synthesize isAuthenticating, isAuthenticated, isAdding, hasSubsites, subsites, viewDidMove, keyboardIsVisible;
@synthesize hasValidXMLRPCurl, addUsersBlogsView, activeTextField, blogID, host, blogName, hasCheckedForSubsites;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"AddSite"];
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
				textFrame = CGRectMake(150, 12, 350, 22);
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
		case 1: //settings or blogs cell
			if(isAdding == NO) {
				if((hasSubsites) && (indexPath.row == 0)) {
					// Select Sites
					[self.navigationController pushViewController:addUsersBlogsView animated:YES];
					[tv deselectRowAtIndexPath:indexPath animated:YES];
				}
				else if(((!hasSubsites) && (indexPath.row == 0)) || (indexPath.row == 1)) {
					// Settings
					if(url != nil)
						[appDelegate.currentBlog setValue:url forKey:@"url"];
					if(username != nil)
						[appDelegate.currentBlog setValue:username forKey:@"username"];
					if(activeTextField != nil) {
						[activeTextField becomeFirstResponder];
						[activeTextField resignFirstResponder];
					}

					// FIXME: change "Settings" button to Geolocation
//					BlogSettingsViewController *settingsView;
//					if(DeviceIsPad())
//						settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController-iPad" bundle:nil];
//					else
//						settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController" bundle:nil];
//					[self.navigationController pushViewController:settingsView animated:YES];
//					[settingsView release];
					
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

					if(isAuthenticated == NO) {
						[self performSelectorInBackground:@selector(getXMLRPCUrl) withObject:nil];
					}
					else {
						[tv deselectRowAtIndexPath:indexPath animated:YES];
                        [self addSite];
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
	if (results != nil) {
		[self setSubsites:results];
		NSLog(@"results: %@", results);
        if (results.count > 1) {
            hasSubsites = YES;
            [addUsersBlogsView setUrl:xmlrpc];
            [addUsersBlogsView setUsername:username];
            [addUsersBlogsView setPassword:password];
        }
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
		if(isAdding)
            [self addSite];
	}
	@catch (NSException * e) {
		NSLog(@"Error adding site: %@", e);
	}
	
	[self refreshTable];
}

- (void)authenticate {
	isAuthenticating = YES;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((username != nil) && (password != nil) && (![username isEqualToString:@""]) && (![password isEqualToString:@""])) {
		footerText = @"Authenticating...";
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];

		if(xmlrpc != nil) {
			isAuthenticated = [[WPDataController sharedInstance] authenticateUser:xmlrpc username:username password:password];
			if(isAuthenticated == YES) {
				footerText = @"Authenticated successfully.";
				[self performSelectorOnMainThread:@selector(didAuthenticateSuccessfully) withObject:nil waitUntilDone:NO];
			}
			else {
				isAdding = NO;
				addButtonText = @"Add Blog";
				footerText = @"Connection error.";
				[self performSelectorOnMainThread:@selector(didFailAuthentication) withObject:nil waitUntilDone:NO];
			}
		}
		else {
			footerText = @"XML-RPC endpoint not found. Please enter it manually.";
			isAdding = NO;
			addButtonText = @"Add Blog";
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


- (void)didAuthenticateSuccessfully {
    isAuthenticating = NO;
	if((isAdding == NO) || ((username == nil) || (password == nil) || (xmlrpc == nil) || (hasCheckedForSubsites == NO)))
		[self performSelectorInBackground:@selector(getSubsites) withObject:nil];
	else if((username != nil) && (password != nil) && (xmlrpc != nil))
        [self addSite];
}

- (void)didFailAuthentication {
    isAuthenticating = NO;
    [self refreshTable];
}


- (void)getXMLRPCUrl {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((self.url != nil) && (![url isEqualToString:@""])) {
		if(![self.url hasPrefix:@"http"])
			self.url = [NSString stringWithFormat:@"http://%@", self.url];
	}

	
	// wp-admin convenience check
	if([self.url hasSuffix:@"/wp-admin"])
		self.url = [self.url stringByReplacingOccurrencesOfString:@"/wp-admin" withString:@""];
	
	// Start by just trying URL + /xmlrpc.php
	NSString *xmlrpcURL = [self.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if(![xmlrpcURL hasSuffix:@"/"])
		xmlrpcURL = [NSString stringWithFormat:@"%@/xmlrpc.php", xmlrpcURL];
	else
		xmlrpcURL = [NSString stringWithFormat:@"%@xmlrpc.php", xmlrpcURL];
	
	ASIHTTPRequest *xmlrpcRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:xmlrpcURL]];
	[xmlrpcRequest setValidatesSecureCertificate:NO]; 
	[xmlrpcRequest setShouldPresentCredentialsBeforeChallenge:NO];
	[xmlrpcRequest setShouldPresentAuthenticationDialog:YES];
	[xmlrpcRequest setUseKeychainPersistence:YES];
	[xmlrpcRequest setDidFinishSelector:@selector(getXMLRPCUrlDone:)];
	[xmlrpcRequest setDidFailSelector:@selector(getXMLRPCUrlWentWrong:)];
	[xmlrpcRequest setDelegate:self];
	[xmlrpcRequest startAsynchronous];

	[pool release];
}



- (void)getXMLRPCUrlDone:(ASIHTTPRequest *)xmlrpcRequest
{
	NSString *responseString = [xmlrpcRequest responseString];
	
	if([responseString rangeOfString:@"XML-RPC server accepts POST requests only."].location != NSNotFound){
		[self verifyXMLRPCurl:[xmlrpcRequest.url absoluteString]];
	}
	else {
		
		// We're looking for: <link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://myblog.com/xmlrpc.php?rsd" />
		NSString *rsdURL = [responseString stringByMatching:@"<link rel=\"EditURI\" type=\"application/rsd\\+xml\" title=\"RSD\" href=\"([^\"]*)\"[^/]*/>" capture:1];
		
		// We found a valid RSD document, now try to parse the XML
		NSError *rsdError;
		if(rsdURL != nil) {
			CXMLDocument *rsdXML = [[[CXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:rsdURL] options:CXMLDocumentTidyXML error:&rsdError] autorelease];
			if(!rsdError) {
				@try{
					CXMLElement *serviceXML = [[[rsdXML rootElement] children] objectAtIndex:1];
					for(CXMLElement *api in [[[serviceXML elementsForName:@"apis"] objectAtIndex:0] elementsForName:@"api"]) {
						if([[[api attributeForName:@"name"] stringValue] isEqualToString:@"WordPress"]) {
							// Bingo! We found the WordPress XML-RPC element
							[self verifyXMLRPCurl:[[api attributeForName:@"apiLink"] stringValue]];
							break;
						}
					}
				}@catch (NSException *ex) {
					[self updateUIAfterXMLRPCFails:@"XML-RPC endpoint not found. Please enter it manually."];
				}
				@finally {
					
				}				
			}
			else {
				// RSD document was invalid
				[self updateUIAfterXMLRPCFails:[rsdError localizedDescription]];
			}
		}
		else {
			[self updateUIAfterXMLRPCFails:@"XML-RPC endpoint not found. Please enter it manually."];
		}
	}
}

- (void)getXMLRPCUrlWentWrong:(ASIHTTPRequest *)request {
	NSError *error = [request error];
	NSString *errorMessage = [error localizedDescription];
	WPLog(@"getXMLRPCUrlWentWrong %@", errorMessage);
	[self updateUIAfterXMLRPCFails:@"XML-RPC endpoint not found. Please enter it manually."];
}


- (void) updateUIAfterXMLRPCFails:(NSString *)errorMsg {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	footerText = errorMsg;
	isAdding = NO;
	addButtonText = @"Add Blog";
	self.hasValidXMLRPCurl = NO;
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];

}

- (void)verifyXMLRPCurl:(NSString *)xmlrpcURL {
	WPLog(@"verifyXMLRPCurl: %@", xmlrpcURL);
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
        //WPLog(@"verified xmlrpc (%@): %@", xmlrpcURL, [xmlrpcRequest responseString]);
		CXMLDocument *xml = [[[CXMLDocument alloc] initWithXMLString:[xmlrpcRequest responseString] options:CXMLDocumentTidyXML error:nil] autorelease];
		NSArray *xmlrpcMethods = [xml nodesForXPath:@"//params/param/value/array/data/*" error:nil];
		if(xmlrpcMethods.count > 0) {
			self.hasValidXMLRPCurl = YES;
			self.xmlrpc = xmlrpcURL;
			[self authenticate];
		}
		else {
			[self updateUIAfterXMLRPCFails:@"Invalid XML-RPC response. Please, check your blog configuration."];
		}
	}
	else {
		[self updateUIAfterXMLRPCFails:@"Invalid XML-RPC response. Please, check your blog configuration."];
	}
	[xmlrpcRequest release];
}


- (BOOL)blogExists {
	WPLog(@"blogExists");
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
		WPLog(@"addSite");
    if (hasSubsites) {
        [self.navigationController pushViewController:addUsersBlogsView animated:YES];
        isAdding = NO;
        return;
    }

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[spinner show];

	NSMutableDictionary *newBlog = [subsites objectAtIndex:0];
    [newBlog setObject:username forKey:@"username"];
    [newBlog setObject:password forKey:@"password"];

	NSLog(@"saving newBlog: %@", newBlog);
    [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
    [FlurryAPI logEvent:@"AddSite#NewBlog"];
    NSError *error = nil;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }

	[self didAddSiteSuccessfully];
	[pool release];
}

- (void)didAddSiteSuccessfully {
	WPLog(@"didAddSiteSuccessfully");
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
	WPLog(@"addSiteFailed");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[self refreshTable];
}

- (void)refreshTable {
	WPLog(@"refreshTable");
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

