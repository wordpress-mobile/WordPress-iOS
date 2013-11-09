//
//  JetpackSettingsViewController.m
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import "JetpackSettingsViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "WPAccount.h"
#import "WPNUXUtility.h"
#import "WPNUXMainButton.h"
#import "WPWalkthroughTextField.h"
#import "UIView+FormSheetHelpers.h"
#import "WPNUXSecondaryButton.h"

@interface JetpackSettingsViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@end

@implementation JetpackSettingsViewController {
    Blog *_blog;
    
    UIImageView *_icon;
    UILabel *_description;
    WPWalkthroughTextField *_usernameText;
    WPWalkthroughTextField *_passwordText;
    WPNUXMainButton *_signInButton;
    WPNUXMainButton *_installJetbackButton;
    UIButton *_moreInformationButton;
    WPNUXSecondaryButton *_skipButton;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    CGFloat _keyboardOffset;

    BOOL _authenticating;
}

CGFloat const JetpackiOS7StatusBarOffset = 20.0;
CGFloat const JetpackStandardOffset = 16;
CGFloat const JetpackTextFieldWidth = 320.0;
CGFloat const JetpackMaxTextWidth = 289.0;
CGFloat const JetpackTextFieldHeight = 44.0;
CGFloat const JetpackIconVerticalOffset = 77;
CGFloat const JetpackSignInButtonWidth = 289.0;
CGFloat const JetpackSignInButtonHeight = 41.0;
@synthesize username = _username;
@synthesize password = _password;

#define kCheckCredentials NSLocalizedString(@"Verify and Save Credentials", @"");
#define kCheckingCredentials NSLocalizedString(@"Verifing Credentials", @"");

- (id)initWithBlog:(Blog *)blog {
    NSAssert(blog != nil, @"blog can't be nil");

    self = [super init];
    if (self) {
        _blog = blog;
		self.username = _blog.jetpackUsername;
		self.password = _blog.jetpackPassword;
        self.initialSignIn = YES;
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark LifeCycle Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:_initialSignIn animated:animated];
}

- (void)viewDidLoad {
    WPFLogMethod();
    [super viewDidLoad];
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];

    self.title = NSLocalizedString(@"Jetpack Connect", @"");
    self.view.backgroundColor = [WPNUXUtility jetpackBackgroundColor];
    
    [self initializeView];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }

    // add observer to detect text field changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeNotificaitonRecieved:) name:UITextFieldTextDidChangeNotification object:_usernameText];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeNotificaitonRecieved:) name:UITextFieldTextDidChangeNotification object:_passwordText];
    
    if (_initialSignIn) {
        if (self.canBeSkipped) {
            _skipButton = [[WPNUXSecondaryButton alloc] init];
            [_skipButton setTitle:NSLocalizedString(@"Skip", @"") forState:UIControlStateNormal];
            [_skipButton addTarget:self action:@selector(skip:) forControlEvents:UIControlEventTouchUpInside];
            [_skipButton sizeToFit];
            [self.view addSubview:_skipButton];
            
            self.navigationItem.hidesBackButton = YES;
        }
    }

    [self updateMessage];
    [self updateSaveButton];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self checkForJetpack];
    });

    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tgr.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tgr];
}

- (void)initializeView {
    
    [self addControls];
    [self layoutControls];
}

- (void)addControls {
    
    // Add Logo
    if (_icon == nil) {
        _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack"]];
        [self.view addSubview:_icon];
    }
    
    // Add Description
    if (_description == nil) {
        _description = [[UILabel alloc] init];
        _description.backgroundColor = [UIColor clearColor];
        _description.textAlignment = NSTextAlignmentCenter;
        _description.numberOfLines = 0;
        _description.lineBreakMode = NSLineBreakByWordWrapping;
        _description.font = [WPNUXUtility descriptionTextFont];
        _description.text = NSLocalizedString(@"Hold the web in the palm of your hand. Full publishing power in a pint-sized package.", @"NUX First Walkthrough Page 1 Description");
        _description.textColor = [WPNUXUtility jetpackDescriptionTextColor];
        [self.view addSubview:_description];
    }
    
    // Add Username
    if (_usernameText == nil) {
        _usernameText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
        _usernameText.backgroundColor = [UIColor whiteColor];
        _usernameText.placeholder = NSLocalizedString(@"WordPress.com username", @"");
        _usernameText.font = [WPNUXUtility textFieldFont];
        _usernameText.adjustsFontSizeToFitWidth = YES;
        _usernameText.delegate = self;
        _usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _usernameText.text = _username;
        [self.view addSubview:_usernameText];
    }
    
    // Add Password
    if (_passwordText == nil) {
        _passwordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _passwordText.backgroundColor = [UIColor whiteColor];
        _passwordText.placeholder = NSLocalizedString(@"WordPress.com password", @"");
        _passwordText.font = [WPNUXUtility textFieldFont];
        _passwordText.delegate = self;
        _passwordText.secureTextEntry = YES;
        _passwordText.text = _password;
        _passwordText.showTopLineSeparator = YES;
        [self.view addSubview:_passwordText];
    }
    
    // Add Sign In Button
    if (_signInButton == nil) {
        _signInButton = [[WPNUXMainButton alloc] init];
        NSString *title = _initialSignIn ? NSLocalizedString(@"Sign In", nil) : NSLocalizedString(@"Save", nil);
        [_signInButton setTitle:title forState:UIControlStateNormal];
        [_signInButton addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_signInButton];
        _signInButton.enabled = NO;
    }
    
    // Add Download Button
    if (_installJetbackButton == nil) {
        _installJetbackButton = [[WPNUXMainButton alloc] init];
        [_installJetbackButton setTitle:NSLocalizedString(@"Install Jetpack", @"") forState:UIControlStateNormal];
        [_installJetbackButton addTarget:self action:@selector(openInstallJetpackURL) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_installJetbackButton];
    }
    
    // Add More Information Button
    if (_moreInformationButton == nil) {
        _moreInformationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreInformationButton setTitle:NSLocalizedString(@"More information", @"") forState:UIControlStateNormal];
        [_moreInformationButton addTarget:self action:@selector(openMoreInformationURL) forControlEvents:UIControlEventTouchUpInside];
        [_moreInformationButton setTitleColor:[WPNUXUtility jetpackDescriptionTextColor] forState:UIControlStateNormal];
        _moreInformationButton.titleLabel.font = [WPNUXUtility confirmationLabelFont];
        [self.view addSubview:_moreInformationButton];
    }
}

