//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "WPcomLoginViewController.h"


@implementation WPcomLoginViewController
@synthesize footerText, buttonText, username, password, isAuthenticated, isSigningIn, WPcomXMLRPCUrl, tableView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	//AddUsersBlogsViewController *addBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];

	
	footerText = @" ";
	buttonText = @"Sign In";
	WPcomXMLRPCUrl = @"https://wordpress.com/xmlrpc.php";
	self.navigationItem.title = @"Sign In";
	//addBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil)
		username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"] != nil)
		password = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"];
	
	if((![username isEqualToString:@""]) && (![password isEqualToString:@""]))
		[self authenticate];
	
	// Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wpcom";
	if(DeviceIsPad() == YES) {
		logoFile = @"logo_wpcom@2x.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	else if([UIDevice currentDevice].model == IPHONE_1G_NAMESTRING) {
		logoFile = @"logo_wpcom.png";
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
	self.tableView.backgroundColor = [UIColor clearColor];
	
	if(DeviceIsPad())
		self.tableView.backgroundView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	isSigningIn = NO;
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
				if(DeviceIsPad() == YES) {
					activityCell.textLabel.frame = CGRectMake(90, 4, 300, 40);
				}
				break;
			}
		}
	}
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:@"MyCell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if ([indexPath section] == 0) {
			CGRect textFrame = CGRectMake(110, 10, 185, 30);
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
					loginTextField.returnKeyType = UIReturnKeyDone;
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
	int foo = 0;
	switch (indexPath.section) {
		case 0:
			foo = 1;
			UITableViewCell *cell = (UITableViewCell *)[tv cellForRowAtIndexPath:indexPath];
			
			for(UIView *subview in cell.subviews) {
				if([subview isKindOfClass:[UITextField class]] == YES) {
					UITextField *tempTextField = (UITextField *)subview;
					[tempTextField becomeFirstResponder];
				}
			}
			break;
		case 1:
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
				isSigningIn = YES;
				[NSThread sleepForTimeInterval:0.15];
				[tv reloadData];
				
				[self performSelectorInBackground:@selector(signIn:) withObject:self];
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
	
	if((textField.tag == 1) && (username != nil) && (password != nil)) {
		isSigningIn = YES;
		[self refreshTable];
		[self performSelectorInBackground:@selector(signIn:) withObject:self];
	}
	
	return YES;	
}

- (void)textFieldDidEndEditing: (UITextField *) textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	switch (indexPath.row) {
		case 0:
			if([textField.text isEqualToString:@""]) {
				footerText = @"Username is required.";
			}
			else {
				username = textField.text;
				footerText = @" ";
			}
			break;
		case 1:
			if([textField.text isEqualToString:@""]) {
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
	if(![username isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"wpcom_username_preference"];
	if(![password isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:password forKey:@"wpcom_password_preference"];
	
	if(isAuthenticated)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
}

- (void)clearLoginData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_password_preference"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
}

- (BOOL)authenticate {
	if([[WPDataController sharedInstance] authenticateUser:WPcomXMLRPCUrl username:username password:password] == YES) {
		isAuthenticated = YES;
		[self saveLoginData];
	}
	else {
		isAuthenticated = NO;
		[self clearLoginData];
	}
	return isAuthenticated;
}

- (void)selectPasswordField:(id)sender {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	UITextField *textField = [cell.contentView.subviews objectAtIndex:0];
	[textField becomeFirstResponder];
}

- (void)signIn:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self authenticate];
	isSigningIn = NO;
	if(isAuthenticated) {
		[WordPressAppDelegate sharedWordPressApp].isWPcomAuthenticated = YES;
		if(DeviceIsPad() == YES) {
			//addBlogsView.isWPcom = YES;
//			[addBlogsView setUsername:self.username];
//			[addBlogsView setPassword:self.password];
//			[self.navigationController pushViewController:addBlogsView animated:YES];
		}
		else {
			[super dismissModalViewControllerAnimated:YES];
		}
	}
	else {
		footerText = @"Sign in failed. Please try again.";
		buttonText = @"Sign In";
		[self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
	}
	
	[pool release];
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
	WPcomXMLRPCUrl = nil;
	[WPcomXMLRPCUrl release];
    [super dealloc];
}


@end

