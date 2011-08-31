//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "EditSiteViewController.h"
#import "NSURL+IDN.h"

@interface EditSiteViewController (PrivateMethods)
- (void)validateFields;
@end

@implementation EditSiteViewController
@synthesize password, username, url, geolocationEnabled;
@synthesize blog, tableView, savingIndicator;
@synthesize urlCell, usernameCell, passwordCell;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    if (blog) {
        [FlurryAPI logEvent:@"EditSite"];

        if([blog isWPcom] == YES) {
            self.navigationItem.title = NSLocalizedString(@"Edit Blog", @"");
        }
        else {
            self.navigationItem.title = NSLocalizedString(@"Edit Site", @"");
        }
		self.tableView.backgroundColor = [UIColor clearColor];
		if (DeviceIsPad()){
			self.tableView.backgroundView = nil;
			self.tableView.backgroundColor = [UIColor clearColor];
		}
		
		if (DeviceIsPad() && self.navigationItem.leftBarButtonItem == nil)
		{
			//add cancel button if editing an existing blog
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
		}

        NSError *error = nil;
        self.url = blog.url;
        self.username = blog.username;
        self.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.hostURL error:&error];
        self.geolocationEnabled = blog.geolocationEnabled;
    }
    
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    
    self.navigationItem.rightBarButtonItem = saveButton;	
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
            return 3;	// URL, username, password
		case 1:
            return 1;	// Settings
        case 2:
            // Overloaded in AddSiteViewController to hide dashboard link
            return 1;   // Dashboard
		default:
			break;
	}
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath section] == 0) {
        if (indexPath.row == 0) {
            self.urlCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UrlCell"];
            if (self.urlCell == nil) {
                self.urlCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UrlCell"] autorelease];
				self.urlCell.textLabel.text = NSLocalizedString(@"URL", @"");
				urlTextField = [self.urlCell.textField retain];
				urlTextField.placeholder = NSLocalizedString(@"http://example.com", @"");
				urlTextField.keyboardType = UIKeyboardTypeURL;
				urlTextField.returnKeyType = UIReturnKeyNext;
                urlTextField.delegate = self;
				if(blog.url != nil)
					urlTextField.text = blog.url;
            }
            
            return self.urlCell;
        }
        else if(indexPath.row == 1) {
            self.usernameCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
            if (self.usernameCell == nil) {
                self.usernameCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"] autorelease];
				self.usernameCell.textLabel.text = NSLocalizedString(@"Username", @"");
				usernameTextField = [self.usernameCell.textField retain];
				usernameTextField.placeholder = NSLocalizedString(@"WordPress username", @"");
				usernameTextField.keyboardType = UIKeyboardTypeDefault;
				usernameTextField.returnKeyType = UIReturnKeyNext;
                usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                usernameTextField.delegate = self;
				if(blog.username != nil)
					usernameTextField.text = blog.username;
			}
            
            return self.usernameCell;
        }
        else if(indexPath.row == 2) {
            self.passwordCell = (UITableViewTextFieldCell *)[tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
            if (self.passwordCell == nil) {
                self.passwordCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"] autorelease];
				self.passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
				passwordTextField = [self.passwordCell.textField retain];
				passwordTextField.placeholder = NSLocalizedString(@"WordPress password", @"");
				passwordTextField.keyboardType = UIKeyboardTypeDefault;
				passwordTextField.secureTextEntry = YES;
                passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                passwordTextField.delegate = self;
				if(password != nil)
					passwordTextField.text = password;
			}            
            return self.passwordCell;
        }				        
    } else if(indexPath.section == 1) {
        if(switchCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewSwitchCell" owner:nil options:nil];
            for(id currentObject in topLevelObjects)
            {
                if([currentObject isKindOfClass:[UITableViewSwitchCell class]])
                {
                    switchCell = (UITableViewSwitchCell *)currentObject;
                    break;
                }
            }
        }
        [switchCell retain];
        switchCell.textLabel.text = NSLocalizedString(@"Geotagging", @"Enables geotagging in blog settings (short label)");
        switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchCell.cellSwitch.on = self.geolocationEnabled;
        [switchCell.cellSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        return switchCell;
	} else if(indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DashboardCell"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DashboardCell"] autorelease];
        }
        cell.textLabel.text = NSLocalizedString(@"View dashboard", @"Button to load the dashboard in a web view");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        return cell;
    }
    
    // We shouldn't reach this point, but return an empty cell just in case
    return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"] autorelease];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	switch (section) {
		case 0:
			result = blog.blogName;
			break;
        case 1:
            result = NSLocalizedString(@"Settings", @"");
            break;
        case 2:
            result = NSLocalizedString(@"Advanced", @"");
            break;
		default:
			break;
	}
	return result;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
	if (indexPath.section == 0) {
        for(UIView *subview in cell.subviews) {
            if(subview.class == [UITextField class]) {
                [subview becomeFirstResponder];
                break;
            }
        }
	} else if (indexPath.section == 2) {
        WPWebViewController *webViewController;
        if (DeviceIsPad()) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
        [webViewController setUrl:[NSURL URLWithString:dashboardUrl]];
        [webViewController setUsername:self.username];
        [webViewController setPassword:self.password];
        if (DeviceIsPad())
            [self presentModalViewController:webViewController animated:YES];
        else
            [self.navigationController pushViewController:webViewController animated:YES];
        
    }
    [tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UITextField methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        UITableViewCell *cell = (UITableViewCell *)[textField superview];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
        UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        if (nextCell) {
            for (UIView *subview in [nextCell subviews]) {
                if ([subview isKindOfClass:[UITextField class]]) {
                    [subview becomeFirstResponder];
                    break;
                }
            }
        }
    }
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSMutableString *result = [NSMutableString stringWithString:textField.text];
    [result replaceCharactersInRange:range withString:string];

    if ([result length] == 0) {
        cell.textLabel.textColor = WRONG_FIELD_COLOR;
    } else {
        cell.textLabel.textColor = GOOD_FIELD_COLOR;        
    }
    
    return YES;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch(buttonIndex) {
		case 0: {
			HelpViewController *helpViewController = [[HelpViewController alloc] init];
			WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			if (DeviceIsPad()) {
				helpViewController.isBlogSetup = YES;
				[self.navigationController pushViewController:helpViewController animated:YES];
			}
			else
				[appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
			
			[helpViewController release];
			break;
		}
		case 1:
			//ok
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark Custom methods

- (void)toggleGeolocation:(id)sender {
    self.geolocationEnabled = switchCell.cellSwitch.on;
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (void)checkURL {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *urlToValidate = urlTextField.text;    
	
    if(![urlToValidate hasPrefix:@"http"])
        urlToValidate = [NSString stringWithFormat:@"http://%@", url];
	
    urlToValidate = [urlToValidate stringByReplacingOccurrencesOfRegex:@"/wp-login.php$" withString:@""];
    urlToValidate = [urlToValidate stringByReplacingOccurrencesOfRegex:@"/wp-admin/?$" withString:@""]; 
    urlToValidate = [urlToValidate stringByReplacingOccurrencesOfRegex:@"/?$" withString:@""]; 
	
    [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), urlToValidate];
	ASIHTTPRequest *xmlrpcRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlToValidate]];
	[xmlrpcRequest setValidatesSecureCertificate:NO]; 
	[xmlrpcRequest setShouldPresentCredentialsBeforeChallenge:NO];
	[xmlrpcRequest setShouldPresentAuthenticationDialog:YES];
	[xmlrpcRequest setUseKeychainPersistence:YES];
	[xmlrpcRequest setNumberOfTimesToRetryOnTimeout:2];
	[xmlrpcRequest setDidFinishSelector:@selector(remoteValidate:)];
	[xmlrpcRequest setDidFailSelector:@selector(checkURLWentWrong:)];
	[xmlrpcRequest setDelegate:self];
    NSString *version  = [[[NSBundle mainBundle] infoDictionary] valueForKey:[NSString stringWithFormat:@"CFBundleVersion"]];
	[xmlrpcRequest addRequestHeader:@"User-Agent" value:[NSString stringWithFormat:@"wp-iphone/%@",version]];
    [xmlrpcRequest addRequestHeader:@"Accept" value:@"*/*"];
    [xmlrpcRequest startAsynchronous];
	
	[xmlrpcRequest release];
  	[pool release];    
}


