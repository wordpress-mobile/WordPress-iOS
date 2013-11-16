//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <WPXMLRPC/WPXMLRPC.h>
#import <QuartzCore/QuartzCore.h>
#import "UIView+FormSheetHelpers.h"
#import "LoginViewController.h"
#import "CreateAccountAndBlogViewController.h"
#import "NewAddUsersBlogViewController.h"
#import "AboutViewController.h"
#import "SupportViewController.h"
#import "WPNUXMainButton.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPWalkthroughTextField.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "Blog+Jetpack.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "JetpackSettingsViewController.h"
#import "WPWalkthroughOverlayView.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "ReachabilityUtils.h"
#import "WPNUXUtility.h"
#import "WPAccount.h"

@interface LoginViewController () <
    UIScrollViewDelegate,
    UITextFieldDelegate> {
        
    // Views
    UIView *_mainView;
    WPNUXSecondaryButton *_skipToCreateAccount;
    WPNUXSecondaryButton *_toggleSignInForm;
    UIButton *_infoButton;
    UIImageView *_icon;
    WPWalkthroughTextField *_usernameText;
    WPWalkthroughTextField *_passwordText;
    WPWalkthroughTextField *_siteUrlText;
    WPNUXMainButton *_signInButton;
    
    // Measurements
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    CGFloat _keyboardOffset;
    
    BOOL _userIsDotCom;
    BOOL _blogConnectedToJetpack;
    NSString *_dotComSiteUrl;
    NSArray *_blogs;
    Blog *_blog;
}

@end

@implementation LoginViewController

CGFloat const GeneralWalkthroughIconVerticalOffset = 77;
CGFloat const GeneralWalkthroughStandardOffset = 16;
CGFloat const GeneralWalkthroughMaxTextWidth = 289.0;
CGFloat const GeneralWalkthroughTextFieldWidth = 320.0;
CGFloat const GeneralWalkthroughTextFieldHeight = 44.0;
CGFloat const GeneralWalkthroughSignInButtonWidth = 289.0;
CGFloat const GeneralWalkthroughSignInButtonHeight = 41.0;
CGFloat const GeneralWalkthroughiOS7StatusBarOffset = 20.0;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
        
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
    _userIsDotCom = YES;

    [self addMainView];
    [self initializeView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughOpened];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {    
    if (textField == _usernameText) {
        [_passwordText becomeFirstResponder];
    } else if (textField == _passwordText) {
        if (_userIsDotCom) {
            [self clickedSignIn:nil];
        } else {
            [_siteUrlText becomeFirstResponder];
        }
    } else if (textField == _siteUrlText) {
        if (_signInButton.enabled) {
            [self clickedSignIn:nil];
        }
    }
    
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    _signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == _usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _passwordText) {
        isPasswordFilled = updatedStringHasContent;
    }
    _signInButton.enabled = isUsernameFilled && isPasswordFilled;
    
    return YES;
}

#pragma mark - Displaying of Error Messages

- (WPWalkthroughOverlayView *)baseLoginErrorOverlayView:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode;
    overlayView.overlayTitle = NSLocalizedString(@"Sorry, we can't log you in.", nil);
    overlayView.overlayDescription = message;
    overlayView.secondaryButtonText = NSLocalizedString(@"Need Help?", nil);
    overlayView.primaryButtonText = NSLocalizedString(@"OK", nil);
    overlayView.dismissCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    return overlayView;
}

- (void)displayErrorMessageForXMLRPC:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.primaryButtonText = NSLocalizedString(@"Enable Now", nil);
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedEnableXMLRPCServices];
        
        [overlayView dismiss];
        
        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rng = [regex rangeOfFirstMatchInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (rng.location == NSNotFound) {
            path = [self getSiteUrl];
            path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
            path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
        } else {
            path = [message substringWithRange:rng];
        }
        
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:path]];
        [webViewController setUsername:_usernameText.text];
        [webViewController setPassword:_passwordText.text];
        webViewController.shouldScrollToBottom = YES;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    [self.view addSubview:overlayView];
}

- (void)displayErrorMessageForBadUrl:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];  
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        webViewController.url = [NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)displayGenericErrorMessage:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

#pragma mark - Button Press Methods

- (void)clickedInfoButton:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedInfo];

    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:supportViewController];
    nc.navigationBar.translucent = NO;
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

- (void)clickedSkipToCreate:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount];
    [self showCreateAccountView];
}

- (void)clickedCreateAccount:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedCreateAccount];
    [self showCreateAccountView];
}