- (void)layoutControls {
    
    CGFloat x,y;
    BOOL hasJetpack = [_blog hasJetpack];
    
    // Layout Icon
    x = (_viewWidth - CGRectGetWidth(_icon.frame))/2.0;
    y = 0;
    if (IS_IOS7) {
        y = JetpackiOS7StatusBarOffset;
    }
    y += JetpackIconVerticalOffset;
    _icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));
    
    // Layout Description
    CGSize labelSize = [_description.text sizeWithFont:_description.font constrainedToSize:CGSizeMake(JetpackMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - labelSize.width)/2.0;
    y = CGRectGetMaxY(_icon.frame) + 0.5*JetpackStandardOffset;
    _description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Username
    x = (_viewWidth - JetpackTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_description.frame) + JetpackStandardOffset;
    _usernameText.frame = CGRectIntegral(CGRectMake(x, y, JetpackTextFieldWidth, JetpackTextFieldHeight));
    _usernameText.hidden = !hasJetpack;
    
    // Layout Password
    x = (_viewWidth - JetpackTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameText.frame);
    _passwordText.frame = CGRectIntegral(CGRectMake(x, y, JetpackTextFieldWidth, JetpackTextFieldHeight));
    _passwordText.hidden = !hasJetpack;
    
    // Layout Sign in Button
    x = (_viewWidth - JetpackSignInButtonWidth) / 2.0;;
    y = CGRectGetMaxY(_passwordText.frame) + JetpackStandardOffset;
    _signInButton.frame = CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight);
    _signInButton.hidden = !hasJetpack;
    
    // Layout Download Button
    x = (_viewWidth - JetpackSignInButtonWidth)/2.0;
    y = CGRectGetMaxY(_description.frame) + JetpackStandardOffset;
    _installJetbackButton.frame = CGRectIntegral(CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight));
    _installJetbackButton.hidden = hasJetpack;
    
    // Layout More Information Button
    x = (_viewWidth - JetpackSignInButtonWidth)/2.0;
    y = CGRectGetMaxY(_installJetbackButton.frame);
    _moreInformationButton.frame = CGRectIntegral(CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight));
    _moreInformationButton.hidden = hasJetpack;
    
    // Layout Skip Button
    x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(_skipButton.frame) - JetpackStandardOffset;
    y = CGRectGetHeight(self.view.frame) - JetpackStandardOffset - CGRectGetHeight(_skipButton.frame);
    _skipButton.frame = CGRectMake(x, y, CGRectGetWidth(_skipButton.frame), CGRectGetHeight(_skipButton.frame));
    
    NSArray *viewsToCenter;
    UIView *endingView;
    if (hasJetpack) {
        viewsToCenter = @[_icon, _description, _usernameText, _passwordText, _signInButton];
        endingView = _signInButton;
    } else {
        viewsToCenter = @[_icon, _description, _installJetbackButton, _moreInformationButton];
        endingView = _moreInformationButton;
    }
    
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_icon andEndingView:endingView forHeight:(self.view.frame.size.height - 88)];
}


#pragma mark -
#pragma mark Instance Methods

- (void)skip:(id)sender {
    if (self.completionBlock) {
        self.completionBlock(NO);
    }
}


- (void)saveAction:(id)sender {
    
    [self dismissKeyboard];
    [SVProgressHUD show];
	
    [self setAuthenticating:YES];
    [_blog validateJetpackUsername:_username
                          password:_password
                           success:^{
                               [SVProgressHUD dismiss];
                               if (![[WordPressComApi sharedApi] hasCredentials]) {
                                   [[WordPressComApi sharedApi] signInWithUsername:_username password:_password success:nil failure:nil];
                               }
                               [self setAuthenticating:NO];
                               if (self.completionBlock) {
                                   self.completionBlock(YES);
                               }
                           } failure:^(NSError *error) {
                               [SVProgressHUD dismiss];
                               [self setAuthenticating:NO];
                               [WPError showAlertWithError:error];
                           }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == _usernameText) {
        [_passwordText becomeFirstResponder];
    } else if (textField == _passwordText) {
        [self saveAction:nil];
    }
    
	return YES;
}

