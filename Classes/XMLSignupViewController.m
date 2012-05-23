//
//  XMLSignupViewController.m
//  WordPress
//
//  Created by Brad Angelcyk on 8/17/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "XMLSignupViewController.h"
#import "UITableViewTextFieldCell.h"

@interface XMLSignupViewController(PrivateMethods)
- (void)backgroundTap:(id)sender;
- (void)scrollViewToCenter;
- (void)tosButtonPressed;
- (void)saveLoginData;
- (void)xmlrpcCreateAccount;
- (void)refreshTable;
- (void)createBlog;
@end

@implementation XMLSignupViewController
@synthesize buttonText, footerText, blogName, email, username, password, passwordconfirm;
@synthesize tableView;
@synthesize lastTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
       
    appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self setFooterText:@" "];
    
    // set up table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wpcom.png";
	if(DeviceIsPad() == YES) {
		logoFile = @"logo_wpcom@2x.png";
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
    
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;

    UIButton *footerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [footerButton setFrame:CGRectMake(0, 0, 320, 20)];
    [footerButton setTitle:NSLocalizedString(@"You agree to the fascinating terms\nof service by submitting this form.", @"") forState:UIControlStateNormal];
    [footerButton.titleLabel setLineBreakMode:UILineBreakModeWordWrap];
    [footerButton.titleLabel setTextAlignment:UITextAlignmentCenter];
    [footerButton.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
    [footerButton setTitleColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.5f alpha:1.0f] forState:UIControlStateNormal];
    [footerButton addTarget:self action:@selector(tosButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.tableView.tableFooterView = footerButton;
    
	if(DeviceIsPad())
		self.tableView.backgroundView = nil;
	
	self.tableView.backgroundColor = [UIColor clearColor];
    
    // add gesture recognizer for background tap to remove keyboard to tableView
    // -- breaks submit button
//    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
//    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (void)viewDidUnload
{
    [self setButtonText:nil];
    [self setFooterText:nil];
    [self setTableView:nil];
    [self setLastTextField:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [buttonText release];
    [footerText release];
    [tableView release];
    [lastTextField release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            // blog name, username, password, confirm and email entry
            return 5;
            break;
        case 1:
            // submit button
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
    if (indexPath.section == 0) {
        UITableViewTextFieldCell *creationCell = [[[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                                               reuseIdentifier:@"TextCell"] autorelease];
        
        if ([indexPath row] == 0) {
            creationCell.textLabel.text = NSLocalizedString(@"Blog", @"");
            creationCell.textField.placeholder = NSLocalizedString(@"WordPress.com blog name", @"");
            creationCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            creationCell.textField.returnKeyType = UIReturnKeyNext;
            creationCell.textField.tag = 0;
            creationCell.textField.delegate = self;
            
            if(blogName != nil)
                creationCell.textField.text = blogName;
        } else if ([indexPath row] == 1) {
            creationCell.textLabel.text = NSLocalizedString(@"Username", @"");
            creationCell.textField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
            creationCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            creationCell.textField.returnKeyType = UIReturnKeyNext;
            creationCell.textField.tag = 1;
            creationCell.textField.delegate = self;
            
            if(username != nil)
                creationCell.textField.text = username;
        } else if ([indexPath row] == 2) {
            creationCell.textLabel.text = NSLocalizedString(@"Password", @"");
            creationCell.textField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
            creationCell.textField.keyboardType = UIKeyboardTypeDefault;
            creationCell.textField.returnKeyType = UIReturnKeyNext;
            creationCell.textField.secureTextEntry = YES;
            creationCell.textField.tag = 2;
            creationCell.textField.delegate = self;
            
            if(password != nil)
                creationCell.textField.text = password;
        } else if ([indexPath row] == 3) {
            creationCell.textLabel.text = NSLocalizedString(@"Confirm", @"");
            creationCell.textField.placeholder = NSLocalizedString(@"Confirm", @"");
            creationCell.textField.keyboardType = UIKeyboardTypeDefault;
            creationCell.textField.returnKeyType = UIReturnKeyNext;
            creationCell.textField.secureTextEntry = YES;
            creationCell.textField.tag = 3;
            creationCell.textField.delegate = self;   
            
            if(passwordconfirm != nil)
                creationCell.textField.text = passwordconfirm;
        } else if ([indexPath row] == 4) {
            creationCell.textLabel.text = NSLocalizedString(@"E-mail", @"");
            creationCell.textField.placeholder = NSLocalizedString(@"E-mail address", @"");
            creationCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
            creationCell.textField.returnKeyType = UIReturnKeyDone;            
            creationCell.textField.tag = 4;
            creationCell.textField.delegate = self;            

            if(email != nil)
                creationCell.textField.text = email;
        }
        
        creationCell.textField.delegate = self;
        cell = creationCell;
    } else if (indexPath.section == 1) {
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

        self.buttonText = NSLocalizedString(@"Create WordPress.com Account", @"");
        
		activityCell.textLabel.text = buttonText;
		cell = activityCell;
	}
    
	return cell;    
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0) {
		return footerText;
    } else {
		return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 0.0f;
    }
    
    return 20.0f;
}

#pragma mark -
#pragma mark Table view delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    UITableViewCell *cell = nil;
    UITextField *nextField = nil;
    
    if (textField.tag == 4) {
        // do something here
    } else {
        switch (textField.tag) {
            case 0:
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                break;
            case 1:
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                break;
            case 2:
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
                break;
            case 3:
                cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
                break;                
        }
        
        [textField endEditing:YES];
        
        if(cell != nil) {
            nextField = (UITextField*)[cell viewWithTag:textField.tag+1];
            
            if(nextField != nil) {
                [nextField becomeFirstResponder];
            }
        }
    }
    
    return YES;	
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self setLastTextField:textField];
    
    [self scrollViewToCenter];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
                    [self setFooterText:NSLocalizedString(@"Blog name is required.", @"")];
                } else {
                    [self setBlogName:textField.text];
                }
                break;
            case 1:
                if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
                    [self setFooterText:NSLocalizedString(@"Username is required.", @"")];
                } else {
                    [self setUsername:textField.text];
                }
                break;
            case 2:
                if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
                    [self setFooterText:NSLocalizedString(@"Password is required.", @"")];
                } else {
                    [self setPassword:textField.text];
                }
                break;
            case 3:
                if((textField.text != nil) && ([textField.text isEqualToString:@""]) && !([textField.text isEqualToString:self.password])) {
                    [self setFooterText:NSLocalizedString(@"Passwords must match.", @"")];
                } else {
                    [self setPasswordconfirm:textField.text];
                }
                break;
            case 4:
                if((textField.text != nil) && ([textField.text isEqualToString:@""])) {
                    [self setFooterText:NSLocalizedString(@"E-mail is required.", @"")];
                } else {
                    [self setEmail:textField.text];
                }
                break;
            default:
                break;
        }
    } 
	
	[textField resignFirstResponder];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (blogName == nil) {
            [self setFooterText:NSLocalizedString(@"Blog name is required.", @"")];
            [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
            [tv reloadData];
        } else if (username == nil) {
            [self setFooterText:NSLocalizedString(@"Username is required.", @"")];
            [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
            [tv reloadData];
        } else if (password == nil) {
            [self setFooterText:NSLocalizedString(@"Password is required.", @"")];
            [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
            [tv reloadData];
        } else if (!([password isEqualToString:passwordconfirm])) {
            [self setFooterText:NSLocalizedString(@"Passwords must match.", @"")];
            [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
            [tv reloadData];
        } else if (email == nil) {
            [self setFooterText:NSLocalizedString(@"E-mail is required.", @"")];
            [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
            [tv reloadData];
        } else {
            [self setButtonText:NSLocalizedString(@"Creating Account...", @"")];            

            [self performSelectorInBackground:@selector(xmlrpcCreateAccount) withObject:self];
            
            [NSThread sleepForTimeInterval:0.15];

            [tv reloadData];
        }
    } 
}

#pragma mark -
#pragma mark Custom Methods

- (void)backgroundTap:(id)sender {
    // Handle for background tap to remove keyboard from screen
    [self.lastTextField resignFirstResponder];
}

- (void)scrollViewToCenter
{
    // Scroll fields behind keyboard so the user can see them
    if(DeviceIsPad() == NO) {
        CGPoint textFieldOrigin = [self.lastTextField convertPoint:self.lastTextField.frame.origin toView:self.view];
        CGFloat scrollPoint = self.view.frame.size.height / 2 - self.lastTextField.frame.size.height;
        
        if (textFieldOrigin.y > scrollPoint) {
            CGFloat scrollDistance = textFieldOrigin.y - scrollPoint/2;
            [self.tableView setContentOffset:CGPointMake(0.0f, scrollDistance) animated:YES];
        }
    }
}

- (void) tosButtonPressed {
    // Push ToS to new webview

    WPWebViewController *tosView;
    if (DeviceIsPad()) {
        tosView = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
    }
    else {
        tosView = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
    }

    [tosView setUrl:[NSURL URLWithString:@"http://en.wordpress.com/tos/"]];
    [tosView view];
    [self.navigationController pushViewController:tosView animated:YES];
    [tosView release];
}

- (void)saveLoginData {   
    NSError *error = nil;
    //FIXME
 /*   [SFHFKeychainUtils storeUsername:username
                         andPassword:password
                      forServiceName:@"WordPress.com"
                      updateExisting:YES
                               error:&error];*/
    
    if (error) {
        NSLog(@"Error storing wpcom credentials: %@", [error localizedDescription]);
    }

	if(![username isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"wpcom_username_preference"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)xmlrpcCreateAccount {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [self setFooterText:@"Creating Account..."];
    AFXMLRPCClient *api = [AFXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:[NSString stringWithFormat: @"%@", kWPcomXMLRPCUrl]]];
    [api callMethod:@"wpcom.registerAccount"
         parameters:[NSArray arrayWithObjects:blogName, username, password, email, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *status = [[NSString alloc] init];
                status = @"";
                NSDictionary *returnData = [responseObject retain];
                NSArray *errors = [NSArray arrayWithObjects:@"blogname", @"user_name", @"pass1", @"user_email", nil];
                for (id e in errors) {
                    if ([returnData valueForKey:e])
                        status = [returnData valueForKey:e];
                }
                
                if ([status isEqualToString:@""])
                    status = @"Success";
            
                if (status != @"Success") {
                    [self setFooterText:@"Error"];
                    [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];                
                } else {
                    [self saveLoginData];
                    [self createBlog];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activation e-mail sent.", @"") 
                                                                    message:NSLocalizedString(@"Please check your e-mail to activate this blog.", @"")
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                    alert.tag = 10;
                    [alert autorelease];
                    [alert show];
                    [self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 WPFLog(@"Failed registering account: %@", [error localizedDescription]); 
                [self setFooterText:[error localizedDescription]];
                [self setButtonText:NSLocalizedString(@"Create WordPress.com Account", @"")];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                                    message:[error localizedDescription]
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = 20;
                [alertView show];
                [alertView release]; 
                [self performSelectorOnMainThread:@selector(refreshTable) withObject:nil waitUntilDone:NO];
            }];
    
    [pool release];
}

- (void)refreshTable {
    [self.tableView reloadData];
}

- (void)createBlog {
    NSMutableDictionary *newBlog = [[NSMutableDictionary alloc] init];
    
    [newBlog setValue:self.blogName forKey:@"blogName"];
    [newBlog setValue:@"1" forKey:@"isAdmin"];
    [newBlog setValue:@"0" forKey:@"isActivated"];
    [newBlog setValue:[NSString stringWithFormat:@"http://%@.wordpress.com/", self.blogName] forKey:@"url"];
    [newBlog setValue:[NSString stringWithFormat:@"https://%@.wordpress.com/xmlrpc.php", self.blogName] forKey:@"xmlrpc"];
    [newBlog setValue:self.username forKey:@"username"];
    [newBlog setValue:self.password forKey:@"password"];
    
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];        
    [blog dataSave];
    
    [newBlog release];
    //FIXME: should we send a notification? addUsersBlogsViewController does this.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 10:
           [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        case 20:
            break;
    }
}

@end