- (void)clickedBackground:(UITapGestureRecognizer *)tapGestureRecognizer
{
    
    [self.view endEditing:YES];

    // The info button is a little hard to hit so this adds a little buffer around it
    CGPoint touchPoint = [tapGestureRecognizer locationInView:self.view];
    CGFloat x = CGRectGetMaxX(_infoButton.frame) + 10;
    CGFloat y = CGRectGetMaxY(_infoButton.frame) + 10;
    CGRect infoButtonRect = CGRectMake(0, 0, x, y);
    if (CGRectContainsPoint(infoButtonRect, touchPoint)) {
        [self clickedInfoButton:nil];
    }
}

- (void)clickedSignIn:(id)sender
{
    [self.view endEditing:YES];

    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    if (![self areFieldsValid]) {
        [self displayErrorMessages];
        return;
    }
    
    [self signIn];
}

- (void)toggleSignInformAction:(id)sender {
    
    _userIsDotCom = !_userIsDotCom;
    
    // Only animate transition on iOS 7 due to snapshotting API
    if (IS_IOS7) {
        UIView *snapshot = [self.view snapshotViewAfterScreenUpdates:NO];
        [self.view addSubview:snapshot];
        [self initializeView];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             snapshot.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [snapshot removeFromSuperview];
                         }];
    } else {
        [self initializeView];
    }
}

#pragma mark - Private Methods

- (void)addMainView
{
    _mainView = [[UIView alloc] init];;
    _mainView.frame = self.view.bounds;
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_mainView];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = YES;
    [_mainView addGestureRecognizer:gestureRecognizer];
}

- (void)initializeView
{
    [self addControls];
    [self layoutControls];
}

