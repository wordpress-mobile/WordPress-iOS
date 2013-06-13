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
#import "WPComLanguages.h"
#import "SelectWPComLanguageViewController.h"
#import "WPAsyncBlockOperation.h"

@interface CreateWPComAccountViewController () <
    UITextFieldDelegate> {
        
    UITableViewTextFieldCell *_usernameCell;
    UITableViewTextFieldCell *_passwordCell;
    UITableViewTextFieldCell *_emailCell;
    UITableViewTextFieldCell *_blogUrlCell;
    UITableViewCell *_localeCell;
    
    UITextField *_usernameTextField;
    UITextField *_passwordTextField;
    UITextField *_emailTextField;
    UITextField *_blogUrlTextField;
    
    NSString *_buttonText;
    NSString *_footerText;
    
    BOOL _isCreatingAccount;
    BOOL _userPressedBackButton;
    
    NSDictionary *_currentLanguage;
        
    NSOperationQueue *_operationQueue;
}

@end

@implementation CreateWPComAccountViewController

NSUInteger const CreateAccountEmailTextFieldTag = 1;
NSUInteger const CreateAccountUserNameTextFieldTag = 2;
NSUInteger const CreateAccountPasswordTextFieldTag = 3;
NSUInteger const CreateAccountBlogUrlTextFieldTag = 4;

CGSize const CreateAccountHeaderSize = { 320.0, 70.0 };

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        _currentLanguage = [WPComLanguages currentLanguage];
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern"]];
    self.tableView.backgroundView = nil;
    
	_footerText = @" ";
	_buttonText = NSLocalizedString(@"Create WordPress.com Blog", @"");
	self.navigationItem.title = NSLocalizedString(@"Create Account", @"");

    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wpcom"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, CreateAccountHeaderSize.width, CreateAccountHeaderSize.height);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = logoImage;
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
        return 5;
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
            _blogUrlCell.textLabel.text = NSLocalizedString(@"Blog URL", nil);
            _blogUrlTextField = _blogUrlCell.textField;
            _blogUrlTextField.tag = CreateAccountBlogUrlTextFieldTag;
            _blogUrlTextField.placeholder = NSLocalizedString(@"myblog.wordpress.com", nil);
            _blogUrlTextField.keyboardType = UIKeyboardTypeURL;
            _blogUrlTextField.delegate = self;
            cell = _blogUrlCell;
        } else if (indexPath.row == 4) {
            if (_localeCell == nil) {
                _localeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                     reuseIdentifier:@"LocaleCell"];
            }
            _localeCell.textLabel.text = @"Language";
            _localeCell.detailTextLabel.text = [_currentLanguage objectForKey:@"name"];
            _localeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = _localeCell;
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
    
    if (indexPath.section == 0) {
        if (indexPath.row == 4) {
            SelectWPComLanguageViewController *selectLanguageViewController = [[SelectWPComLanguageViewController alloc] initWithStyle:UITableViewStylePlain];
            selectLanguageViewController.currentlySelectedLanguageId = [[_currentLanguage objectForKey:@"lang_id"] intValue];
            selectLanguageViewController.didSelectLanguage = ^(NSDictionary *language){
                _currentLanguage = language;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:selectLanguageViewController animated:YES];
        }
    } else {
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
        default:
            break;
    }
    
	return YES;
}

#pragma mark - Private Methods

- (BOOL)areFieldsValid
{
    return [self areInputFieldsFilled] && ![self doesUrlHavePeriod] && [self isUsernameLessThanFiftyCharacters];
}

- (BOOL)areInputFieldsFilled
{
    return [[_usernameTextField.text trim] length] != 0 && [[_passwordTextField.text trim] length] != 0 && [[_emailTextField.text trim] length] != 0 && [[_blogUrlTextField.text trim] length] != 0;;
}

- (BOOL)doesUrlHavePeriod
{
    return [_blogUrlTextField.text rangeOfString:@"."].location != NSNotFound;
}

- (BOOL)isUsernameLessThanFiftyCharacters
{
    return [[_usernameTextField.text trim] length] <= 50;
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
    } else if ([self doesUrlHavePeriod]) {
        errorMessage = NSLocalizedString(@"Blog url cannot contain a period", nil);
    } else if (![self isUsernameLessThanFiftyCharacters]) {
        errorMessage = NSLocalizedString(@"Username must be less than fifty characters.", nil);        
    }
    
    if (errorMessage != nil) {
        _footerText = errorMessage;
        [self.tableView reloadData];
    }
}

- (void)displayCreationErrorMessage:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
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
        
        [self disableTextFields];
        [self createUserAndBlog];
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
        [_operationQueue cancelAllOperations];
    }
}

#pragma mark - Private Methods

