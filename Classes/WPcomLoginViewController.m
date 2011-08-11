//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "WPcomLoginViewController.h"
#import "UITableViewTextFieldCell.h"

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
@synthesize footerText, buttonText, username, password, isAuthenticated, isSigningIn, WPcomXMLRPCUrl, tableView, appDelegate, isStatsInitiated;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    [FlurryAPI logEvent:@"WPcomLogin"];
	self.footerText = @" ";
	self.buttonText = NSLocalizedString(@"Sign In", @"");
	WPcomXMLRPCUrl = @"https://wordpress.com/xmlrpc.php";
	self.navigationItem.title = NSLocalizedString(@"Sign In", @"");
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil) {
        NSError *error = nil;
		self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        self.password = [SFHFKeychainUtils getPasswordForUsername:username
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
	UITableViewCell *cell = nil;
	
	if(indexPath.section == 1) {
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[UITableViewActivityCell class]])
			{
				activityCell = (UITableViewActivityCell *)currentObject;
				break;
			}
		}
        if(isSigningIn) {
			[activityCell.spinner startAnimating];
			self.buttonText = NSLocalizedString(@"Signing In...", @"");
		}
		else {
			[activityCell.spinner stopAnimating];
			self.buttonText = NSLocalizedString(@"Sign In", @"");
		}
		
		activityCell.textLabel.text = buttonText;
		cell = activityCell;
	} else {
		UITableViewTextFieldCell *loginCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                           reuseIdentifier:@"TextCell"] autorelease];
		
				if ([indexPath row] == 0) {
                    loginCell.textLabel.text = NSLocalizedString(@"Username", @"");
					loginCell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
					loginCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
					loginCell.textField.returnKeyType = UIReturnKeyNext;
					loginCell.textField.tag = 0;
					loginCell.textField.delegate = self;
					if(username != nil)
						loginCell.textField.text = username;
				}
				else {
                    loginCell.textLabel.text = NSLocalizedString(@"Password", @"");
					loginCell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
					loginCell.textField.keyboardType = UIKeyboardTypeDefault;
					loginCell.textField.secureTextEntry = YES;
					loginCell.textField.tag = 1;
					loginCell.textField.delegate = self;
					if(password != nil)
						loginCell.textField.text = password;
				}
			loginCell.textField.delegate = self;
			
			if(isSigningIn)
				[loginCell.textField resignFirstResponder];

        cell = loginCell;
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
				self.footerText = NSLocalizedString(@"Username is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else if(password == nil) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
				self.buttonText = NSLocalizedString(@"Sign In", @"");
				[tv reloadData];
			}
			else {
				self.footerText = @" ";
				self.buttonText = NSLocalizedString(@"Signing in...", @"");
				
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
				self.footerText = NSLocalizedString(@"Username is required.", @"");
			}
			else {
				self.username = [[textField.text stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
				textField.text = self.username;
			}
			break;
		case 1:
			if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
				self.footerText = NSLocalizedString(@"Password is required.", @"");
			}
			else {
				self.password = textField.text;
			}
			break;
		default:
			break;
	}
	
//	[self.tableView reloadData];
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
		self.footerText = NSLocalizedString(@"Sign in failed. Please try again.", @"");
		self.buttonText = NSLocalizedString(@"Sign In", @"");
		isSigningIn = NO;
		[self.navigationItem setHidesBackButton:NO animated:NO];
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}
	[pool release];
}

- (void)didSignInSuccessfully {
	if(DeviceIsPad() == YES && !isStatsInitiated) {
		AddUsersBlogsViewController *addBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController-iPad" bundle:nil];
		addBlogsView.isWPcom = YES;
		[addBlogsView setUsername:self.username];
		[addBlogsView setPassword:self.password];
		[self.navigationController pushViewController:addBlogsView animated:YES];
		[addBlogsView release];
	}
	else {
        if (DeviceIsPad())
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didDismissWPcomLogin" object:nil];
		[super dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)cancel:(id)sender {
    if (DeviceIsPad())
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didDismissWPcomLogin" object:nil];
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
    self.footerText = nil;
    self.buttonText = nil;
	[username release];
	[password release];
	[WPcomXMLRPCUrl release];
    [super dealloc];
}


@end

