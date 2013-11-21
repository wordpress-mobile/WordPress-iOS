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
#import "WordPressComOAuthClient.h"
#import "WPWebViewController.h"
#import "Blog+Jetpack.h"
#import "JetpackSettingsViewController.h"
#import "WPWalkthroughOverlayView.h"
#import "ReachabilityUtils.h"
#import "WPNUXUtility.h"
#import "WPAccount.h"
#import "ReaderPost.h"
#import "Note.h"

@interface LoginViewController () <
    UITextFieldDelegate> {
        
    // Views
    UIView *_mainView;
    WPNUXSecondaryButton *_skipToCreateAccount;
    WPNUXSecondaryButton *_toggleSignInForm;
    UIButton *_helpButton;
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
CGFloat const GeneralWalkthroughButtonWidth = 289.0;
CGFloat const GeneralWalkthroughButtonHeight = 41.0;
CGFloat const GeneralWalkthroughSecondaryButtonHeight = 33;
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
            [self signInButtonAction:nil];
        } else {
            [_siteUrlText becomeFirstResponder];
        }
    } else if (textField == _siteUrlText) {
        if (_signInButton.enabled) {
            [self signInButtonAction:nil];
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

- (void)helpButtonAction:(id)sender
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
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedCreateAccount];
    [self showCreateAccountView];
}

- (void)clickedBackground:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.view endEditing:YES];

    // The info button is a little hard to hit so this adds a little buffer around it
    CGPoint touchPoint = [tapGestureRecognizer locationInView:self.view];
    CGFloat x = CGRectGetMaxX(_helpButton.frame) + 10;
    CGFloat y = CGRectGetMaxY(_helpButton.frame) + 10;
    CGRect infoButtonRect = CGRectMake(0, 0, x, y);
    if (CGRectContainsPoint(infoButtonRect, touchPoint)) {
        [self helpButtonAction:nil];
    }
}

- (void)signInButtonAction:(id)sender
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
    
    // Controls are layed out in initializeView. Calling this method in an animation block will animate the controls to their new positions. 
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self initializeView];
                     }];
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
    if (_helpButton == nil) {
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_helpButton setImage:infoButtonImage forState:UIControlStateNormal];
        _helpButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [_helpButton addTarget:self action:@selector(helpButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_helpButton];
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
        [_signInButton addTarget:self action:@selector(signInButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_signInButton];
        _signInButton.enabled = NO;
    }
    
    // Add Account type toggle
    if (_toggleSignInForm == nil) {
        _toggleSignInForm = [[WPNUXSecondaryButton alloc] init];
        [_toggleSignInForm addTarget:self action:@selector(toggleSignInformAction:) forControlEvents:UIControlEventTouchUpInside];
        [_mainView addSubview:_toggleSignInForm];
    }
    NSString *toggleTitle = _userIsDotCom ? NSLocalizedString(@"Add Self-Hosted Site", nil) : NSLocalizedString(@"Sign in to WordPress.com", nil);
    [_toggleSignInForm setTitle:toggleTitle forState:UIControlStateNormal];
    
    // Add Skip to Create Account Button
    if (_skipToCreateAccount == nil) {
        _skipToCreateAccount = [[WPNUXSecondaryButton alloc] init];
        [_skipToCreateAccount setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
        [_skipToCreateAccount addTarget:self action:@selector(clickedSkipToCreate:) forControlEvents:UIControlEventTouchUpInside];
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
    _helpButton.frame = CGRectMake(_viewWidth - infoButtonImage.size.width, y, infoButtonImage.size.width, infoButtonImage.size.height);
    
    
    CGFloat heightOfControls = CGRectGetHeight(_icon.frame) + GeneralWalkthroughStandardOffset + (_userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldHeight + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonHeight;
    CGFloat startingYForCenteredControls = floorf((_viewHeight - 2 * GeneralWalkthroughSecondaryButtonHeight - heightOfControls)/2.0);
    
    x = (_viewWidth - CGRectGetWidth(_icon.frame))/2.0;
    y = startingYForCenteredControls;
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
    x = (_viewWidth - GeneralWalkthroughButtonWidth) / 2.0;;
    y = CGRectGetMaxY(_siteUrlText.frame) + GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectMake(x, y, GeneralWalkthroughButtonWidth, GeneralWalkthroughButtonHeight);
    
    // Layout Skip to Create Account Button
    x = GeneralWalkthroughStandardOffset;
    x = (_viewWidth - GeneralWalkthroughButtonWidth)/2.0;
    y = _viewHeight - GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    _skipToCreateAccount.frame = CGRectMake(x, y, GeneralWalkthroughButtonWidth, GeneralWalkthroughSecondaryButtonHeight);
    
    // Layout Toggle Button
    x = GeneralWalkthroughStandardOffset;
    x = (_viewWidth - GeneralWalkthroughButtonWidth)/2.0;
    y = CGRectGetMinY(_skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    _toggleSignInForm.frame = CGRectMake(x, y, GeneralWalkthroughButtonWidth, GeneralWalkthroughSecondaryButtonHeight);
}

- (void)dismiss
{
    self.parentViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showCreateAccountView
{
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    createAccountViewController.onCreatedUser = ^(NSString *username, NSString *password) {
        _usernameText.text = username;
        _passwordText.text = password;
        _userIsDotCom = YES;
        [self.navigationController popViewControllerAnimated:NO];
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
        
        [self dismiss];
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
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self createSelfHostedAccountAndBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
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
    
    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                             success:^(NSString *authToken) {
                                 [SVProgressHUD dismiss];
                                 _userIsDotCom = YES;
                                 [self createWordPressComAccountForUsername:username password:password authToken:authToken];
                             } failure:^(NSError *error) {
                                 [SVProgressHUD dismiss];
                                 [self displayRemoteError:error];
                             }];
}

- (void)createWordPressComAccountForUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Getting account information", @"") maskType:SVProgressHUDMaskTypeBlack];
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken];
    if (![WPAccount defaultWordPressComAccount]) {
        [WPAccount setDefaultWordPressComAccount:account];
    }
    [account syncBlogsWithSuccess:^{
        [SVProgressHUD dismiss];
        [self dismiss];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    }];
    [ReaderPost fetchPostsWithCompletionHandler:nil];
    [account.restApi getNotificationsSince:nil success:nil failure:nil];
}

- (void)createSelfHostedAccountAndBlogWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options
{
    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    NSMutableDictionary *blogDetails = [NSMutableDictionary dictionaryWithObject:xmlrpc forKey:@"xmlrpc"];
    if (blogName) {
        [blogDetails setObject:blogName forKey:@"blogName"];
    }
    if (url) {
        [blogDetails setObject:url forKey:@"url"];
    }
    _blog = [account findOrCreateBlogFromDictionary:blogDetails withContext:account.managedObjectContext];
    _blog.options = options;
    [_blog dataSave];
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack];
    [_blog syncBlogWithSuccess:nil failure:nil];

    if ([_blog hasJetpack]) {
        [self showJetpackAuthentication];
    } else {
        [self dismiss];
    }
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

- (void)displayRemoteError:(NSError *)error {
    DDLogError(@"%@", error);
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
        NSArray *controlsToHide = @[_helpButton];
        
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
        NSArray *controlsToHide = @[_helpButton];

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