- (void)createUserAndBlog
{
    // As there are 5 API requests to do this successfully, using WPAsyncBlockOperation to create dependencies
    // on previous required API requests so if one fails along the way the rest won't continue executing.
    
    WPAsyncBlockOperation *userValidation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^userValidationSuccess)(id) = ^(id responseObject) {
            [operation didSucceed];
        };
        
        void (^userValidationFailure)(NSError *) = ^(NSError *error){
            [operation didFail];
            [self processErrorDuringRemoteConnection:error];
        };

        [[WordPressComApi sharedApi] validateWPComAccountWithEmail:_emailTextField.text
                                                       andUsername:_usernameTextField.text
                                                       andPassword:_passwordTextField.text
                                                           success:userValidationSuccess
                                                           failure:userValidationFailure];
    }];
    WPAsyncBlockOperation *blogValidation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^blogValidationSuccess)(id) = ^(id responseObject) {
            [operation didSucceed];
        };
        void (^blogValidationFailure)(NSError *) = ^(NSError *error) {
            [self processErrorDuringRemoteConnection:error];
            [operation didFail];
        };
        
        [[WordPressComApi sharedApi] validateWPComBlogWithUrl:_blogUrlTextField.text
                                                 andBlogTitle:nil
                                                andLanguageId:[_currentLanguage objectForKey:@"lang_id"]
                                                      success:blogValidationSuccess
                                                      failure:blogValidationFailure];
    }];    
    WPAsyncBlockOperation *userCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createUserSuccess)(id) = ^(id responseObject){
            [operation didSucceed];
        };
        void (^createUserFailure)(NSError *) = ^(NSError *error) {
            [operation didFail];
            [self processErrorDuringRemoteConnection:error];
        };
        
        [[WordPressComApi sharedApi] createWPComAccountWithEmail:_emailTextField.text
                                                     andUsername:_usernameTextField.text
                                                     andPassword:_passwordTextField.text
                                                         success:createUserSuccess
                                                         failure:createUserFailure];
 
    }];
    WPAsyncBlockOperation *userSignIn = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^signInSuccess)(void) = ^{
            [operation didSucceed];
        };
        void (^signInFailure)(NSError *) = ^(NSError *error) {
            // We've hit a strange failure at this point, the user has been created successfully but for some reason
            // we are unable to sign in and proceed
            [operation didFail];
            [self processErrorDuringRemoteConnection:error];
        };
        
        [[WordPressComApi sharedApi] signInWithUsername:_usernameTextField.text
                                               password:_passwordTextField.text
                                                success:signInSuccess
                                                failure:signInFailure];
    }];
    
    WPAsyncBlockOperation *blogCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createBlogSuccess)(id) = ^(id responseObject){
            [operation didSucceed];
            if (self.delegate != nil) {
                [self.delegate createdAndSignedInAccountWithUserName:_usernameTextField.text];
            }
        };
        void (^createBlogFailure)(NSError *error) = ^(NSError *error) {
            [operation didFail];
            [self processErrorDuringRemoteConnection:error];
        };
        NSNumber *languageId = [_currentLanguage objectForKey:@"lang_id"];
        
        [[WordPressComApi sharedApi] createWPComBlogWithUrl:_blogUrlTextField.text
                                               andBlogTitle:nil
                                              andLanguageId:languageId
                                          andBlogVisibility:WordPressComApiBlogVisibilityPublic
                                                    success:createBlogSuccess
                                                    failure:createBlogFailure];
    }];
    
    // The order of API Requests is
    // 1. Validate User
    // 2. Validate Blog
    // 3. Create User
    // 4. Sign In User
    // 5. Create Blog
    
    [blogCreation addDependency:userSignIn];
    [userSignIn addDependency:userCreation];
    [userCreation addDependency:blogValidation];
    [userCreation addDependency:userValidation];
    [blogValidation addDependency:userValidation];
    
    [_operationQueue addOperation:userValidation];
    [_operationQueue addOperation:blogValidation];
    [_operationQueue addOperation:userCreation];
    [_operationQueue addOperation:userSignIn];
    [_operationQueue addOperation:blogCreation];
}

- (void)processErrorDuringRemoteConnection:(NSError *)error
{
    if (!_userPressedBackButton) {
        _isCreatingAccount = false;
        [self enableTextFields];
        [self.tableView reloadData];
        [self displayCreationErrorMessage:error];
    }
}

- (void)disableTextFields
{
    NSArray *textFields = @[_usernameTextField, _emailTextField, _passwordTextField, _blogUrlTextField];
    for (UITextField *textField in textFields) {
        textField.enabled = false;
    }
}

- (void)enableTextFields
{
    NSArray *textFields = @[_usernameTextField, _emailTextField, _passwordTextField, _blogUrlTextField];
    for (UITextField *textField in textFields) {
        textField.enabled = true;
    }
}

@end