- (void)addControls
{
    // Add Icon
    if (_icon == nil) {
        _icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-wp"]];
        [_mainView addSubview:_icon];
    }
    
    // Add Info button
    UIImage *infoButtonImage = [UIImage imageNamed:@"btn-help"];
    if (_infoButton == nil) {
        _infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_infoButton setImage:infoButtonImage forState:UIControlStateNormal];
        _infoButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [_infoButton addTarget:self action:@selector(clickedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_infoButton];
    }
    
    // Add Username
    if (_usernameText == nil) {
        _usernameText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
        _usernameText.backgroundColor = [UIColor whiteColor];
        _usernameText.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 2 Username Placeholder");
        _usernameText.font = [WPNUXUtility textFieldFont];
        _usernameText.adjustsFontSizeToFitWidth = YES;
        _usernameText.delegate = self;
        _usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_mainView addSubview:_usernameText];
    }
    
    // Add Password
    if (_passwordText == nil) {
        _passwordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _passwordText.backgroundColor = [UIColor whiteColor];
        _passwordText.placeholder = NSLocalizedString(@"Password", nil);
        _passwordText.font = [WPNUXUtility textFieldFont];
        _passwordText.delegate = self;
        _passwordText.secureTextEntry = YES;
        _passwordText.showTopLineSeparator = YES;
        [_mainView addSubview:_passwordText];
    }
    
    // Add Site Url
    if (_siteUrlText == nil) {
        _siteUrlText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
        _siteUrlText.backgroundColor = [UIColor whiteColor];
        _siteUrlText.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 2 Site Address Placeholder");
        _siteUrlText.font = [WPNUXUtility textFieldFont];
        _siteUrlText.adjustsFontSizeToFitWidth = YES;
        _siteUrlText.delegate = self;
        _siteUrlText.keyboardType = UIKeyboardTypeURL;
        _siteUrlText.returnKeyType = UIReturnKeyGo;
        _siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
        _siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _siteUrlText.showTopLineSeparator = YES;
        // insert URL field below password field to hide when signing into
        // WP.com account
        [_mainView insertSubview:_siteUrlText belowSubview:_passwordText];
    }
    _siteUrlText.enabled = !_userIsDotCom;
    
    // Add Sign In Button
    if (_signInButton == nil) {
        _signInButton = [[WPNUXMainButton alloc] init];
        [_signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
        [_signInButton addTarget:self action:@selector(clickedSignIn:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_signInButton];
        _signInButton.enabled = NO;
    }
    
    // Add Account type toggle
    if (_toggleSignInForm == nil) {
        _toggleSignInForm = [[WPNUXSecondaryButton alloc] init];
        [_toggleSignInForm addTarget:self action:@selector(toggleSignInformAction:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_toggleSignInForm];
    }
    NSString *toggleTitle = _userIsDotCom ? @"Add Self-Hosted Site" : @"Sign in to WordPress.com";
    [_toggleSignInForm setTitle:toggleTitle forState:UIControlStateNormal];
    [_toggleSignInForm sizeToFit];
    
    // Add Skip to Create Account Button
    if (_skipToCreateAccount == nil) {
        _skipToCreateAccount = [[WPNUXSecondaryButton alloc] init];
        [_skipToCreateAccount setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
        [_skipToCreateAccount addTarget:self action:@selector(clickedSkipToCreate:) forControlEvents:UIControlEventTouchUpInside];
        [_skipToCreateAccount sizeToFit];
        [_mainView addSubview:_skipToCreateAccount];
    }
}

- (void)layoutControls
{
    CGFloat x,y;
    
    UIImage *infoButtonImage = [UIImage imageNamed:@"btn-about"];
    y = 0;
    if (IS_IOS7 && IS_IPHONE) {
        y = GeneralWalkthroughiOS7StatusBarOffset;
    }
    _infoButton.frame = CGRectMake(0, y, infoButtonImage.size.width, infoButtonImage.size.height);
    
    x = (_viewWidth - CGRectGetWidth(_icon.frame))/2.0;
    y = GeneralWalkthroughIconVerticalOffset;
    _icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));

    // Layout Username
    x = (_viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_icon.frame) + GeneralWalkthroughStandardOffset;
    _usernameText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Password
    x = (_viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameText.frame) - 1;
    _passwordText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Site URL
    x = (_viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = _userIsDotCom ? CGRectGetMaxY(_usernameText.frame) - 1 : CGRectGetMaxY(_passwordText.frame);
    _siteUrlText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Sign in Button
    x = (_viewWidth - GeneralWalkthroughSignInButtonWidth) / 2.0;;
    y = CGRectGetMaxY(_siteUrlText.frame) + GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectMake(x, y, GeneralWalkthroughSignInButtonWidth, GeneralWalkthroughSignInButtonHeight);
    
    // Layout Skip to Create Account Button
    x = GeneralWalkthroughStandardOffset;
    x = (_viewWidth - CGRectGetWidth(_skipToCreateAccount.frame))/2.0;
    y = CGRectGetMaxY(_mainView.frame) - GeneralWalkthroughStandardOffset - 33;
    _skipToCreateAccount.frame = CGRectMake(x, y, CGRectGetWidth(_skipToCreateAccount.frame), 33);
    
    // Layout Toggle Button
    x = GeneralWalkthroughStandardOffset;
    x = (_viewWidth - CGRectGetWidth(_toggleSignInForm.frame))/2.0;
    y = CGRectGetMinY(_skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - 33;
    _toggleSignInForm.frame = CGRectMake(x, y, CGRectGetWidth(_toggleSignInForm.frame), 33);
    
    
    NSArray *viewsToCenter = @[_icon, _usernameText, _passwordText, _siteUrlText, _signInButton];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_icon andEndingView:_signInButton forHeight:_viewHeight - (_viewHeight-CGRectGetMinY(_toggleSignInForm.frame))];
}

- (void)showCompletionWalkthrough
{
    LoginCompletedWalkthroughViewController *loginCompletedViewController = [[LoginCompletedWalkthroughViewController alloc] init];
    loginCompletedViewController.showsExtraWalkthroughPages = _userIsDotCom || _blogConnectedToJetpack;
    [self.navigationController pushViewController:loginCompletedViewController animated:YES];
}

- (void)showCreateAccountView
{
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    createAccountViewController.onCreatedUser = ^(NSString *username, NSString *password) {
        _usernameText.text = username;
        _passwordText.text = password;
        _userIsDotCom = YES;
        [self.navigationController popViewControllerAnimated:NO];
        [self showAddUsersBlogsForWPCom];
    };
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)showJetpackAuthentication
{
    [SVProgressHUD dismiss];
    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:_blog];
    jetpackSettingsViewController.canBeSkipped = YES;
    [jetpackSettingsViewController setCompletionBlock:^(BOOL didAuthenticate) {
        _blogConnectedToJetpack = didAuthenticate;
        
        if (_blogConnectedToJetpack) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserConnectedToJetpack];
        } else {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSkippedConnectingToJetpack];            
        }
        
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    }];
    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}

- (void)showHelpViewController:(BOOL)animated
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:supportViewController animated:animated];
}

