//
//  SPAutehnticationViewController.m
//  Simperium
//
//  Created by Michael Johnston on 24/11/11.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SPAuthenticationViewController.h"
#import "SPAuthenticator.h"
#import "SPHttpRequest.h"
#import <Simperium/Simperium.h>
#import "JSONKit+Simperium.h"
#import "SPAuthenticationButton.h"
#import "SPAuthenticationConfiguration.h"
#import "SPAuthenticationValidator.h"
#import "SPTOSViewController.h"



#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

NS_ENUM(NSInteger, SPAuthenticationRows) {
	SPAuthenticationRowsEmail		= 0,
	SPAuthenticationRowsPassword	= 1,
	SPAuthenticationRowsConfirm		= 2
};

static CGFloat const SPAuthenticationFieldPaddingX = 10.0;


#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface SPAuthenticationViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) SPAuthenticationValidator *validator;

@property (nonatomic, strong) SPAuthenticationButton	*actionButton;
@property (nonatomic, strong) SPAuthenticationButton	*changeButton;
@property (nonatomic, strong) UIButton					*termsButton;

@property (nonatomic, strong) UITextField				*usernameField;
@property (nonatomic, strong) UITextField				*passwordField;
@property (nonatomic, strong) UITextField				*passwordConfirmField;

@property (nonatomic, strong) UIBarButtonItem			*cancelButton;
@property (nonatomic, strong) UIActivityIndicatorView	*progressView;
@property (nonatomic, assign) CGFloat					keyboardHeight;

@property (nonatomic, assign) BOOL						editing;

- (void)earthquake:(UIView*)itemView;
- (void)changeAction:(id)sender;

@end


#pragma mark ====================================================================================
#pragma mark SPAuthenticationViewController
#pragma mark ====================================================================================

@implementation SPAuthenticationViewController

- (id)init {
	if ((self = [super init])) {
		_signingIn = NO;
	}
	return self;
}

- (void)setSigningIn:(BOOL)bCreating {
	_signingIn = bCreating;
	[self refreshButtons];
}

