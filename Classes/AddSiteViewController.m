//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@implementation AddSiteViewController
@synthesize spinner, footerText, addButtonText, url, xmlrpc, username, password;
@synthesize isAuthenticating, isAuthenticated, isAdding, hasSubsites, subsites;
@synthesize hasValidXMLRPCurl, blogID, blogName, host, addUsersBlogsView;

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
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg"]];
	logo.frame = CGRectMake(40, 20, 229, 43);
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
}

- (void)viewWillAppear:(BOOL)animated {
	if(appDelegate.currentBlog == nil)
		appDelegate.currentBlog = [[NSMutableDictionary alloc] init];
	else {
		NSLog(@"appDelegate.currentBlog.geotagging: %@", [appDelegate.currentBlog valueForKey:@"geotagging"]);
		NSLog(@"appDelegate.currentBlog.resize: %@", [appDelegate.currentBlog valueForKey:kResizePhotoSetting]);
		NSLog(@"appDelegate.currentBlog.postsdownload: %@", [appDelegate.currentBlog valueForKey:kPostsDownloadCount]);
		NSLog(@"appDelegate.currentBlog.authenabled: %@", [appDelegate.currentBlog valueForKey:@"authEnabled"]);
	}

}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
			UITextField *addTextField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
			addTextField.adjustsFontSizeToFitWidth = YES;
			addTextField.textColor = [UIColor blackColor];
			if ([indexPath section] == 0) {
				if (indexPath.row == 0) {
					addTextField.placeholder = @"http://myawesomesite.com";
					addTextField.keyboardType = UIKeyboardTypeEmailAddress;
					addTextField.returnKeyType = UIReturnKeyNext;
					if(url != nil)
						addTextField.text = url;
				}
				else if(indexPath.row == 1) {
					addTextField.placeholder = @"WordPress username.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyNext;
					if(username != nil)
						addTextField.text = username;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"WordPress password.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					if(xmlrpc != nil)
						addTextField.returnKeyType = UIReturnKeyDone;
					else
						addTextField.returnKeyType = UIReturnKeyNext;
					addTextField.secureTextEntry = YES;
					if(password != nil)
						addTextField.text = password;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"http://myawesomesite.com/xmlrpc.php";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					if(xmlrpc != nil)
						addTextField.text = xmlrpc;
				}
				
				addTextField.tag = indexPath.row;
				addTextField.backgroundColor = [UIColor whiteColor];
				addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
				addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				addTextField.textAlignment = UITextAlignmentLeft;
				addTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
				addTextField.delegate = self;
				
				addTextField.clearButtonMode = UITextFieldViewModeNever;
				[addTextField setEnabled: YES];
				
				[cell addSubview:addTextField];
				[addTextField release];
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
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.text = addButtonText;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
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
				BlogSettingsViewController *settingsView = [[BlogSettingsViewController alloc] initWithNibName:@"BlogSettingsViewController" bundle:nil];
				[self.navigationController pushViewController:settingsView animated:YES];
				[settingsView release];
				
				[tv deselectRowAtIndexPath:indexPath animated:YES];
			}
			break;
		case 2:
			// Add Site
			if(![self blogExists]) {
				footerText = @" ";
				addButtonText = @"Adding Site...";
				isAdding = YES;
				[tv deselectRowAtIndexPath:indexPath animated:YES];
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				
				[self performSelectorInBackground:@selector(addSite) withObject:nil];
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

- (void)textFieldDidEndEditing: (UITextField *) textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if(((username != nil) && (password != nil)) && ([textField.text isEqualToString:@""]))
				footerText = @"URL is required.";
			else {
				[self setUrl:textField.text];
				footerText = nil;
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
			if(((!hasValidXMLRPCurl) && (username != nil) && (password != nil)) && ([textField.text isEqualToString:@""]))
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
	
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Custom methods

- (void)getSubsites {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	footerText = @"Checking for sites...";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	subsites = [[WPDataController sharedInstance] getBlogsForUrl:xmlrpc username:username password:password];
	if(subsites.count > 1) {
		hasSubsites = YES;
		[addUsersBlogsView setUrl:xmlrpc];
		[addUsersBlogsView setUsername:username];
		[addUsersBlogsView setPassword:password];
	}
	else if(subsites.count == 1) {
		Blog *blog = [subsites objectAtIndex:0];
		host = blog.host;
		blogID = blog.blogID;
		blogName = blog.blogName;
	}
	
	if(![self blogExists]) {
		if(isAuthenticated) 
			footerText = @"Good to go.";
		else
			footerText = @"";
	}
	else
		footerText = @"Site has already been added.";
	
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
	[self getSubsites];
}

- (void)getXMLRPCurl {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if((url != nil) && (![url isEqualToString:@""])) {
		if(![url hasPrefix:@"http"])
			url = [NSString stringWithFormat:@"http://%@", url];
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
		
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}
	 
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
	xmlrpc = xmlrpcUrl;
}

- (void)addSite {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[spinner show];
	
	[self performSelectorInBackground:@selector(addSiteInBackground) withObject:nil];
}

- (void)addSiteInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *authUsername = username;
	NSString *authPassword = password;
	NSNumber *authEnabled = [appDelegate.currentBlog valueForKey:@"authEnabled"];
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil] retain];
	
	[[BlogDataManager sharedDataManager] resetCurrentBlog];
	
	[newBlog setValue:blogID forKey:kBlogId];
	[newBlog setValue:host forKey:kBlogHostName];
	[newBlog setValue:blogName forKey:@"blogName"];
	[newBlog setValue:url forKey:@"url"];
	[newBlog setValue:xmlrpc forKey:@"xmlrpc"];
	[newBlog setValue:username forKey:@"username"];
	[newBlog setValue:authEnabled forKey:@"authEnabled"];
	[[BlogDataManager sharedDataManager] updatePasswordInKeychain:password andUserName:username andBlogURL:host];
	
	[newBlog setValue:authUsername forKey:@"authUsername"];
	[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
													  andUserName:authUsername
													   andBlogURL:authBlogURL];
	[newBlog setValue:[appDelegate.currentBlog valueForKey:kResizePhotoSetting] forKey:kResizePhotoSetting];
	[newBlog setValue:[appDelegate.currentBlog valueForKey:kPostsDownloadCount] forKey:kResizePhotoSetting];
	[newBlog setValue:[appDelegate.currentBlog valueForKey:kGeolocationSetting] forKey:kGeolocationSetting];
	[newBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
	
	[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
	[newBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
	[newBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
	[[BlogDataManager sharedDataManager] setCurrentBlog:newBlog];
	[BlogDataManager sharedDataManager].currentBlogIndex = -1;
	[[BlogDataManager sharedDataManager] saveCurrentBlog];
	[[BlogDataManager sharedDataManager] syncCategoriesForBlog:newBlog];
	[[BlogDataManager sharedDataManager] syncStatusesForBlog:newBlog];
	[newBlog release];
	
	[self performSelectorOnMainThread:@selector(didAddSiteSuccessfully) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didAddSiteSuccessfully {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[appDelegate syncBlogs];
	[self.navigationController popToRootViewControllerAnimated:YES];
	appDelegate.currentBlog = nil;
	
	[pool release];
}

- (void)addSiteFailed {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)refreshTable {
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
	[subsites release];
	subsites = nil;
	[addUsersBlogsView release];
	[blogID release];
	[blogName release];
	[host release];
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
    [super dealloc];
}


@end

