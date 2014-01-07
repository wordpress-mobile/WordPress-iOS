//
//  JetpackSettingsViewController.m
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "JetpackSettingsViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "WPAccount.h"
#import "WPNUXUtility.h"
#import "WPNUXMainButton.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXSecondaryButton.h"
#import "UILabel+SuggestSize.h"
#import "WordPressComOAuthClient.h"

CGFloat const JetpackiOS7StatusBarOffset = 20.0;
CGFloat const JetpackStandardOffset = 16;
CGFloat const JetpackTextFieldWidth = 320.0;
CGFloat const JetpackMaxTextWidth = 289.0;
CGFloat const JetpackTextFieldHeight = 44.0;
CGFloat const JetpackIconVerticalOffset = 77;
CGFloat const JetpackSignInButtonWidth = 289.0;
CGFloat const JetpackSignInButtonHeight = 41.0;

@interface JetpackSettingsViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>
@end

@implementation JetpackSettingsViewController {
    Blog *_blog;
    
    UIImageView *_icon;
    UILabel *_description;
    WPWalkthroughTextField *_usernameField;
    WPWalkthroughTextField *_passwordField;
    WPNUXMainButton *_signInButton;
    WPNUXMainButton *_installJetbackButton;
    UIButton *_moreInformationButton;
    WPNUXSecondaryButton *_skipButton;
    
    CGFloat _keyboardOffset;

    BOOL _authenticating;
}

- (id)initWithBlog:(Blog *)blog {

    self = [super init];
    if (self) {
        _blog = blog;
        self.showFullScreen = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) hidesBottomBarWhenPushed {
    return YES;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutControls];
}

#pragma mark -
#pragma mark LifeCycle Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:_showFullScreen animated:animated];
    [self layoutControls];
}

- (void)viewDidLoad {
    DDLogMethod();
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Jetpack Connect", @"");
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    [self initializeView];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeNotificationReceived:) name:UITextFieldTextDidChangeNotification object:_usernameField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeNotificationReceived:) name:UITextFieldTextDidChangeNotification object:_passwordField];
    
    if (self.canBeSkipped) {
        if (_showFullScreen) {
            _skipButton = [[WPNUXSecondaryButton alloc] init];
            [_skipButton setTitle:NSLocalizedString(@"Skip", @"") forState:UIControlStateNormal];
            [_skipButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
            [_skipButton addTarget:self action:@selector(skipAction:) forControlEvents:UIControlEventTouchUpInside];
            [_skipButton sizeToFit];
            [self.view addSubview:_skipButton];
        } else {
            UIBarButtonItem *skipButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"") style:UIBarButtonItemStylePlain target:self action:@selector(skip:)];
            self.navigationItem.rightBarButtonItem = skipButton;
        }
        
        self.navigationItem.hidesBackButton = YES;

    }

    [self updateMessage];
    [self updateSaveButton];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self checkForJetpack];
    });

    UITapGestureRecognizer *dismissKeyboardTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    dismissKeyboardTapRecognizer.cancelsTouchesInView = YES;
    dismissKeyboardTapRecognizer.delegate = self;
    [self.view addGestureRecognizer:dismissKeyboardTapRecognizer];
}

- (void)initializeView {
    
    [self addControls];
    [self layoutControls];
}

// This resolves a crash due to JetpackSettingsViewController previously using a .xib.
// Source: http://stackoverflow.com/questions/17708292/not-key-value-coding-compliant-error-from-deleted-xib
- (void)loadView {
    [super loadView];
}