- (void)refreshButtons {
	NSString *actionTitle = _signingIn ?
		NSLocalizedString(@"Sign In", @"Title of button for logging in (must be short)") :
		NSLocalizedString(@"Sign Up", @"Title of button to create a new account (must be short)");
	NSString *changeTitle = _signingIn ?
		NSLocalizedString(@"Sign up", @"A short link to access the account creation screen") :
		NSLocalizedString(@"Sign in", @"A short link to access the account login screen");
    NSString *changeDetailTitle = _signingIn ?
		NSLocalizedString(@"Don't have an account?", @"A short description to access the account creation screen") :
		NSLocalizedString(@"Already have an account?", @"A short description to access the account login screen");

    
    changeTitle = [[changeTitle stringByAppendingString:@" »"] uppercaseString];
    
	[self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
    [self.changeButton setTitle:changeTitle forState:UIControlStateNormal];
    self.changeButton.detailTitleLabel.text = changeDetailTitle.uppercaseString;

    self.termsButton.hidden = _signingIn;
}

- (void)viewDidLoad {
    self.validator = [[SPAuthenticationValidator alloc] init];
    
	SPAuthenticationConfiguration *configuration = [SPAuthenticationConfiguration sharedInstance];
	
    // TODO: Should eventually be paramaterized
    UIColor *whiteColor		= [UIColor colorWithWhite:0.99 alpha:1.0];
    UIColor *blueColor		= [UIColor colorWithRed:66.0 / 255.0 green:137 / 255.0 blue:201 / 255.0 alpha:1.0];
    UIColor *darkBlueColor	= [UIColor colorWithRed:36.0 / 255.0 green:100.0 / 255.0 blue:158.0 / 255.0 alpha:1.0];
    UIColor *lightGreyColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    UIColor *greyColor		= [UIColor colorWithWhite:0.7 alpha:1.0];
    
    self.view.backgroundColor = whiteColor;
	
    // The cancel button will only be visible if there's a navigation controller, which will only happen
    // if authenticationOptional has been set on the Simperium instance.
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel button for authentication");
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:cancelTitle style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAction:)];
    self.navigationItem.rightBarButtonItem = self.cancelButton;

    // TableView
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.backgroundView = nil;
    _tableView.separatorColor = lightGreyColor;
    _tableView.clipsToBounds = NO;
    [self.view addSubview:_tableView];
	
    if (self.view.bounds.size.height <= 480.0) {
        _tableView.rowHeight = 38.0;
    }
    
	// Terms String
	NSDictionary *termsAttributes = @{
		NSForegroundColorAttributeName: [greyColor colorWithAlphaComponent:0.4]
	};
	
	NSDictionary *termsLinkAttributes = @{
		NSUnderlineStyleAttributeName	: @(NSUnderlineStyleSingle),
		NSForegroundColorAttributeName	: [greyColor colorWithAlphaComponent:0.4]
	};
	
	NSString *termsText = NSLocalizedString(@"By signing up, you agree to our Terms of Service »", @"Terms Button Text");
	NSRange underlineRange = [termsText rangeOfString:@"Terms of Service"];
    NSMutableAttributedString *termsTitle = [[NSMutableAttributedString alloc] initWithString:[termsText uppercaseString] attributes:termsAttributes];
    [termsTitle setAttributes:termsLinkAttributes range:underlineRange];
	
	// Terms Button
    self.termsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_termsButton addTarget:self action:@selector(termsAction:) forControlEvents:UIControlEventTouchUpInside];
    _termsButton.titleEdgeInsets = UIEdgeInsetsMake(3, 0, 0, 0);
    _termsButton.titleLabel.font = [UIFont fontWithName:configuration.mediumFontName size:10.0];
    _termsButton.frame = CGRectMake(10.0, 0.0, self.tableView.frame.size.width-20.0, 24.0);
	_termsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_termsButton setAttributedTitle:termsTitle forState:UIControlStateNormal];;
    
	// Action
	self.actionButton = [[SPAuthenticationButton alloc] initWithFrame:CGRectMake(0, 30.0, self.view.frame.size.width, 44)];
	[_actionButton addTarget:self action:@selector(goAction:) forControlEvents:UIControlEventTouchUpInside];
    [_actionButton setTitleColor:whiteColor forState:UIControlStateNormal];
    _actionButton.titleLabel.font = [UIFont fontWithName:configuration.regularFontName size:22.0];
    _actionButton.backgroundColor = blueColor;
    _actionButton.backgroundHighlightColor = darkBlueColor;
	_actionButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// Change
	self.changeButton = [[SPAuthenticationButton alloc] initWithFrame:CGRectZero];
	[_changeButton addTarget:self action:@selector(changeAction:) forControlEvents:UIControlEventTouchUpInside];
    [_changeButton setTitleColor:blueColor forState:UIControlStateNormal];
    [_changeButton setTitleColor:greyColor forState:UIControlStateHighlighted];
    _changeButton.detailTitleLabel.textColor = greyColor;
    _changeButton.detailTitleLabel.font = [UIFont fontWithName:configuration.mediumFontName size:12.5];
    _changeButton.titleLabel.font = [UIFont fontWithName:configuration.mediumFontName size:12.5];
    _changeButton.frame = CGRectMake(10.0, 80.0, self.tableView.frame.size.width-20.0, 40.0);
	_changeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// Progress
	self.progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	_progressView.frame = CGRectIntegral(CGRectMake(self.actionButton.frame.size.width - 30, (self.actionButton.frame.size.height - 20) / 2.0, 20, 20));
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[_actionButton addSubview:_progressView];
    
	// Logo
    UIImage *logo = [UIImage imageNamed:[SPAuthenticationConfiguration sharedInstance].logoImageName];
    self.logoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, logo.size.width, logo.size.height)];
    _logoView.image = logo;
    _logoView.contentMode = UIViewContentModeCenter;
    [self.view addSubview:_logoView];
    
	// Setup TableView's Footer
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.changeButton.frame.size.height + self.changeButton.frame.origin.y)];
	footerView.contentMode = UIViewContentModeTopLeft;
	[footerView setUserInteractionEnabled:YES];
    [footerView addSubview:_termsButton];
	[footerView addSubview:_actionButton];
	[footerView addSubview:_changeButton];
	footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.tableView.tableFooterView = footerView;
    
	// Setup TableView's GesturesRecognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditingAction:)];
    tapGesture.numberOfTouchesRequired = 1;
    tapGesture.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:tapGesture];
    
	// Show / Hide signup fields, if needed
	[self refreshButtons];
    
    // Layout views
    [self layoutViewsForInterfaceOrientation:self.interfaceOrientation];
}

