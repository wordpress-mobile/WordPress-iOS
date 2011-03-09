//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "WPcomLoginViewController.h"

@interface WPcomLoginViewController(PrivateMethods)
- (void)saveLoginData;
- (BOOL)authenticate;
- (void)clearLoginData;
- (void)signIn:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)refreshTable;
- (void)didSignInSuccessfully;
@end


@implementation WPcomLoginViewController
@synthesize footerText, buttonText, username, password, isAuthenticated, isSigningIn, WPcomXMLRPCUrl, tableView, appDelegate;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    [FlurryAPI logEvent:@"WPcomLogin"];
	footerText = @" ";
	buttonText = @"Sign In";
	WPcomXMLRPCUrl = @"https://wordpress.com/xmlrpc.php";
	self.navigationItem.title = @"Sign In";
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil) {
        NSError *error = nil;
		username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        password = [SFHFKeychainUtils getPasswordForUsername:username
                                              andServiceName:@"WordPress.com"
                                                       error:&error];
    }
	
	if((![username isEqualToString:@""]) && (![password isEqualToString:@""]))
		[self authenticate];
	
	// Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wpcom.png";
	if(DeviceIsPad() == YES) {
		logoFile = @"logo_wpcom@2x.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	else if([[UIDevice currentDevice] platformString] == IPHONE_1G_NAMESTRING) {
		logoFile = @"logo_wpcom.png";
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
	
	if(DeviceIsPad())
		self.tableView.backgroundView = nil;
	
	self.tableView.backgroundColor = [UIColor clearColor];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationItem setHidesBackButton:NO animated:NO];
	isSigningIn = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
		return 2;
	else
		return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return footerText;
	else
		return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MyCell"];
	UITableViewActivityCell *activityCell = (UITableViewActivityCell *)[self.tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
	
	if((indexPath.section == 1) && (activityCell == nil)) {
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
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:@"MyCell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if ([indexPath section] == 0) {
			CGRect textFrame = CGRectMake(110, 12, 185, 30);
			if(DeviceIsPad()){
				textFrame = CGRectMake(150, 12, 350, 42);
			}
			UITextField *loginTextField = [[UITextField alloc] initWithFrame:textFrame];
			loginTextField.adjustsFontSizeToFitWidth = YES;
			loginTextField.textColor = [UIColor blackColor];
			if ([indexPath section] == 0) {
				if ([indexPath row] == 0) {
					loginTextField.placeholder = @"WordPress.com username";
					loginTextField.keyboardType = UIKeyboardTypeEmailAddress;
					loginTextField.returnKeyType = UIReturnKeyNext;
					loginTextField.tag = 0;
					loginTextField.delegate = self;
					if(username != nil)
						loginTextField.text = username;
				}
				else {
					loginTextField.placeholder = @"WordPress.com password";
					loginTextField.keyboardType = UIKeyboardTypeDefault;
					loginTextField.returnKeyType = UIReturnKeyDone;
					loginTextField.secureTextEntry = YES;
					loginTextField.tag = 1;
					loginTextField.delegate = self;
					if(password != nil)
						loginTextField.text = password;
				}
			}
			if(DeviceIsPad() == YES)
				loginTextField.backgroundColor = [UIColor clearColor];
			else
				loginTextField.backgroundColor = [UIColor whiteColor];
			loginTextField.autocorrectionType = UITextAutocorrectionTypeNo;
			loginTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			loginTextField.textAlignment = UITextAlignmentLeft;
			loginTextField.delegate = self;
			
			loginTextField.clearButtonMode = UITextFieldViewModeNever;
			[loginTextField setEnabled:YES];
			
			if(isSigningIn)
				[loginTextField resignFirstResponder];
			
			[cell addSubview:loginTextField];
			[loginTextField release];
		}
	}
	
	if (indexPath.section == 0) {
		if ([indexPath row] == 0) {
			cell.textLabel.text = @"Username";
		}
		else {
			cell.textLabel.text = @"Password";
		}
	}
	else if(indexPath.section == 1) {
		if(isSigningIn) {
			[activityCell.spinner startAnimating];
			buttonText = @"Signing In...";
		}
		else {
			[activityCell.spinner stopAnimating];
			buttonText = @"Sign In";
		}
		
		activityCell.textLabel.text = buttonText;
		cell = activityCell;
	}
	return cell;    
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];
		
	switch (indexPath.section) {
		case 0:
        {
			UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:indexPath];
			for(UIView *subview in cell.subviews) {
				if([subview isKindOfClass:[UITextField class]] == YES) {
					UITextField *tempTextField = (UITextField *)subview;
					[tempTextField becomeFirstResponder];
					break;
				}
			}
			break;
        }
		case 1:
			for(int i = 0; i < 2; i++) {
				UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
				for(UIView *subview in cell.subviews) {
					if([subview isKindOfClass:[UITextField class]] == YES) {
						UITextField *tempTextField = (UITextField *)subview;
						[self textFieldDidEndEditing:tempTextField];
					}
				}
			}
			if(username == nil) {
				footerText = @"Username is required.";
				buttonText = @"Sign In";
				[tv reloadData];
			}
			else if(password == nil) {
				footerText = @"Password is required.";
				buttonText = @"Sign In";
				[tv reloadData];
			}
			else {
				footerText = @" ";
				buttonText = @"Signing in...";
				
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				if (!isSigningIn){
					[self.navigationItem setHidesBackButton:YES animated:NO];
					isSigningIn = YES;
					[self performSelectorInBackground:@selector(signIn:) withObject:self];
				}
			}
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
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
            if((username != nil) && (password != nil)) {
                if (!isSigningIn){
                    isSigningIn = YES;
					[self.navigationItem setHidesBackButton:YES animated:NO];
                    [self refreshTable];
                    [self performSelectorInBackground:@selector(signIn:) withObject:self];
                }
            }
            break;
	}

	return YES;	
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				footerText = @"Username is required.";
			}
			else {
				username = [[NSString alloc] init];
				username = textField.text;
				username = [[[username stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString] retain];
				textField.text = username;
				footerText = @" ";
			}
			break;
		case 1:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				footerText = @"Password is required.";
			}
			else {
				password = textField.text;
				footerText = @" ";
			}
			break;
		default:
			break;
	}
	
	[self.tableView reloadData];
	[textField resignFirstResponder];
}

