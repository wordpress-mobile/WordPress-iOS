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
#import "WPTableViewActivityCell.h"
#import "UITableViewTextFieldCell.h"
#import "WPComLanguages.h"
#import "SelectWPComLanguageViewController.h"
#import "WPAsyncBlockOperation.h"
#import "WPTableViewSectionFooterView.h"
#import "WPAccount.h"

static NSString *const TextFieldCellIdentifier = @"TextCell";
static NSString *const LocaleCellIdentifier = @"LocaleCell";
static NSString *const FooterViewIdentifier = @"FooterViewIdentifier";
CGSize const CreateAccountHeaderSize = { 320.0, 70.0 };

@interface CreateWPComAccountViewController () <UITextFieldDelegate>

@property (nonatomic, weak) UITextField *usernameTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UITextField *emailTextField;
@property (nonatomic, weak) UITextField *blogUrlTextField;
@property (nonatomic, strong) NSString *buttonText;
@property (nonatomic, strong) NSString *footerText;
@property (nonatomic, assign) BOOL isCreatingAccount;
@property (nonatomic, assign) BOOL userPressedBackButton;
@property (nonatomic, strong) NSDictionary *currentLanguage;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation CreateWPComAccountViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _currentLanguage = [WPComLanguages currentLanguage];
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
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

	_footerText = @" ";
	_buttonText = NSLocalizedString(@"Create WordPress.com Site", @"Button to complete creating a new WordPress.com site");
	self.navigationItem.title = NSLocalizedString(@"Create Account", @"Label to create a new WordPress.com account.");

    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wpcom"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, CreateAccountHeaderSize.width, CreateAccountHeaderSize.height);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = logoImage;
    
    [self.tableView registerClass:[UITableViewTextFieldCell class] forCellReuseIdentifier:TextFieldCellIdentifier];
    [self.tableView registerClass:[WPTableViewSectionFooterView class] forHeaderFooterViewReuseIdentifier:FooterViewIdentifier];
}

- (NSOperationQueue *)operationQueue {
    if (_operationQueue) {
        return _operationQueue;
    }
    _operationQueue = [[NSOperationQueue alloc] init];
    return _operationQueue;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 5;
    } else {
        return 1;
    }
}

- (NSString *)titleForFooterInSection:(NSInteger)section {
    if(section == 0) {
		return _footerText;
    } else {
		return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    WPTableViewSectionFooterView *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FooterViewIdentifier];
    footer.title = [self titleForFooterInSection:section];
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self titleForFooterInSection:section];
    return [WPTableViewSectionFooterView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1) {
        UITableViewActivityCell *activityCell = nil;
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UITableViewActivityCell" owner:nil options:nil];
		for(id currentObject in topLevelObjects)
		{
			if([currentObject isKindOfClass:[WPTableViewActivityCell class]])
			{
				activityCell = (WPTableViewActivityCell *)currentObject;
				break;
			}
		}
        
        if (_isCreatingAccount) {
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
        
        [WPStyleGuide configureTableViewActionCell:activityCell];
		return activityCell;
	} else {
        if (indexPath.row == 0) {
            UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            
            cell.textLabel.text = NSLocalizedString(@"Email", @"");
            _emailTextField = cell.textField;
            _emailTextField.placeholder = NSLocalizedString(@"user@example.com", @"");
            _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
            _emailTextField.returnKeyType = UIReturnKeyNext;
            _emailTextField.delegate = self;
            [WPStyleGuide configureTableViewTextCell:cell];
            return cell;
        }
        else if (indexPath.row == 1) {
            UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            
            cell.textLabel.text = NSLocalizedString(@"Username", @"Label for username field");
            _usernameTextField = cell.textField;
            _usernameTextField.placeholder = NSLocalizedString(@"Enter username", @"Help user enter username for log in");
            _usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
            _usernameTextField.returnKeyType = UIReturnKeyNext;
            _usernameTextField.delegate = self;
            [WPStyleGuide configureTableViewTextCell:cell];
            return cell;
        } else if (indexPath.row == 2) {
            UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Password", @"Label for password field");
            _passwordTextField = cell.textField;
            _passwordTextField.placeholder = NSLocalizedString(@"Enter password", @"Help user enter password for log in");
            _passwordTextField.keyboardType = UIKeyboardTypeDefault;
            _passwordTextField.returnKeyType = UIReturnKeyNext;
            _passwordTextField.secureTextEntry = YES;
            _passwordTextField.delegate = self;
            [WPStyleGuide configureTableViewTextCell:cell];
            return cell;
        } else if (indexPath.row == 3) {
            UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Site URL", @"Label for Site URL field in the Create a site window");
            _blogUrlTextField = cell.textField;
            _blogUrlTextField.placeholder = NSLocalizedString(@"http://(choose-address).wordpress.com", @"Help user enter a URL for their new site");
            _blogUrlTextField.keyboardType = UIKeyboardTypeURL;
            _blogUrlTextField.delegate = self;
            [WPStyleGuide configureTableViewTextCell:cell];
            return cell;
        } else if (indexPath.row == 4) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:LocaleCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:LocaleCellIdentifier];
            }
            cell.textLabel.text = @"Language";
            cell.detailTextLabel.text = [_currentLanguage objectForKey:@"name"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [WPStyleGuide configureTableViewCell:cell];
            return cell;
        }
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_isCreatingAccount) {
        return;
    }
    
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
	   
    if (textField == _emailTextField) {
        [_usernameTextField becomeFirstResponder];
    } else if (textField == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
    } else if (textField == _passwordTextField) {
        [_blogUrlTextField becomeFirstResponder];
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
    return [[_usernameTextField.text trim] length] != 0 && [[_passwordTextField.text trim] length] != 0 && [[_emailTextField.text trim] length] != 0 && [[_blogUrlTextField.text trim] length] != 0;
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
    [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:errorMessage];
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
        _isCreatingAccount = YES;
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
        _userPressedBackButton = YES;
        [self.operationQueue cancelAllOperations];
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
                WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:_usernameTextField.text andPassword:_passwordTextField.text];
                [WPAccount setDefaultWordPressComAccount:account];
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
    
    [self.operationQueue addOperation:userValidation];
    [self.operationQueue addOperation:blogValidation];
    [self.operationQueue addOperation:userCreation];
    [self.operationQueue addOperation:userSignIn];
    [self.operationQueue addOperation:blogCreation];
}

- (void)processErrorDuringRemoteConnection:(NSError *)error
{
    if (!_userPressedBackButton) {
        _isCreatingAccount = NO;
        [self enableTextFields];
        [self.tableView reloadData];
        [self displayCreationErrorMessage:error];
    }
}

- (void)disableTextFields
{
    NSArray *textFields = @[_usernameTextField, _emailTextField, _passwordTextField, _blogUrlTextField];
    for (UITextField *textField in textFields) {
        textField.enabled = NO;
    }
}

- (void)enableTextFields
{
    NSArray *textFields = @[_usernameTextField, _emailTextField, _passwordTextField, _blogUrlTextField];
    for (UITextField *textField in textFields) {
        textField.enabled = YES;
    }
}

@end