- (CGFloat)topInset {
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
    return navigationBarHeight > 0 ? navigationBarHeight : 20.0; // 20.0 refers to the status bar height
}

- (void)layoutViewsForInterfaceOrientation:(UIInterfaceOrientation)orientation {
	
    CGFloat viewWidth;
	if (UIInterfaceOrientationIsPortrait(orientation)) {
		viewWidth = MIN(self.view.frame.size.width, self.view.frame.size.height);
	} else {
		viewWidth = MAX(self.view.frame.size.width, self.view.frame.size.height);
	}
	
    _logoView.frame = CGRectIntegral(CGRectMake((viewWidth - _logoView.frame.size.width) / 2.0,
												(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 180.0 : 20.0 + self.topInset,
												_logoView.frame.size.width,
												_logoView.frame.size.height));
    
    CGFloat tableViewYOrigin = _logoView.frame.origin.y + _logoView.frame.size.height;
    CGFloat tableViewWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 400 : viewWidth;
    
    _tableView.frame = CGRectIntegral(CGRectMake((viewWidth - tableViewWidth) / 2.0,
												 tableViewYOrigin,
												 tableViewWidth,
												 self.view.frame.size.height - tableViewYOrigin));
    
    [self.view sendSubviewToBack:_logoView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutViewsForInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate {
    return !_editing;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskPortrait;
    }
	
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillAppear:(BOOL)animated {
    self.tableView.scrollEnabled = NO;
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.tableView.scrollEnabled = NO;
        [self.tableView setBackgroundView:nil];
	}

    // register for keyboard notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    // un-register for keyboard notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver: self name:UIKeyboardWillHideNotification object:nil];
	[nc removeObserver: self name:UIKeyboardWillShowNotification object:nil];
}


#pragma mark Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
	
    CGRect keyboardFrame = [(NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSNumber* duration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
	
    _editing = YES;
    _keyboardHeight = MIN(keyboardFrame.size.height, keyboardFrame.size.width);
	
    [self positionTableViewWithDuration:duration.floatValue];
}

- (void)keyboardWillHide:(NSNotification *)notification {

	NSNumber* duration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
	
    _editing = NO;
    _keyboardHeight = 0;

    [self positionTableViewWithDuration:duration.floatValue];
}

- (void)positionTableViewWithDuration:(CGFloat)duration {
    CGRect newFrame = self.view.bounds;
    
    if (_keyboardHeight > 0) {
        CGFloat maxHeight = newFrame.size.height - _keyboardHeight - self.topInset;
        CGFloat tableViewHeight = [self.tableView tableFooterView].frame.origin.y + [self.tableView tableFooterView].frame.size.height;
        CGFloat tableViewTopPadding = [self.tableView convertRect:[self.tableView cellForRowAtIndexPath:[self emailIndexPath]].frame fromView:self.tableView].origin.y;
        
        newFrame.origin.y = MAX((maxHeight - tableViewHeight - tableViewTopPadding) / 2.0 + self.topInset, self.topInset - tableViewTopPadding);
        newFrame.size.height = maxHeight  + tableViewTopPadding;

        self.tableView.scrollEnabled = YES;
    } else {
        newFrame.origin.y = _logoView.frame.origin.y + _logoView.frame.size.height;
        newFrame.size.height = self.view.frame.size.height -  newFrame.origin.y;
        self.tableView.scrollEnabled = NO;
    }
    
    newFrame.size.width = self.tableView.frame.size.width;
    newFrame.origin.x = self.tableView.frame.origin.x;

    if (!(_keyboardHeight > 0)) {
        self.logoView.hidden = NO;
    }

    self.tableView.tableHeaderView.alpha = _keyboardHeight > 0 ? 1.0 : 0.0;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.tableView.frame = newFrame;
                         self.logoView.alpha = _keyboardHeight > 0 ? 0.0 : 1.0;
                     }
					 completion:^(BOOL finished) {
                         self.logoView.hidden = (_keyboardHeight > 0);
                     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
	
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark Validation

- (BOOL)validateUsername {
	if (![self.validator validateUsername:self.usernameField.text]) {
		NSString *errorText = NSLocalizedString(@"Your email address is not valid.", @"Message displayed when email address is invalid");
        [self.actionButton showErrorMessage:errorText];
        [self earthquake:[self.tableView cellForRowAtIndexPath:[self emailIndexPath]]];
		return NO;
	}
    
	return YES;
}

- (BOOL)validatePassword {
	if (![self.validator validatePasswordSecurity:self.passwordField.text])	{
		NSString *errorText = NSLocalizedString(@"Password must contain at least 4 characters.", @"Message displayed when password is invalid");
        [self.actionButton showErrorMessage:errorText];
        [self earthquake:[self.tableView cellForRowAtIndexPath:[self passwordIndexPath]]];
		return NO;
	}
        
	return YES;
}

- (BOOL)validateData {
	if (![self validateUsername]) {
		return NO;
	}
	
	return [self validatePassword];
}

- (BOOL)validatePasswordConfirmation {
	if ([self.passwordField.text compare: self.passwordConfirmField.text] != NSOrderedSame) {
		[self earthquake: self.passwordField];
		[self earthquake: self.passwordConfirmField];
		return NO;
	}
    
	return YES;
}


#pragma mark Login

- (void)performLogin {	
	self.actionButton.enabled = NO;
	self.changeButton.enabled = NO;
    self.cancelButton.enabled = NO;

	[self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.progressView setHidden: NO];
	[self.progressView startAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self.authenticator authenticateWithUsername:self.usernameField.text
										password:self.passwordField.text
										 success:^{
											 [self.progressView setHidden: YES];
											 [self.progressView stopAnimating];
											 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
										 }
										 failure: ^(int responseCode, NSString *responseString){
											 self.actionButton.enabled = YES;
											 self.changeButton.enabled = YES;
											 self.cancelButton.enabled = YES;

											 [self.progressView setHidden: YES];
											 [self.progressView stopAnimating];
											 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                         
											 NSString* loginError = [self loginErrorForCode:responseCode];
											 [self.actionButton showErrorMessage:loginError];
						 
											 [self earthquake:[self.tableView cellForRowAtIndexPath:[self emailIndexPath]]];
											 [self earthquake:[self.tableView cellForRowAtIndexPath:[self passwordIndexPath]]];
										 }
     ];
}

- (NSString*)loginErrorForCode:(NSUInteger)responseCode {
    switch (responseCode) {
        case 401:
            // Bad email or password
			return NSLocalizedString(@"Could not login with the provided email address and password.", @"Message displayed when login fails");
        default:
            // General network problem
			return NSLocalizedString(@"We're having problems. Please try again soon.", @"Generic error");
    }
}


#pragma mark Creation

- (void)restoreCreationSettings {
	self.actionButton.enabled = YES;
	self.changeButton.enabled = YES;
    self.cancelButton.enabled = YES;
	[self.progressView setHidden: YES];
	[self.progressView stopAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)performCreation {
	self.actionButton.enabled = NO;
	self.changeButton.enabled = NO;
    self.cancelButton.enabled = NO;

	[self.usernameField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.passwordConfirmField resignFirstResponder];
	
	// Try to login and sync after entering password?
	[self.progressView setHidden: NO];
	[self.progressView startAnimating];
    [self.authenticator createWithUsername:self.usernameField.text
								  password:self.passwordField.text
								   success:^{
									   [self.progressView setHidden: YES];
									   [self.progressView stopAnimating];
									   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
								   }
								   failure:^(int responseCode, NSString *responseString){
									   [self restoreCreationSettings];

									   NSString *message = [self signupErrorForCode:responseCode];
									   [self.actionButton showErrorMessage:message];

									   [self earthquake:[self.tableView cellForRowAtIndexPath:[self emailIndexPath]]];
									   [self earthquake:[self.tableView cellForRowAtIndexPath:[self passwordIndexPath]]];
									   [self earthquake:[self.tableView cellForRowAtIndexPath:[self confirmIndexPath]]];
								   }
     ];
}

- (NSString*)signupErrorForCode:(NSUInteger)responseCode {
    switch (responseCode) {
        case 409:
            // User already exists
			return NSLocalizedString(@"That email is already being used", @"Error when address is in use");
        case 401:
            // Bad email or password
			return NSLocalizedString(@"Could not create an account with the provided email address and password.", @"Error for bad email or password");
        default:
            // General network problem
			return NSLocalizedString(@"We're having problems. Please try again soon.", @"Generic error");
    }
}


#pragma mark Actions

- (void)termsAction:(id)sender {
 
    SPTOSViewController *vc = [[SPTOSViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if (self.navigationController) {
		[self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
		[self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)changeAction:(id)sender {
	_signingIn = !_signingIn;
    NSArray *indexPaths = @[ [self confirmIndexPath] ];
    if (_signingIn) {
        [self.tableView deleteRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationTop];
    } else {
        [self.tableView insertRowsAtIndexPaths: indexPaths withRowAnimation:UITableViewRowAnimationTop];
	}
	
    [self.usernameField becomeFirstResponder];
    
    [self setSigningIn:_signingIn];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self positionTableViewWithDuration:0.3];
    });
}

- (void)goAction:(id)sender {
	if ([self validateData]) {
		if (!_signingIn && self.passwordConfirmField.text.length > 0) {
			if ([self validatePasswordConfirmation]) {
				[self performCreation];
			}
		} else {
			[self performLogin];
        }
	}
}

- (void)cancelAction:(id)sender {
    [self.authenticator cancel];
}

- (void)endEditingAction:(id)sender {
    [self.view endEditing:YES];
}


#pragma mark Text Field

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.actionButton clearErrorMessage];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	if (theTextField == self.usernameField) {
		if (![self validateUsername]) {
			return NO;
		}
		
		// Advance to next field and don't dismiss keyboard
		[self.passwordField becomeFirstResponder];
		return NO;
	} else if (theTextField == self.passwordField) {
		if ([self validatePassword]) {
			if (_signingIn) {
				[self performLogin];
			} else {
				// Advance to next field and don't dismiss keyboard
				[self.passwordConfirmField becomeFirstResponder];
				return NO;
			}
		}
	} else {
		if (!_signingIn && [self validatePasswordConfirmation] && [self validateData]) {
			[self performCreation];
		}
	}
	
    return YES;
}


- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure {
    UITextField *newTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 280, 25)];
    newTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    newTextField.clearsOnBeginEditing = NO;
    newTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    newTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    newTextField.secureTextEntry = secure;
    newTextField.font = [UIFont fontWithName:[SPAuthenticationConfiguration sharedInstance].regularFontName size:22.0];
    newTextField.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    newTextField.delegate = self;
    newTextField.returnKeyType = UIReturnKeyNext;
    newTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    newTextField.placeholder = placeholder;
 
    return newTextField;
}

- (void)positionTextField:(UITextField *)textField inCell:(UITableViewCell *)cell {
    CGFloat fieldHeight = ceilf(textField.font.lineHeight);
    
    textField.frame = CGRectIntegral(CGRectMake(SPAuthenticationFieldPaddingX,
												(cell.bounds.size.height - fieldHeight) / 2.0,
												cell.bounds.size.width - 2 * SPAuthenticationFieldPaddingX,
												fieldHeight));
    
}


#pragma mark Table Data Source Methods

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 4.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section  {
    return _signingIn ? (SPAuthenticationRowsPassword + 1) : (SPAuthenticationRowsConfirm + 1);
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *EmailCellIdentifier	= @"EmailCellIdentifier";
	static NSString *PasswordCellIdentifier = @"PasswordCellIdentifier";
	static NSString *ConfirmCellIdentifier	= @"ConfirmCellIdentifier";

	UITableViewCell *cell;
	if (indexPath.row == SPAuthenticationRowsEmail) {
		cell = [tView dequeueReusableCellWithIdentifier:EmailCellIdentifier];
		// Email
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:EmailCellIdentifier];
            
			NSString *usernameText = @"email@email.com";
			self.usernameField = [self textFieldWithPlaceholder:usernameText secure:NO];
            _usernameField.keyboardType = UIKeyboardTypeEmailAddress;

            [self positionTextField:_usernameField inCell:cell];
            [cell.contentView addSubview:_usernameField];
		}
	} else if (indexPath.row == SPAuthenticationRowsPassword) {
		cell = [tView dequeueReusableCellWithIdentifier:PasswordCellIdentifier];		
		// Password
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PasswordCellIdentifier];
			
			NSString *passwordText = NSLocalizedString(@"Password", @"Hint displayed in the password field");
			self.passwordField = [self textFieldWithPlaceholder:passwordText secure:YES];

            [self positionTextField:_passwordField inCell:cell];
            [cell.contentView addSubview:_passwordField];
		}
		
		self.passwordField.returnKeyType = _signingIn ? UIReturnKeyGo : UIReturnKeyNext;
	} else {
		cell = [tView dequeueReusableCellWithIdentifier:ConfirmCellIdentifier];		
		// Password
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ConfirmCellIdentifier];
			
			NSString *confirmText = NSLocalizedString(@"Confirm", @"Hint displayed in the password confirmation field");
			self.passwordConfirmField = [self textFieldWithPlaceholder:confirmText secure:YES];
			_passwordConfirmField.returnKeyType = UIReturnKeyGo;
			
            [self positionTextField:_passwordConfirmField inCell:cell];
            [cell.contentView addSubview:_passwordConfirmField];
		}
	}
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    
	return cell;
}


