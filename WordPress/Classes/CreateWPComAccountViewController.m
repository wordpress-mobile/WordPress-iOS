//
//  CreateWPComAccountViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateWPComAccountViewController.h"
#import "WordPressComApi.h"
#import "ReachabilityUtils.h"
#import "UITableViewActivityCell.h"
#import "UITableViewTextFieldCell.h"

@interface CreateWPComAccountViewController () <UITextFieldDelegate> {
    UITableViewTextFieldCell *_usernameCell;
    UITableViewTextFieldCell *_passwordCell;
    UITableViewTextFieldCell *_emailCell;
    UITableViewTextFieldCell *_blogUrlCell;
    
    UITextField *_usernameTextField;
    UITextField *_passwordTextField;
    UITextField *_emailTextField;
    UITextField *_blogUrlTextField;
    
    NSString *_buttonText;
    NSString *_footerText;
    
    BOOL _isCreatingAccount;
    BOOL _userPressedBackButton;
}

@end

@implementation CreateWPComAccountViewController

NSUInteger const CreateAccountEmailTextFieldTag = 1;
NSUInteger const CreateAccountUserNameTextFieldTag = 2;
NSUInteger const CreateAccountPasswordTextFieldTag = 3;
NSUInteger const CreateAccountBlogTextFieldTag = 4;

CGSize const CreateAccountHeaderSize = { 320.0, 70.0 };
CGPoint const CreateAccountLogoStartingPoint = { 40.0, 20.0 };
CGPoint const CreateAccountLogoStartingPointIpad = { 150.0, 20.0 };
CGSize const CreateAccountLogoSize = { 229.0, 43.0 };

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern"]];
    self.tableView.backgroundView = nil;
    
	_footerText = @" ";
	_buttonText = NSLocalizedString(@"Create WordPress.com Blog", @"");
	self.navigationItem.title = NSLocalizedString(@"Create Account", @"");
        
    CGRect headerFrame = CGRectMake(0, 0, CreateAccountHeaderSize.width, CreateAccountHeaderSize.height);
    CGRect logoFrame = CGRectMake(CreateAccountLogoStartingPoint.x, CreateAccountLogoStartingPoint.y, CreateAccountLogoSize.width, CreateAccountLogoSize.height);
	NSString *logoFile = @"logo_wpcom.png";
	if(IS_IPAD == YES) {
		logoFile = @"logo_wpcom@2x.png";
        logoFrame = CGRectMake(CreateAccountLogoStartingPointIpad.x, CreateAccountLogoStartingPointIpad.y, CreateAccountLogoSize.width, CreateAccountLogoSize.height);
	}

	UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	self.tableView.tableHeaderView = headerView;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 4;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0)
		return _footerText;
    else
		return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        
        if(_isCreatingAccount) {
			[activityCell.spinner startAnimating];
			_buttonText = NSLocalizedString(@"Creating Account...", @"");
		} else {
			[activityCell.spinner stopAnimating];
			_buttonText = NSLocalizedString(@"Create WordPress.com Blog", @"");
		}
		
		activityCell.textLabel.text = _buttonText;
        if (_isCreatingAccount) {
            activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            activityCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
		cell = activityCell;
	} else {
        if (indexPath.row == 0) {
            if (_emailCell == nil) {
                _emailCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                             reuseIdentifier:@"TextCell"];
            }
            _emailCell.textLabel.text = NSLocalizedString(@"Email", @"");
            _emailTextField = _emailCell.textField;
            _emailTextField.tag = CreateAccountEmailTextFieldTag;
            _emailTextField.placeholder = NSLocalizedString(@"user@example.com", @"");
            _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
            _emailTextField.returnKeyType = UIReturnKeyNext;
            _emailTextField.delegate = self;
            cell = _emailCell;
        }
        else if (indexPath.row == 1) {
            if (_usernameCell == nil) {
                _usernameCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                reuseIdentifier:@"TextCell"];
            }
            _usernameCell.textLabel.text = NSLocalizedString(@"Username", @"");
            _usernameTextField = _usernameCell.textField;
            _usernameTextField.tag = CreateAccountUserNameTextFieldTag;
            _usernameTextField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
            _usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
            _usernameTextField.returnKeyType = UIReturnKeyNext;
            _usernameTextField.delegate = self;
            cell = _usernameCell;
        } else if (indexPath.row == 2) {
            if (_passwordCell == nil) {
                _passwordCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                reuseIdentifier:@"TextCell"];
            }
            _passwordCell.textLabel.text = NSLocalizedString(@"Password", @"");
            _passwordTextField = _passwordCell.textField;
            _passwordTextField.tag = CreateAccountPasswordTextFieldTag;
            _passwordTextField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
            _passwordTextField.keyboardType = UIKeyboardTypeDefault;
            _passwordTextField.returnKeyType = UIReturnKeyNext;
            _passwordTextField.secureTextEntry = YES;
            _passwordTextField.delegate = self;
            cell = _passwordCell;
        } else if (indexPath.row == 3) {
            if (_blogUrlCell == nil) {
                _blogUrlCell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                reuseIdentifier:@"TextCell"];
            }
            _blogUrlCell.textLabel.text = NSLocalizedString(@"Blog URL", @"");
            _blogUrlTextField = _blogUrlCell.textField;
            _blogUrlTextField.tag = CreateAccountBlogTextFieldTag;
            _blogUrlTextField.placeholder = NSLocalizedString(@"myblog.wordpress.com", @"");
            _blogUrlTextField.keyboardType = UIKeyboardTypeURL;
            _blogUrlTextField.delegate = self;
            cell = _blogUrlCell;
        }
    }
    
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_isCreatingAccount)
        return;
    
    if (indexPath.section == 1) {
        [self createAccount];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	   
    switch (textField.tag) {
        case CreateAccountEmailTextFieldTag:
            [_usernameTextField becomeFirstResponder];
            break;
        case CreateAccountUserNameTextFieldTag:
            [_passwordTextField becomeFirstResponder];
            break;
        case CreateAccountPasswordTextFieldTag:
            [_blogUrlTextField becomeFirstResponder];
            break;
        case CreateAccountBlogTextFieldTag:
            [self createAccount];
            break;
        default:
            break;
    }
    
	return YES;
}