- (void)remoteValidate:(ASIHTTPRequest *)xmlrpcRequest
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	WPDataController *dc = [[WPDataController alloc] init];
    WPLog(@"before guess");
    NSString *xmlrpc = [dc guessXMLRPCForUrl:self.url];
    WPLog(@"after guess");
    [subsites release]; subsites = nil;
    if (xmlrpc != nil) {
        subsites = [[dc getBlogsForUrl:xmlrpc username:usernameTextField.text password:passwordTextField.text] retain];
        if (subsites != nil) {
            [self performSelectorOnMainThread:@selector(validationSuccess:) withObject:xmlrpc waitUntilDone:YES];
        } else {
            [self performSelectorOnMainThread:@selector(validationDidFail:) withObject:dc.error waitUntilDone:YES];
        }
    } else {
        [self performSelectorOnMainThread:@selector(validationDidFail:) withObject:dc.error waitUntilDone:YES];
    }
	
	[dc release];
	[pool release];  
}

- (void)checkURLWentWrong:(ASIHTTPRequest *)request {
	NSError *error = [request error];
	[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), error];
	[self performSelectorOnMainThread:@selector(validationDidFail:) withObject:error waitUntilDone:YES];
}



- (void)validationSuccess:(NSString *)xmlrpc {
	[savingIndicator stopAnimating];
	[savingIndicator setHidden:YES];
    blog.url = self.url;
    blog.xmlrpc = xmlrpc;
    blog.username = self.username;
    blog.geolocationEnabled = self.geolocationEnabled;
	NSError *error = nil;
	//check if the blog is a WP.COM blog
	if(blog.isWPcom) {
		[SFHFKeychainUtils storeUsername:blog.username
                             andPassword:self.password
                          forServiceName:@"WordPress.com"
                          updateExisting:YES
                                   error:&error];
	} else {
		[SFHFKeychainUtils storeUsername:blog.username
							 andPassword:self.password
						  forServiceName:blog.hostURL
						  updateExisting:YES
								   error:&error];
	}
	
    if (error) {
		[FileLogger log:@"%@ %@ Error saving password for %@: %@", self, NSStringFromSelector(_cmd), blog.url, error];
    } else {
		[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), blog.url];
	}
	if (DeviceIsPad())
		[self dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToRootViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    saveButton.enabled = YES;
	[self.navigationItem setHidesBackButton:NO animated:NO];
}