#pragma mark -
#pragma mark Custom methods

- (void)saveLoginData {
    if (isAuthenticated) {
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:username
                             andPassword:password
                          forServiceName:@"WordPress.com"
                          updateExisting:YES
                                   error:&error];

        if (error) {
            NSLog(@"Error storing wpcom credentials: %@", [error localizedDescription]);
        }
    }
	if(![username isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"wpcom_username_preference"];

	if(isAuthenticated)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearLoginData {
    NSError *error = nil;
    [SFHFKeychainUtils deleteItemForUsername:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
                              andServiceName:@"WordPress.com"
                                       error:&error];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)authenticate {
	if([[WPDataController sharedInstance] authenticateUser:WPcomXMLRPCUrl username:username password:password] == YES) {
		isAuthenticated = YES;
		[self saveLoginData];
		
		// Register this device for push notifications with WordPress.com if necessary
		[[WPDataController sharedInstance] registerForPushNotifications];
	}
	else {
		isAuthenticated = NO;
		[self clearLoginData];
	}
	return isAuthenticated;
}

- (void)signIn:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self authenticate];
	if(isAuthenticated) {
		[WordPressAppDelegate sharedWordPressApp].isWPcomAuthenticated = YES;
		[self performSelectorOnMainThread:@selector(didSignInSuccessfully) withObject:nil waitUntilDone:NO];
	}
	else {
		footerText = @"Sign in failed. Please try again.";
		buttonText = @"Sign In";
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
		isSigningIn = NO;
		[self.navigationItem setHidesBackButton:NO animated:NO];
		[self refreshTable];
	}
	[pool release];
}

- (void)didSignInSuccessfully {
	if(DeviceIsPad() == YES) {
		AddUsersBlogsViewController *addBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController-iPad" bundle:nil];
		addBlogsView.isWPcom = YES;
		[addBlogsView setUsername:self.username];
		[addBlogsView setPassword:self.password];
		[self.navigationController pushViewController:addBlogsView animated:YES];
		[addBlogsView release];
	}
	else {
		[super dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)cancel:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"didCancelWPcomLogin" object:nil];
	[self dismissModalViewControllerAnimated:YES];
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
	[tableView release];
	[footerText release];
	[buttonText release];
	[username release];
	[password release];
	[WPcomXMLRPCUrl release];
    [super dealloc];
}


@end