#pragma mark - Private Methods

- (BOOL)areFieldsValid
{
    BOOL areFieldsFilled = [[_usernameTextField.text trim] length] != 0 && [[_passwordTextField.text trim] length] != 0 && [[_emailTextField.text trim] length] != 0 && [[_blogUrlTextField.text trim] length] != 0;
    BOOL urlDoesNotHaveDot = [_blogUrlTextField.text rangeOfString:@"."].location == NSNotFound;
    
    return areFieldsFilled && urlDoesNotHaveDot;
}

- (void)showErrorMessage
{
    NSString *errorMessage;
    
    if ([[_emailTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Email address is required.", nil);
    } else if ([[_usernameTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Username is required.", nil);
    } else if ([[_passwordTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Password is required.", nil);
    } else if ([[_blogUrlTextField.text trim] length] == 0) {
        errorMessage = NSLocalizedString(@"Blog address is required.", nil);
    } else if ([_blogUrlTextField.text rangeOfString:@"."].location != NSNotFound) {
        errorMessage = NSLocalizedString(@"Blog url cannot contain a period", nil);
    }
    
    if (errorMessage != nil) {
        _footerText = errorMessage;
        [self.tableView reloadData];
    }
}

- (void)handleCreationError:(NSError *)error
{
    NSString *errorCode = [error.userInfo objectForKey:WordPressComApiErrorCodeKey];
    NSString *errorMessage;
    
    if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidUser]) {
        errorMessage = NSLocalizedString(@"Invalid username", @"");
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidEmail]) {
        errorMessage = NSLocalizedString(@"Invalid email address", @"");
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidPassword]) {
        errorMessage = NSLocalizedString(@"Invalid password", @"");
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogUrl]) {
        errorMessage = NSLocalizedString(@"Invalid blog url", @"");
    } else if ([errorCode isEqualToString:WordPressComApiErrorCodeInvalidBlogTitle]) {
        errorMessage = NSLocalizedString(@"Invalid Blog Title", @"");
    } else {
        errorMessage = NSLocalizedString(@"Unknown error", @"");
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)createAccount
{
    [self.view endEditing:YES];
    
    if ([self areFieldsValid]) {
        if (![ReachabilityUtils isInternetReachable]) {
            [ReachabilityUtils showAlertNoInternetConnection];
            return;
        }

        _footerText = @"";
        _isCreatingAccount = true;
        [self.tableView reloadData];
        
        [[WordPressComApi sharedApi] createWPComAccountWithEmail:_emailTextField.text andUsername:_usernameTextField.text andPassword:_passwordTextField.text andBlogUrl:_blogUrlTextField.text success:^(id responseObject){
            [[WordPressComApi sharedApi] signInWithUsername:_usernameTextField.text password:_passwordTextField.text success:^{
                if (self.delegate != nil) {
                    [self.delegate createdAndSignedInAccountWithUserName:_usernameTextField.text];
                }
            } failure:^(NSError * error){
                WPFLog(@"Error logging in after creating an account with username : %@", _usernameTextField.text);
                // If we fail to log in  for whatever reason after successfuly creating an account, fallback and
                // display the login form so the user has the option of logging in.
                [self.delegate createdAccountWithUserName:_usernameTextField.text];
            }];
        } failure:^(NSError *error){
            // We don't want to display any messages if the user decided to "cancel" this screen and
            // go back to the main screen.
            if (!_userPressedBackButton) {
                _isCreatingAccount = false;
                [self.tableView reloadData];
                [self handleCreationError:error];
            }
        }];
    } else {
        [self showErrorMessage];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    // User has pressed back button so make sure the user does not see a strange message
    // or encounters strange behavior as a result of a failed or successful attempt to create an account.
    if (parent == nil) {
        self.delegate = nil;
        _userPressedBackButton = true;
    }
}

@end