- (void)validationDidFail:(id)wrong {
	[savingIndicator stopAnimating];
	[savingIndicator setHidden:YES];
    if (wrong) {
        if ([wrong isKindOfClass:[UITableViewCell class]]) {
            ((UITableViewCell *)wrong).textLabel.textColor = WRONG_FIELD_COLOR;
        } else if ([wrong isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)wrong;
			NSString *message;
			if ([error code] == 403) {
				message = NSLocalizedString(@"Please update your credentials and try again.", @"");
			} else {
				message = [error localizedDescription];
			}

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
																message:message
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                      otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
            [alertView show];
            [alertView release];            
        }
    }    

    saveButton.enabled = YES;
	[self.navigationItem setHidesBackButton:NO animated:NO];
}

- (void)validateFields {
    self.url = [NSURL IDNEncodedHostname:urlTextField.text];
    NSLog(@"blog url: %@", self.url);
    self.username = usernameTextField.text;
    self.password = passwordTextField.text;
    
    saveButton.enabled = NO;
	[self.navigationItem setHidesBackButton:YES animated:NO];
    BOOL validFields = YES;
    if ([urlTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.urlCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([usernameTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.usernameCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    if ([passwordTextField.text isEqualToString:@""]) {
        validFields = NO;
        self.passwordCell.textLabel.textColor = WRONG_FIELD_COLOR;
    }
    
    if (validFields) {
        [self performSelectorInBackground:@selector(checkURL) withObject:nil];
    } else {
        [self validationDidFail:nil];
    }
}

- (void)save:(id)sender {
    [urlTextField resignFirstResponder];
    [usernameTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
	
	if (savingIndicator == nil) {
		savingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[savingIndicator setFrame:CGRectMake(0,0,20,20)];
		[savingIndicator setCenter:CGPointMake(tableView.center.x, savingIndicator.center.y)];
		UIView *aView = [[UIView alloc] init];
		[aView addSubview:savingIndicator];
		
		[self.tableView setTableFooterView:aView];
        [aView release];
	}
	[savingIndicator setHidden:NO];
	[savingIndicator startAnimating];

    if (blog) {
        blog.geolocationEnabled = self.geolocationEnabled;
        [blog dataSave];
    }
	
	if(blog == nil || blog.username == nil) {
		[self validateFields];
	} else 
		if ([self.username isEqualToString:usernameTextField.text]
			&& [self.password isEqualToString:passwordTextField.text]
			&& [self.url isEqualToString:urlTextField.text]) {
			// No need to check if nothing changed
			if (DeviceIsPad())
				[self dismissModalViewControllerAnimated:YES];
			else
				[self.navigationController popToRootViewControllerAnimated:YES];
		} else {
			[self validateFields];
		}
}

- (void)cancel:(id)sender {
	if (DeviceIsPad())
		[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    self.username = nil;
    self.password = nil;
    self.url = nil;
    self.urlCell = nil;
    self.usernameCell = nil;
    self.passwordCell = nil;
    self.tableView = nil;
    self.blog = nil;
    [subsites release]; subsites = nil;
    [saveButton release]; saveButton = nil;
    [switchCell release]; switchCell = nil;
    [urlTextField release]; urlTextField = nil;
    [usernameTextField release]; usernameTextField = nil;
    [passwordTextField release]; passwordTextField = nil;
	[savingIndicator release];
    [super dealloc];
}


@end

