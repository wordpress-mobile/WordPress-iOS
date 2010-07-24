//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@implementation AddSiteViewController
@synthesize appDelegate, spinner, footerText, addButtonText, url, xmlrpc, username, password;
@synthesize isAuthenticating, isAuthenticated, isAdding, hasSubsites;
@synthesize hasValidXMLRPCurl, blogID, blogName, host;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	hasValidXMLRPCurl = YES;	// Assume true until proven wrong.
	addButtonText = @"Add Site";
	self.navigationItem.title = @"Add Site";
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	
	// Setup WPorg table header
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg"]];
	logo.frame = CGRectMake(40, 20, 229, 43);
	[headerView addSubview:logo];
	self.tableView.tableHeaderView = headerView;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
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
				return 1;	// Select Subsites
			else
				return 0;	// (invisible)
			break;
		case 2:
			return 1;		// Settings
			break;
		case 3:
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
					addTextField.placeholder = @"http://myexamplesite.com";
					addTextField.keyboardType = UIKeyboardTypeEmailAddress;
					addTextField.returnKeyType = UIReturnKeyDone;
					addTextField.tag = 0;
					if(url != nil)
						addTextField.text = url;
				}
				else if(indexPath.row == 1) {
					addTextField.placeholder = @"WordPress username.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					addTextField.tag = 1;
					if(username != nil)
						addTextField.text = username;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"WordPress password.";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					addTextField.secureTextEntry = YES;
					addTextField.tag = 1;
					if(password != nil)
						addTextField.text = password;
				}
				else if(indexPath.row == 2) {
					addTextField.placeholder = @"http://myexamplesite.com/xmlrpc.php";
					addTextField.keyboardType = UIKeyboardTypeDefault;
					addTextField.returnKeyType = UIReturnKeyDone;
					addTextField.tag = 1;
					if(xmlrpc != nil)
						addTextField.text = xmlrpc;
				}
			}           
			addTextField.backgroundColor = [UIColor whiteColor];
			addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
			addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			addTextField.textAlignment = UITextAlignmentLeft;
			addTextField.delegate = self;
			
			addTextField.clearButtonMode = UITextFieldViewModeNever;
			[addTextField setEnabled: YES];
			
			[cell addSubview:addTextField];
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
		if(hasSubsites) {
			cell.textLabel.text = @"Select Sites";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", subsites.count];
		}
	}
	else if(indexPath.section == 2) {
		cell.textLabel.text = @"Settings";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if(indexPath.section == 3) {
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
			// Sub sites
			[tv deselectRowAtIndexPath:indexPath animated:YES];
			break;
		case 2:
			// Settings
			[tv deselectRowAtIndexPath:indexPath animated:YES];
			break;
		case 3:
			// Add Site
			footerText = nil;
			addButtonText = @"Adding Site...";
			isAdding = YES;
			[tv deselectRowAtIndexPath:indexPath animated:YES];
			[NSThread sleepForTimeInterval:0.15];
			[tv reloadData];
			
			[self performSelectorInBackground:@selector(addSite) withObject:nil];
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

- (void) textFieldDidEndEditing: (UITextField *) textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if([textField.text isEqualToString:@""])
				footerText = @"URL is required.";
			else {
				url = textField.text;
				footerText = nil;
				[self performSelectorInBackground:@selector(getXMLRPCurl) withObject:nil];
			}
			break;
		case 1:
			if([textField.text isEqualToString:@""])
				footerText = @"Username is required.";
			else {
				username = textField.text;
				footerText = nil;
			}
			break;
		case 2:
			if([textField.text isEqualToString:@""])
				footerText = @"Password is required.";
			else {
				password = textField.text;
				footerText = nil;
			}
			break;
		case 3:
			if((!hasValidXMLRPCurl) && ([textField.text isEqualToString:@""]))
				footerText = @"XMLRPC endpoint wasn't found. Please enter it manually.";
			else {
				xmlrpc = textField.text;
				hasValidXMLRPCurl = YES;
				footerText = nil;
			}
			break;
		default:
			break;
	}
	
	[self.tableView reloadData];
	
	if((url != nil) && (username != nil) && (password != nil) && (xmlrpc != nil)) {
		[self authenticate];
	}
}

#pragma mark -
#pragma mark Custom methods

- (void)getSubsites {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	footerText = @"Checking for sub sites...";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	@try {
		subsites = [[WPDataController sharedInstance] getBlogsForUrl:xmlrpc username:username password:password];
		[self didGetSubsitesSuccessfully];
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}
	@catch (NSException * e) {}
	@finally {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	[pool release];
}

- (void)didGetSubsitesSuccessfully {
	if(subsites.count > 1) {
		hasSubsites = YES;
	}
	else if(subsites.count == 1) {
		Blog *blog = [subsites objectAtIndex:0];
		host = blog.host;
		blogID = blog.blogID;
		blogName = blog.blogName;
	}
	footerText = @"";
}

- (void)authenticate {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	footerText = @"Authenticating...";
	[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	
	isAuthenticated = [[WPDataController sharedInstance] authenticateUser:xmlrpc username:username password:password];
	if(isAuthenticated) {
		footerText = @"Authentication successful.";
		[self didAuthenticateSuccessfully];
	}
	else
		footerText = @"Authentication failed.";
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
		if(![url hasSuffix:@"/"])
			url = [NSString stringWithFormat:@"%@/", url];
		[self performSelectorOnMainThread:@selector(setXMLRPCUrl:) 
								withObject:[[NSString stringWithFormat:@"%@xmlrpc.php", url] retain]
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
	NSNumber *authEnabled = [NSNumber numberWithBool:NO];
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil] retain];
    if ([[BlogDataManager sharedDataManager] doesBlogExist:newBlog]) {
        return;
	}
	else {
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
		//[newBlog setValue:value forKey:kResizePhotoSetting];
		[newBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
		
		[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
        [newBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
        [[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
        [newBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[BlogDataManager sharedDataManager] setCurrentBlog:newBlog];
		[BlogDataManager sharedDataManager].currentBlogIndex = -1;
        [[BlogDataManager sharedDataManager] saveCurrentBlog];
	}
	
	[self performSelectorOnMainThread:@selector(didAddSiteSuccessfully) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didAddSiteSuccessfully {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[spinner dismiss];
	[self.navigationController popToRootViewControllerAnimated:YES];
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
	[blogID release];
	[blogName release];
	[host release];
	[appDelegate release];
	[spinner release];
	[footerText release];
	[addButtonText release];
	[url release];
	[xmlrpc release];
	[username release];
	[password release];
    [super dealloc];
}


@end

