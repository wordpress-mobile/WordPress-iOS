//
//  WPcomLoginViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "WPcomLoginViewController.h"


@implementation WPcomLoginViewController
@synthesize footerText, buttonText, username, password, isAuthenticated, isSigningIn, WPcomXMLRPCUrl, tableView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	footerText = @" ";
	buttonText = @"Sign In";
	WPcomXMLRPCUrl = @"https://wordpress.com/xmlrpc.php";
	self.navigationItem.title = @"Sign In";
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsername"] != nil)
		username = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsername"];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomPassword"] != nil)
		password = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomPassword"];
	
	if((![username isEqualToString:@""]) && (![password isEqualToString:@""]))
		[self authenticate];
	
	// Setup WPcom table header
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wpcom.png"]];
	logo.frame = CGRectMake(40, 20, 229, 43);
	[headerView addSubview:logo];
	self.tableView.tableHeaderView = headerView;
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
				break;
			}
		}
	}
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:@"MyCell"] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if ([indexPath section] == 0) {
			UITextField *loginTextField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
			loginTextField.adjustsFontSizeToFitWidth = YES;
			loginTextField.textColor = [UIColor blackColor];
			if ([indexPath section] == 0) {
				if ([indexPath row] == 0) {
					loginTextField.placeholder = @"WordPress.com username";
					loginTextField.keyboardType = UIKeyboardTypeEmailAddress;
					loginTextField.returnKeyType = UIReturnKeyNext;
					loginTextField.tag = 0;
					if(username != nil)
						loginTextField.text = username;
				}
				else {
					loginTextField.placeholder = @"WordPress.com password";
					loginTextField.keyboardType = UIKeyboardTypeDefault;
					loginTextField.returnKeyType = UIReturnKeyDone;
					[loginTextField addTarget:self
									   action:@selector(signIn:)
							 forControlEvents:UIControlEventEditingDidEndOnExit];
					loginTextField.secureTextEntry = YES;
					loginTextField.tag = 1;
					if(password != nil)
						loginTextField.text = password;
				}
			}           
			loginTextField.backgroundColor = [UIColor whiteColor];
			loginTextField.autocorrectionType = UITextAutocorrectionTypeNo;
			loginTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			loginTextField.textAlignment = UITextAlignmentLeft;
			loginTextField.delegate = self;
			
			loginTextField.clearButtonMode = UITextFieldViewModeNever;
			[loginTextField setEnabled: YES];
			
			[cell addSubview:loginTextField];
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
		if(isSigningIn)
			[activityCell.spinner startAnimating];
		else
			[activityCell.spinner stopAnimating];
		
		activityCell.textLabel.text = buttonText;
		cell = activityCell;
	}
	return cell;    
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 1:
			if(username == nil) {
				footerText = @"Username is required.";
				buttonText = @"Sign In";
				[tv deselectRowAtIndexPath:indexPath animated:YES];
				[tv reloadData];
			}
			else if(password == nil) {
				footerText = @"Password is required.";
				buttonText = @"Sign In";
				[tv deselectRowAtIndexPath:indexPath animated:YES];
				[tv reloadData];
			}
			else {
				footerText = @" ";
				buttonText = @"Signing in...";
				isSigningIn = YES;
				[tv deselectRowAtIndexPath:indexPath animated:YES];
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
	return YES;	
}

- (void) textFieldDidEndEditing: (UITextField *) textField {
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
}

#pragma mark -
#pragma mark Custom methods

- (void)saveLoginData {
	if(![username isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"WPcomUsername"];
	if(![password isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:password forKey:@"WPcomPassword"];
	
	if(isAuthenticated)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"isWPcomAuthenticated"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"isWPcomAuthenticated"];
}

- (void)clearLoginData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WPcomUsername"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WPcomPassword"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"isWPcomAuthenticated"];
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
	[indexPath release];
}

- (void)signIn:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self authenticate];
	isSigningIn = NO;
	if(isAuthenticated) {
		[WordPressAppDelegate sharedWordPressApp].isWPcomAuthenticated = YES;
		[self dismissModalViewControllerAnimated:YES];
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
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
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