- (BOOL)isUrlWPCom:(NSString *)url
{
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[url trim] length])];
    
    return [result count] != 0;
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    NSString *url = [siteURL absoluteString];
    
    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if ([self isUrlWPCom:url]) {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"https://%@", url];
        } else {
            if ([url rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [url length])];
            }
        }
    } else {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
    }
    
    NSRegularExpression *wplogin = [NSRegularExpression regularExpressionWithPattern:@"/wp-login.php$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *wpadmin = [NSRegularExpression regularExpressionWithPattern:@"/wp-admin/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *trailingslash = [NSRegularExpression regularExpressionWithPattern:@"/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    url = [wplogin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [wpadmin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [trailingslash stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    
    return url;
}

- (BOOL)areFieldsValid
{
    if ([self areSelfHostedFieldsFilled] && !_userIsDotCom) {
        return [self isUrlValid];
    } else {
        return [self areDotComFieldsFilled];
    }
}

- (BOOL)isUsernameFilled
{
    return [[_usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[_passwordText.text trim] length] != 0;
}

- (BOOL)areDotComFieldsFilled
{
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)areSelfHostedFieldsFilled
{
    return [self areDotComFieldsFilled] && [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)hasUserOnlyEnteredValuesForDotCom
{
    return [self areDotComFieldsFilled] && ![self areSelfHostedFieldsFilled];
}

- (BOOL)areFieldsFilled
{
    return [[_usernameText.text trim] length] != 0 && [[_passwordText.text trim] length] != 0 && [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)isUrlValid
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    return siteURL != nil;
}

- (void)displayErrorMessages
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)signIn
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = _usernameText.text;
    NSString *password = _passwordText.text;
    _dotComSiteUrl = nil;
    
    if (_userIsDotCom) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithoutUrl];
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithUrl];
    
    if ([self isUrlWPCom:_siteUrlText.text]) {
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }
        
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];
        
        [api getBlogOptionsWithSuccess:^(id options){
            [SVProgressHUD dismiss];
            
            if ([options objectForKey:@"wordpress.com"] != nil) {
                NSDictionary *siteUrl = [options dictionaryForKey:@"home_url"];
                _dotComSiteUrl = [siteUrl objectForKey:@"value"];
                [self signInForWPComForUsername:username andPassword:password];
            } else {
                [self signInForSelfHostedForUsername:username password:password options:options andApi:api];
            }
        } failure:^(NSError *error){
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        }];
    };
    
    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [self handleGuessXMLRPCURLFailure:error];
    };
    
    [WordPressXMLRPCApi guessXMLRPCURLForSite:_siteUrlText.text success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)signInForWPComForUsername:(NSString *)username andPassword:(NSString *)password
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForDotCom];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to WordPress.com", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    void (^loginSuccessBlock)(void) = ^{
        [SVProgressHUD dismiss];
        _userIsDotCom = YES;
        [self showAddUsersBlogsForWPCom];
    };
    
    void (^loginFailBlock)(NSError *) = ^(NSError *error){
        // User shouldn't get here because the getOptions call should fail, but in the unlikely case they do throw up an error message.
        [SVProgressHUD dismiss];
        DDLogError(@"Login failed with username %@ : %@", username, error);
        [self displayGenericErrorMessage:NSLocalizedString(@"Please try entering your login details again.", nil)];
    };
    
    [[WordPressComApi sharedApi] signInWithUsername:username
                                           password:password
                                            success:loginSuccessBlock
                                            failure:loginFailBlock];
    
}

- (void)signInForSelfHostedForUsername:(NSString *)username password:(NSString *)password options:(NSDictionary *)options andApi:(WordPressXMLRPCApi *)api
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForSelfHosted];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    [api getBlogsWithSuccess:^(NSArray *blogs) {
        _blogs = blogs;
        [self handleGetBlogsSuccess:[api.xmlrpc absoluteString]];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    }];
}

- (void)handleGuessXMLRPCURLFailure:(NSError *)error
{
    [SVProgressHUD dismiss];
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        [self displayRemoteError:nil];
    } else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
        [self displayRemoteError:error];
    } else if([error.domain isEqual:AFNetworkingErrorDomain]) {
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", nil), [error localizedDescription]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  str, NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
        [self displayRemoteError:err];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil), NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
        [self displayRemoteError:err];
    }
}