#pragma mark Helpers

- (void)earthquake:(UIView*)itemView {
    // From http://stackoverflow.com/a/1827373/1379066
    CGFloat t = 2.0;
	
    CGAffineTransform leftQuake  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0);
    CGAffineTransform rightQuake = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0);
	
    itemView.transform = leftQuake;  // starting point
	
    [UIView beginAnimations:@"earthquake" context:(__bridge void *)(itemView)];
    [UIView setAnimationRepeatAutoreverses:YES]; // important
    [UIView setAnimationRepeatCount:5];
    [UIView setAnimationDuration:0.07];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(earthquakeEnded:finished:context:)];
	
    itemView.transform = rightQuake; // end here & auto-reverse
	
    [UIView commitAnimations];
}

- (void)earthquakeEnded:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([finished boolValue]) {
        UIView* item = (__bridge UIView *)context;
        item.transform = CGAffineTransformIdentity;
    }
}

- (NSIndexPath *)emailIndexPath {
	return [NSIndexPath indexPathForItem:SPAuthenticationRowsEmail inSection:0];
}

- (NSIndexPath *)passwordIndexPath {
	return [NSIndexPath indexPathForItem:SPAuthenticationRowsPassword inSection:0];
}

- (NSIndexPath *)confirmIndexPath {
	return [NSIndexPath indexPathForItem:SPAuthenticationRowsConfirm inSection:0];
}

@end