- (void)addControls {
    // Add Logo
    if (_icon == nil) {
        _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack-gray"]];
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
        _description.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.view addSubview:_description];
    }
    
    // Add Username
    if (_usernameField == nil) {
        _usernameField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
        _usernameField.backgroundColor = [UIColor whiteColor];
        _usernameField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
        _usernameField.font = [WPNUXUtility textFieldFont];
        _usernameField.adjustsFontSizeToFitWidth = YES;
        _usernameField.delegate = self;
        _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _usernameField.text = _blog.jetpackUsername;
        _usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self.view addSubview:_usernameField];
    }
    
    // Add Password
    if (_passwordField == nil) {
        _passwordField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _passwordField.backgroundColor = [UIColor whiteColor];
        _passwordField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
        _passwordField.font = [WPNUXUtility textFieldFont];
        _passwordField.delegate = self;
        _passwordField.secureTextEntry = YES;
        _passwordField.text = _blog.jetpackPassword;
        _passwordField.clearsOnBeginEditing = YES;
        _passwordField.showTopLineSeparator = YES;
        [self.view addSubview:_passwordField];
    }
    
    // Add Sign In Button
    if (_signInButton == nil) {
        _signInButton = [[WPNUXMainButton alloc] init];
        NSString *title = _showFullScreen ? NSLocalizedString(@"Sign In", nil) : NSLocalizedString(@"Save", nil);
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
        [_moreInformationButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
        _moreInformationButton.titleLabel.font = [WPNUXUtility confirmationLabelFont];
        [self.view addSubview:_moreInformationButton];
    }
    [self updateSaveButton];
}

- (void)layoutControls {
    CGFloat x,y;
    BOOL hasJetpack = [_blog hasJetpack];
    
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    // Layout Icon
    x = (viewWidth - CGRectGetWidth(_icon.frame))/2.0;
    y = JetpackiOS7StatusBarOffset + JetpackIconVerticalOffset;
    _icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));
    _icon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout Description
    CGSize labelSize = [_description suggestedSizeForWidth:JetpackMaxTextWidth];
    x = (viewWidth - labelSize.width)/2.0;
    y = CGRectGetMaxY(_icon.frame) + 0.5*JetpackStandardOffset;
    _description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    _description.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout Username
    x = (viewWidth - JetpackTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_description.frame) + JetpackStandardOffset;
    _usernameField.frame = CGRectIntegral(CGRectMake(x, y, JetpackTextFieldWidth, JetpackTextFieldHeight));
    _usernameField.hidden = !hasJetpack;
    _usernameField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    // Layout Password
    x = (viewWidth - JetpackTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameField.frame);
    _passwordField.frame = CGRectIntegral(CGRectMake(x, y, JetpackTextFieldWidth, JetpackTextFieldHeight));
    _passwordField.hidden = !hasJetpack;
    _passwordField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout Sign in Button
    x = (viewWidth - JetpackSignInButtonWidth) / 2.0;;
    y = CGRectGetMaxY(_passwordField.frame) + JetpackStandardOffset;
    _signInButton.frame = CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight);
    _signInButton.hidden = !hasJetpack;
    _signInButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout Download Button
    x = (viewWidth - JetpackSignInButtonWidth)/2.0;
    y = CGRectGetMaxY(_description.frame) + JetpackStandardOffset;
    _installJetbackButton.frame = CGRectIntegral(CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight));
    _installJetbackButton.hidden = hasJetpack;
    _installJetbackButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout More Information Button
    x = (viewWidth - JetpackSignInButtonWidth)/2.0;
    y = CGRectGetMaxY(_installJetbackButton.frame);
    _moreInformationButton.frame = CGRectIntegral(CGRectMake(x, y, JetpackSignInButtonWidth, JetpackSignInButtonHeight));
    _moreInformationButton.hidden = hasJetpack;
    _moreInformationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Layout Skip Button
    x = viewWidth - CGRectGetWidth(_skipButton.frame) - JetpackStandardOffset;
    y = viewHeight - JetpackStandardOffset - CGRectGetHeight(_skipButton.frame);
    _skipButton.frame = CGRectMake(x, y, CGRectGetWidth(_skipButton.frame), CGRectGetHeight(_skipButton.frame));
    _skipButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    NSArray *viewsToCenter;
    UIView *endingView;
    if (hasJetpack) {
        viewsToCenter = @[_icon, _description, _usernameField, _passwordField, _signInButton];
        endingView = _signInButton;
    } else {
        viewsToCenter = @[_icon, _description, _installJetbackButton, _moreInformationButton];
        endingView = _moreInformationButton;
    }
    
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_icon andEndingView:endingView forHeight:(viewHeight - 100)];
}