- (void)handleGetBlogsSuccess:(NSString *)xmlRPCUrl {
    if ([_blogs count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install,
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([_blogs count] > 1) {
            subsite = [[_blogs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlRPCUrl]] lastObject];
        }
        
        if (subsite == nil) {
            subsite = [_blogs objectAtIndex:0];
        }
        
        if ([_blogs count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            [SVProgressHUD dismiss];
            [self showAddUsersBlogsForSelfHosted:xmlRPCUrl];
        } else {
            [self createBlogWithXmlRpc:xmlRPCUrl andBlogDetails:subsite];
            [self synchronizeNewlyAddedBlog];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", nil)}];
        [self displayRemoteError:error];
    }
}

- (void)displayRemoteError:(NSError *)error {
    NSString *message = [error localizedDescription];
    if (![[error domain] isEqualToString:WPXMLRPCFaultErrorDomain]) {
        [self displayGenericErrorMessage:message];
        return;
    }
    if ([error code] == 403) {
        message = NSLocalizedString(@"Please try entering your login details again.", nil);
    }
    
    if ([[message trim] length] == 0) {
        message = NSLocalizedString(@"Sign in failed. Please try again.", nil);
    }
    
    if ([error code] == 405) {
        [self displayErrorMessageForXMLRPC:message];
    } else {
        if ([error code] == NSURLErrorBadURL) {
            [self displayErrorMessageForBadUrl:message];
        } else {
            [self displayGenericErrorMessage:message];
        }
    }
}

- (NewAddUsersBlogViewController *)addUsersBlogViewController:(NSString *)xmlRPCUrl
{
    BOOL isWPCom = (xmlRPCUrl == nil);
    NewAddUsersBlogViewController *vc = [[NewAddUsersBlogViewController alloc] init];
    vc.account = [self createAccountWithUsername:_usernameText.text andPassword:_passwordText.text isWPCom:isWPCom xmlRPCUrl:xmlRPCUrl];
    vc.blogAdditionCompleted = ^(NewAddUsersBlogViewController * viewController){
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onNoBlogsLoaded = ^(NewAddUsersBlogViewController *viewController) {
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onErrorLoading = ^(NewAddUsersBlogViewController *viewController, NSError *error) {
        DDLogError(@"There was an error loading blogs after sign in");
        [self.navigationController popViewControllerAnimated:YES];
        [self displayGenericErrorMessage:[error localizedDescription]];
    };
    
    return vc;
}

- (void)showAddUsersBlogsForSelfHosted:(NSString *)xmlRPCUrl
{
    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController:xmlRPCUrl];

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAddUsersBlogsForWPCom
{
    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController:nil];

    NSString *siteUrl = [_siteUrlText.text trim];
    if ([siteUrl length] != 0) {
        vc.siteUrl = siteUrl;
    } else if ([_dotComSiteUrl length] != 0) {
        vc.siteUrl = _dotComSiteUrl;
    }

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlRPCUrl andBlogDetails:(NSDictionary *)blogDetails
{
    NSParameterAssert(blogDetails != nil);
    
    WPAccount *account = [self createAccountWithUsername:_usernameText.text andPassword:_passwordText.text isWPCom:NO xmlRPCUrl:xmlRPCUrl];
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:xmlRPCUrl forKey:@"xmlrpc"];

    _blog = [account findOrCreateBlogFromDictionary:newBlog withContext:account.managedObjectContext];
    [_blog dataSave];

}

- (WPAccount *)createAccountWithUsername:(NSString *)username andPassword:(NSString *)password isWPCom:(BOOL)isWPCom xmlRPCUrl:(NSString *)xmlRPCUrl {
    WPAccount *account;
    if (isWPCom) {
        account = [WPAccount createOrUpdateWordPressComAccountWithUsername:username andPassword:password];
    } else {
        account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlRPCUrl username:username andPassword:password];
    }
    return account;
}

- (void)synchronizeNewlyAddedBlog
{
    [SVProgressHUD setStatus:NSLocalizedString(@"Synchronizing Blog", nil)];
    void (^successBlock)() = ^{
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
        [SVProgressHUD dismiss];
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack];
        if ([_blog hasJetpack]) {
            [self showJetpackAuthentication];
        } else {
            [self showCompletionWalkthrough];
        }
    };
    void (^failureBlock)(NSError*) = ^(NSError * error) {
        [SVProgressHUD dismiss];
    };
    [_blog syncBlogWithSuccess:successBlock failure:failureBlock];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    _keyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_signInButton.frame);

    if (_keyboardOffset < 0) {
        _keyboardOffset = 0;
        return;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        NSArray *controlsToMove = @[_icon, _usernameText, _passwordText, _siteUrlText, _signInButton];
        NSArray *controlsToHide = @[_infoButton];
        
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
        NSArray *controlsToMove = @[_icon, _usernameText, _passwordText, _siteUrlText, _signInButton];
        NSArray *controlsToHide = @[_infoButton];

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

@end