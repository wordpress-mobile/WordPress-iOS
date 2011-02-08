//
//  EditBlogViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "EditSiteViewController.h"

#define WRONG_FIELD_COLOR [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0]
#define GOOD_FIELD_COLOR [UIColor blackColor]

@interface EditSiteViewController (PrivateMethods)
- (void)validateFields;
@end

@implementation EditSiteViewController
@synthesize password, username, url;
@synthesize blog, tableView;
@synthesize urlCell, usernameCell, passwordCell;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [FlurryAPI logEvent:@"EditSite"];

	if([blog isWPcom] == YES) {
		self.navigationItem.title = @"Edit Blog";
	}
	else {
		self.navigationItem.title = @"Edit Site";
	}

    NSError *error = nil;
    self.url = blog.url;
    self.username = blog.username;
    self.password = [SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.url error:&error];
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(done:)];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.navigationItem.rightBarButtonItem = doneButton;	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if(DeviceIsPad() == YES)
		return YES;
	else
		return NO;
}

#pragma mark -
#pragma mark Table view data source

- (UITextField *)newTextFieldForCell:(UITableViewCell *)cell {
    CGSize labelSize = [cell.textLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:17]];
    labelSize.width = ceil(labelSize.width/5) * 5; // Round to upper 5
    CGRect frame;
    // Frame values have to be hard coded since the cell has not been added yet to the table
    if (DeviceIsPad()) {
        frame = CGRectMake(labelSize.width + 50,
                           11,
                           440 - labelSize.width,
                           28);
    } else {
        frame = CGRectMake(labelSize.width + 30,
                           11,
                           cell.frame.size.width - labelSize.width - 50,
                           28);
    }

    UITextField *addTextField = [[UITextField alloc] initWithFrame:frame];
    addTextField.adjustsFontSizeToFitWidth = YES;
    addTextField.textColor = [UIColor blackColor];
    addTextField.backgroundColor = [UIColor clearColor];
    addTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    addTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    addTextField.textAlignment = UITextAlignmentLeft;
    addTextField.delegate = self;
    addTextField.clearButtonMode = UITextFieldViewModeNever;
    addTextField.enabled = YES;
    addTextField.returnKeyType = UIReturnKeyDone;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return addTextField;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case 0:
            return 3;	// URL, username, password
		case 1:
            return 1;	// Settings
		default:
			break;
	}
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if ([indexPath section] == 0) {
        if (indexPath.row == 0) {
            self.urlCell = [tableView dequeueReusableCellWithIdentifier:@"UrlCell"];
            if (self.urlCell == nil) {
                self.urlCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UrlCell"] autorelease];
            }
            self.urlCell.textLabel.text = @"URL";
            urlTextField = [self newTextFieldForCell:self.urlCell];
            urlTextField.placeholder = @"http://example.com";
            urlTextField.keyboardType = UIKeyboardTypeURL;
            if(blog.url != nil)
                urlTextField.text = blog.url;
            [self.urlCell addSubview:urlTextField];
            return self.urlCell;
        }
        else if(indexPath.row == 1) {
            self.usernameCell = [tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
            if (self.usernameCell == nil) {
                self.usernameCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"] autorelease];
            }
            self.usernameCell.textLabel.text = @"Username";
            usernameTextField = [self newTextFieldForCell:self.usernameCell];
            usernameTextField.placeholder = @"WordPress username.";
            usernameTextField.keyboardType = UIKeyboardTypeDefault;
            if(blog.username != nil)
                usernameTextField.text = blog.username;
            [self.usernameCell addSubview:usernameTextField];
            return self.usernameCell;
        }
        else if(indexPath.row == 2) {
            self.passwordCell = [tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
            if (self.passwordCell == nil) {
                self.passwordCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"] autorelease];
            }            
            self.passwordCell.textLabel.text = @"Password";
            passwordTextField = [self newTextFieldForCell:self.passwordCell];
            passwordTextField.placeholder = @"WordPress password.";
            passwordTextField.keyboardType = UIKeyboardTypeDefault;
            passwordTextField.secureTextEntry = YES;
            if(password != nil)
                passwordTextField.text = password;
            [self.passwordCell addSubview:passwordTextField];
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
        switchCell.textLabel.text = @"Geotagging";
        switchCell.selectionStyle = UITableViewCellSelectionStyleNone;
        switchCell.cellSwitch.on = self.blog.geolocationEnabled;
        [switchCell.cellSwitch addTarget:self action:@selector(toggleGeolocation:) forControlEvents:UIControlEventValueChanged];
        return switchCell;
	}
    
    // We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result = nil;
	switch (section) {
		case 0:
			result = blog.blogName;
			break;
        case 1:
            result = @"Settings";
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
	}
    [tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UITextField methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;	
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
    if (buttonIndex == 0) {
        // Discard changes
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark Custom methods

- (void)toggleGeolocation:(id)sender {
    blog.geolocationEnabled = switchCell.cellSwitch.on;
    [blog dataSave];
}

- (void)refreshTable {
	[self.tableView reloadData];
}

- (void)remoteValidate {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    WPDataController *dc = [[WPDataController alloc] init];
    WPLog(@"before guess");
    NSString *xmlrpc = [dc guessXMLRPCForUrl:urlTextField.text];
    WPLog(@"after guess");
    if (xmlrpc != nil) {
        if ([dc authenticateUser:xmlrpc username:usernameTextField.text password:passwordTextField.text]) {
            [self performSelectorOnMainThread:@selector(validationSuccess:) withObject:xmlrpc waitUntilDone:YES];
        } else {
            [self performSelectorOnMainThread:@selector(validationDidFail:) withObject:dc.error waitUntilDone:YES];
        }
    } else {
        [self performSelectorOnMainThread:@selector(validationDidFail:) withObject:dc.error waitUntilDone:YES];
    }

	[pool release];    
}

- (void)validationSuccess:(NSString *)xmlrpc {
    blog.url = self.url;
    blog.xmlrpc = xmlrpc;
    blog.username = self.username;
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:blog.username
                         andPassword:self.password
                      forServiceName:blog.url
                      updateExisting:YES
                               error:&error];
    
    if (error) {
        NSLog(@"Error saving password for %@", blog.url);
    }
    [self dismissModalViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];

    doneButton.enabled = YES;
}
         
- (void)validationDidFail:(id)wrong {
    if (wrong) {
        if ([wrong isKindOfClass:[UITableViewCell class]]) {
            ((UITableViewCell *)wrong).textLabel.textColor = WRONG_FIELD_COLOR;
        } else if ([wrong isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)wrong;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Can't log in"
                                                                message:[error localizedDescription]
                                                               delegate:self
                                                      cancelButtonTitle:@"Discard changes"
                                                      otherButtonTitles:self.navigationItem.title, nil];
            [alertView show];
            [alertView release];            
        }
    }    

    doneButton.enabled = YES;
}

- (void)validateFields {
    urlTextField.text;
    usernameTextField.text;
    passwordTextField.text;
    
    doneButton.enabled = NO;
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
        [self performSelectorInBackground:@selector(remoteValidate) withObject:nil];
    } else {
        [self validationDidFail:nil];
    }
}

- (void)done:(id)sender {
    if ([self.username isEqualToString:usernameTextField.text]
        && [self.password isEqualToString:passwordTextField.text]
        && [self.url isEqualToString:urlTextField.text]) {
        // No need to check if nothing changed
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self validateFields];
    }
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
    [doneButton release]; doneButton = nil;
    [switchCell release]; switchCell = nil;
    [urlTextField release]; urlTextField = nil;
    [usernameTextField release]; usernameTextField = nil;
    [passwordTextField release]; passwordTextField = nil;
    [super dealloc];
}


@end