- (void)skipAction:(id)sender {
    if (self.completionBlock) {
        self.completionBlock(NO);
    }
}

- (void)saveAction:(id)sender {
    [self dismissKeyboard];
    [self setAuthenticating:YES];

    [_blog validateJetpackUsername:_usernameField.text
                          password:_passwordField.text
                           success:^{
                               if (![[[WPAccount defaultWordPressComAccount] restApi] hasCredentials]) {
                                   [[WordPressComOAuthClient client] authenticateWithUsername:_usernameField.text password:_passwordField.text success:^(NSString *authToken) {
                                       WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:_usernameField.text password:_passwordField.text authToken:authToken];
                                       [WPAccount setDefaultWordPressComAccount:account];
                                   } failure:^(NSError *error) {
                                       DDLogWarn(@"Unabled to obtain OAuth token for account credentials provided for Jetpack blog. %@", error);
                                   }];
                               }
                               [self setAuthenticating:NO];
                               if (self.completionBlock) {
                                   self.completionBlock(YES);
                               }
                           } failure:^(NSError *error) {
                               [self setAuthenticating:NO];
                               [WPError showNetworkingAlertWithError:error];
                           }];
}

#pragma mark - UITextField delegate and Keyboard

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _usernameField) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        [self saveAction:nil];
    }
    
	return YES;
}

- (void)textFieldDidChangeNotificationReceived:(NSNotification *)notification {
    [self updateSaveButton];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];

    _keyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_signInButton.frame);
    
    [UIView animateWithDuration:animationDuration animations:^{
        NSArray *controlsToMove = @[_usernameField, _passwordField, _signInButton];
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

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:animationDuration animations:^{
        NSArray *controlsToMove = @[_usernameField, _passwordField, _signInButton];
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
    return (!_authenticating && _usernameField.text.length && _passwordField.text.length);
}

- (void)setAuthenticating:(BOOL)authenticating {
    _authenticating = authenticating;
    _usernameField.enabled = !authenticating;
    _passwordField.enabled = !authenticating;
    [self updateSaveButton];
    [_signInButton showActivityIndicator:authenticating];
}

- (void)updateSaveButton {
	if (![self isViewLoaded]) return;
	
    _signInButton.enabled = [self saveEnabled];
}

- (void)dismissKeyboard {
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

#pragma mark - Browser

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
        if (!_blog.jetpackUsername || !_blog.jetpackPassword) {
            _usernameField.text = [[WPAccount defaultWordPressComAccount] username];
            _passwordField.text = [[WPAccount defaultWordPressComAccount] password];
            [self updateSaveButton];
        }
        return;
    }
    [_blog syncOptionsWithWithSuccess:^{
        if ([_blog hasJetpack]) {
            [self updateMessage];
        }
    } failure:^(NSError *error) {
        [WPError showNetworkingAlertWithError:error];
    }];
}

- (void)tryLoginWithUsername:(NSString *)username andPassword:(NSString *)password {
    NSAssert(username != nil, @"Can't login with a nil username");
    NSAssert(password != nil, @"Can't login with a nil password");
    _usernameField.text = username;
    _passwordField.text = password;
	
    [self saveAction:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    BOOL isUsernameField = [touch.view isDescendantOfView:_usernameField];
    BOOL isSigninButton = [touch.view isDescendantOfView:_signInButton];
    if (isUsernameField || isSigninButton) {
        return NO;
    }
    return YES;
}

@end