- (void)textFieldDidChangeNotificaitonRecieved:(NSNotification *)notification {
    
    UITextField *textField = (UITextField *)notification.object;
    
    if([textField isEqual:_usernameText]) {
		self.username = _usernameText.text;
	} else {
		self.password = _passwordText.text;
	}
    [self updateSaveButton];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];

    _keyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_signInButton.frame);
    
    [UIView animateWithDuration:animationDuration animations:^{
        NSArray *controlsToMove = @[_usernameText, _passwordText, _signInButton];
        NSArray *controlsToHide = @[_icon, _description];

        for (UIControl *control in controlsToMove) {
            CGRect frame = control.frame;
            frame.origin.y -= _keyboardOffset;
            control.frame = frame;
        }
        
        for (UIControl *control in controlsToHide) {
            control.alpha = 0.0;
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:animationDuration animations:^{
        NSArray *controlsToMove = @[_usernameText, _passwordText, _signInButton];
        NSArray *controlsToHide = @[_icon, _description];

        for (UIControl *control in controlsToMove) {
            CGRect frame = control.frame;
            frame.origin.y += _keyboardOffset;
            control.frame = frame;
        }
        for (UIControl *control in controlsToHide) {
            control.alpha = 1.0;
        }
    }];
}

#pragma mark - Custom methods


- (BOOL)saveEnabled {
    return (!_authenticating && _usernameText.text.length && _passwordText.text.length);
}

- (void)setAuthenticating:(BOOL)authenticating {
    _authenticating = authenticating;
    [self updateSaveButton];
}

- (void)updateSaveButton {
	if (![self isViewLoaded]) return;
	
    _signInButton.enabled = [self saveEnabled];
}


- (void)dismissKeyboard {
    [_usernameText resignFirstResponder];
    [_passwordText resignFirstResponder];
}

- (void)openInstallJetpackURL {
    
    [self openURL:[NSURL URLWithString:[_blog adminUrlWithPath:@"plugin-install.php?tab=plugin-information&plugin=jetpack"]] withUsername:_blog.username password:_blog.password wpLoginURL:[NSURL URLWithString:_blog.loginUrl]];
}
- (void)openMoreInformationURL {
    
    [self openURL:[NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_15"] withUsername:nil password:nil wpLoginURL:nil];
}

- (void)openURL:(NSURL *)url withUsername:(NSString *)username password:(NSString *)password wpLoginURL:(NSURL *)wpLoginURL {
    
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:url];
    if (username && password && wpLoginURL) {

        [webViewController setUsername:username];
        [webViewController setPassword:password];
        [webViewController setWpLoginURL:wpLoginURL];
    }
    
    if (self.navigationController) {
        [self.navigationController pushViewController:webViewController animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
        navController.navigationBar.translucent = NO;
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        webViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissBrowser)];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)dismissBrowser {
    [self dismissViewControllerAnimated:YES completion:^{
        [self checkForJetpack];
    }];
}

- (void)updateMessage {
    if ([_blog hasJetpack]) {
        _description.text = NSLocalizedString(@"Looks like you have Jetpack set up on your blog. Congrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", @"");
    } else {
        _description.text = NSLocalizedString(@"Jetpack 1.8.2 or later is required for stats. Do you want to install Jetpack?", @"");
    }
    [_description sizeToFit];
    
    [self layoutControls];
}

- (void)checkForJetpack {
    if ([_blog hasJetpack]) {
        [self tryLoginWithCurrentWPComCredentials];
        return;
    }
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Checking for Jetpack...", @"") maskType:SVProgressHUDMaskTypeBlack];
    [_blog syncOptionsWithWithSuccess:^{
        [SVProgressHUD dismiss];
        if ([_blog hasJetpack]) {
            [self updateMessage];
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self tryLoginWithCurrentWPComCredentials];
            });
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [WPError showAlertWithError:error];
    }];
}

- (void)tryLoginWithCurrentWPComCredentials {
    if ([_blog hasJetpack] && !([[_blog jetpackUsername] length] && [[_blog jetpackPassword] length])) {
        NSString *wpcomUsername = [[WPAccount defaultWordPressComAccount] username];
        NSString *wpcomPassword = [[WPAccount defaultWordPressComAccount] password];
        if (wpcomUsername && wpcomPassword) {
            [self tryLoginWithUsername:wpcomUsername andPassword:wpcomPassword];
        }
    }
}

- (void)tryLoginWithUsername:(NSString *)username andPassword:(NSString *)password {
    NSAssert(username != nil, @"Can't login with a nil username");
    NSAssert(password != nil, @"Can't login with a nil password");
    _usernameText.text = username;
    _passwordText.text = password;
	
    self.username = username;
    self.password = password;

    [self saveAction:nil];
}

@end
