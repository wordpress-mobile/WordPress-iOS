//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <WPXMLRPC/WPXMLRPC.h>
#import <QuartzCore/QuartzCore.h>
#import "LoginViewController.h"
#import "CreateAccountAndBlogViewController.h"
#import "AboutViewController.h"
#import "SupportViewController.h"
#import "WPNUXMainButton.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPWalkthroughTextField.h"
#import "WordPressComOAuthClient.h"
#import "WPWebViewController.h"
#import "EditPostViewController.h"
#import "Blog+Jetpack.h"
#import "JetpackSettingsViewController.h"
#import "WPWalkthroughOverlayView.h"
#import "ReachabilityUtils.h"
#import "WPNUXUtility.h"
#import "WPNUXBackButton.h"
#import "WPAccount.h"
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
    WPNUXSecondaryButton *_cancelButton;

    UILabel *_statusLabel;
    
    // Measurements
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
CGFloat const GeneralWalkthroughStandardOffset = 15;
CGFloat const GeneralWalkthroughMaxTextWidth = 290.0;
CGFloat const GeneralWalkthroughTextFieldWidth = 320.0;
CGFloat const GeneralWalkthroughTextFieldHeight = 44.0;
CGFloat const GeneralWalkthroughButtonWidth = 290.0;
CGFloat const GeneralWalkthroughButtonHeight = 41.0;
CGFloat const GeneralWalkthroughSecondaryButtonHeight = 33;
CGFloat const GeneralWalkthroughStatusBarOffset = 20.0;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
    _userIsDotCom = self.onlyDotComAllowed || !self.prefersSelfHosted;
    if ([WPAccount defaultWordPressComAccount]) {
        _userIsDotCom = NO;
    }

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
    [self layoutControls];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [self layoutControls];
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
    _signInButton.enabled = [self isSignInEnabled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    _signInButton.enabled = [self isSignInEnabled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    BOOL isSiteUrlFilled = [self isSiteUrlFilled];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == _usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _passwordText) {
        isPasswordFilled = updatedStringHasContent;
    } else if (textField == _siteUrlText) {
        isSiteUrlFilled = updatedStringHasContent;
    }
    _signInButton.enabled = isUsernameFilled && isPasswordFilled && (_userIsDotCom || isSiteUrlFilled);
    
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

- (void)skipToCreateAction:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedCreateAccount];
    [self showCreateAccountView];
}

- (void)backgroundTapGestureAction:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.view endEditing:YES];
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

- (void)toggleSignInFormAction:(id)sender {
    _userIsDotCom = !_userIsDotCom;
    
    // Controls are layed out in initializeView. Calling this method in an animation block will animate the controls to their new positions. 
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self initializeView];
                     }];
}

- (void)cancelButtonAction:(id)sender {
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}

#pragma mark - Private Methods

- (void)addMainView
{
    _mainView = [[UIView alloc] init];;
    _mainView.frame = self.view.bounds;
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_mainView];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapGestureAction:)];
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
        _icon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_mainView addSubview:_icon];
    }
    
    // Add Info button
    UIImage *infoButtonImage = [UIImage imageNamed:@"btn-help"];
    if (_helpButton == nil) {
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_helpButton setImage:infoButtonImage forState:UIControlStateNormal];
        _helpButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        _helpButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_helpButton addTarget:self action:@selector(helpButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_helpButton sizeToFit];
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
        _usernameText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
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
        _passwordText.showSecureTextEntryToggle = YES;
        _passwordText.showTopLineSeparator = YES;
        _passwordText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
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
        _siteUrlText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        // insert URL field below password field to hide when signing into
        // WP.com account
        [_mainView insertSubview:_siteUrlText belowSubview:_passwordText];
    }
    _siteUrlText.enabled = !_userIsDotCom;
    
    // Add Sign In Button
    if (_signInButton == nil) {
        _signInButton = [[WPNUXMainButton alloc] init];
        [_signInButton addTarget:self action:@selector(signInButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _signInButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_mainView addSubview:_signInButton];
        _signInButton.enabled = NO;
    }
    
    NSString *signInTitle;
    if (_userIsDotCom) {
        signInTitle = NSLocalizedString(@"Sign In", nil);
    } else {
        signInTitle = NSLocalizedString(@"Add Site", nil);
    }
    [_signInButton setTitle:signInTitle forState:UIControlStateNormal];

    // Add Cancel Button
    if (self.dismissBlock && _cancelButton == nil) {
        _cancelButton = [[WPNUXSecondaryButton alloc] init];
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton sizeToFit];
        [self.view addSubview:_cancelButton];
    }

    // Add status label
    if (_statusLabel == nil) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [WPNUXUtility confirmationLabelFont];
        _statusLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _statusLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [_mainView addSubview:_statusLabel];
    }
    
    // Add Account type toggle
    if (_toggleSignInForm == nil) {
        _toggleSignInForm = [[WPNUXSecondaryButton alloc] init];
        [_toggleSignInForm addTarget:self action:@selector(toggleSignInFormAction:) forControlEvents:UIControlEventTouchUpInside];
        _toggleSignInForm.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [_mainView addSubview:_toggleSignInForm];
    }
    if (!self.onlyDotComAllowed && ![WPAccount defaultWordPressComAccount]) {
        // Add Account type toggle
        if (_toggleSignInForm == nil) {
            _toggleSignInForm = [[WPNUXSecondaryButton alloc] init];
            [_toggleSignInForm addTarget:self action:@selector(toggleSignInFormAction:) forControlEvents:UIControlEventTouchUpInside];
            [_mainView addSubview:_toggleSignInForm];
        }
        NSString *toggleTitle;
        if (_userIsDotCom) {
            toggleTitle = NSLocalizedString(@"Add Self-Hosted Site", nil);
        } else {
            toggleTitle = NSLocalizedString(@"Sign in to WordPress.com", nil);
        }
        [_toggleSignInForm setTitle:toggleTitle forState:UIControlStateNormal];
    }

    if (![WPAccount defaultWordPressComAccount]) {
        // Add Skip to Create Account Button
        if (_skipToCreateAccount == nil) {
            _skipToCreateAccount = [[WPNUXSecondaryButton alloc] init];
            _skipToCreateAccount.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
            [_skipToCreateAccount setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
            [_skipToCreateAccount addTarget:self action:@selector(skipToCreateAction:) forControlEvents:UIControlEventTouchUpInside];
            [_mainView addSubview:_skipToCreateAccount];
        }
    }
}

- (void)layoutControls
{
    CGFloat x,y;
    
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    // Layout Help Button
    x = viewWidth - CGRectGetWidth(_helpButton.frame) - GeneralWalkthroughStandardOffset;
    y = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    _helpButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_helpButton.frame), GeneralWalkthroughButtonHeight));
    
    // Layout Cancel Button
    x = 0;
    y = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    _cancelButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_cancelButton.frame), GeneralWalkthroughButtonHeight));

    // Calculate total height and starting Y origin of controls
    CGFloat heightOfControls = CGRectGetHeight(_icon.frame) + GeneralWalkthroughStandardOffset + (_userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldHeight + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonHeight;
    CGFloat startingYForCenteredControls = floorf((viewHeight - 2 * GeneralWalkthroughSecondaryButtonHeight - heightOfControls)/2.0);
    
    x = (viewWidth - CGRectGetWidth(_icon.frame))/2.0;
    y = startingYForCenteredControls;
    _icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));

    // Layout Username
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_icon.frame) + GeneralWalkthroughStandardOffset;
    _usernameText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Password
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameText.frame) - 1;
    _passwordText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Site URL
    x = (viewWidth - GeneralWalkthroughTextFieldWidth)/2.0;
    y = _userIsDotCom ? CGRectGetMaxY(_usernameText.frame) - 1 : CGRectGetMaxY(_passwordText.frame);
    _siteUrlText.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughTextFieldWidth, GeneralWalkthroughTextFieldHeight));

    // Layout Sign in Button
    x = (viewWidth - GeneralWalkthroughButtonWidth) / 2.0;;
    y = CGRectGetMaxY(_siteUrlText.frame) + GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughButtonWidth, GeneralWalkthroughButtonHeight));
    
    // Layout Skip to Create Account Button
    x = GeneralWalkthroughStandardOffset;
    x = (viewWidth - GeneralWalkthroughButtonWidth)/2.0;
    y = viewHeight - GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    _skipToCreateAccount.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughButtonWidth, GeneralWalkthroughSecondaryButtonHeight));
    
    // Layout Status Label
    x =  (viewWidth - GeneralWalkthroughMaxTextWidth) / 2.0;
    y = CGRectGetMaxY(_signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    _statusLabel.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughMaxTextWidth, _statusLabel.font.lineHeight));
    
    // Layout Toggle Button
    x =  (viewWidth - GeneralWalkthroughMaxTextWidth) / 2.0;
    y = CGRectGetMinY(_skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - 33;
    _toggleSignInForm.frame = CGRectIntegral(CGRectMake(x, y, GeneralWalkthroughMaxTextWidth, 33));
}

- (void)dismiss
{
    WordPressAppDelegate *delegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // If we were invoked from the post tab proceed to the editor. Our work here is done.
    if (_showEditorAfterAddingSites) {
        [delegate showPostTab];
        return;
    }
    
    // Check if there is an active WordPress.com account. If not, switch tab bar
    // away from Reader to // blog list view
    if (![WPAccount defaultWordPressComAccount]) {
        [delegate showBlogListTab];
    }
    
    self.parentViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showCreateAccountView
{
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)showJetpackAuthentication
{
    [self setAuthenticating:NO withStatusMessage:nil];
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

- (BOOL)isSiteUrlFilled
{
    return [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)isSignInEnabled
{
    return _userIsDotCom ? [self areDotComFieldsFilled] : [self areSelfHostedFieldsFilled];
}

- (BOOL)areDotComFieldsFilled
{
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)areSelfHostedFieldsFilled
{
    return [self areDotComFieldsFilled] && [self isSiteUrlFilled];
}

- (BOOL)hasUserOnlyEnteredValuesForDotCom
{
    return [self areDotComFieldsFilled] && ![self areSelfHostedFieldsFilled];
}

- (BOOL)isUrlValid
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    return siteURL != nil;
}

- (void)displayErrorMessages
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) withSupportButton:NO];
}

- (void)setAuthenticating:(BOOL)authenticating withStatusMessage:(NSString *)status {
    
    _statusLabel.hidden = !(status.length > 0);
    _statusLabel.text = status;
    
    _signInButton.enabled = !authenticating;
    _toggleSignInForm.hidden = authenticating;
    _skipToCreateAccount.hidden = authenticating;
    _cancelButton.enabled = !authenticating;
    [_signInButton showActivityIndicator:authenticating];
}

- (void)signIn
{
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Authenticating", nil)];
    
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
            [self setAuthenticating:NO withStatusMessage:nil];
            
            if ([options objectForKey:@"wordpress.com"] != nil) {
                NSDictionary *siteUrl = [options dictionaryForKey:@"home_url"];
                _dotComSiteUrl = [siteUrl objectForKey:@"value"];
                [self signInForWPComForUsername:username andPassword:password];
            } else {
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self createSelfHostedAccountAndBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
            }
        } failure:^(NSError *error){
            [self setAuthenticating:NO withStatusMessage:nil];
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
    
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    
    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                             success:^(NSString *authToken) {
                                 [self setAuthenticating:NO withStatusMessage:nil];
                                 _userIsDotCom = YES;
                                 [self createWordPressComAccountForUsername:username password:password authToken:authToken];
                             } failure:^(NSError *error) {
                                 [self setAuthenticating:NO withStatusMessage:nil];
                                 [self displayRemoteError:error];
                             }];
}

- (void)createWordPressComAccountForUsername:(NSString *)username password:(NSString *)password authToken:(NSString *)authToken
{
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Getting account information", nil)];
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken];
    if (![WPAccount defaultWordPressComAccount]) {
        [WPAccount setDefaultWordPressComAccount:account];
    }
    [account syncBlogsWithSuccess:^{
        [self setAuthenticating:NO withStatusMessage:nil];
        [self dismiss];
    } failure:^(NSError *error) {
        [self setAuthenticating:NO withStatusMessage:nil];
        [self displayRemoteError:error];
    }];
    [Note fetchNewNotificationsWithSuccess:nil failure:nil];
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
    [self setAuthenticating:NO withStatusMessage:nil];
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
    CGFloat newKeyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + GeneralWalkthroughStandardOffset;

    if (newKeyboardOffset < 0) {
        newKeyboardOffset = 0;
        return;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveForTextEntry]) {
            CGRect frame = control.frame;
            frame.origin.y -= newKeyboardOffset;
            control.frame = frame;
        }
        
        for (UIControl *control in [self controlsToHideForTextEntry]) {
            control.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        
        _keyboardOffset += newKeyboardOffset;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGFloat currentKeyboardOffset = _keyboardOffset;
    _keyboardOffset = 0;

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveForTextEntry]) {
            CGRect frame = control.frame;
            frame.origin.y += currentKeyboardOffset;
            control.frame = frame;
        }
        
        for (UIControl *control in [self controlsToHideForTextEntry]) {
            control.alpha = 1.0;
        }
    }];
}

- (NSArray *)controlsToMoveForTextEntry {
    
    return @[_icon, _usernameText, _passwordText, _siteUrlText, _signInButton, _statusLabel];
}
- (NSArray *)controlsToHideForTextEntry {
    
    NSArray *controlsToHide = @[_helpButton];
    
    // Hide the
    BOOL isSmallScreen = !(CGRectGetHeight(self.view.bounds) > 480.0);
    if (isSmallScreen) {
        controlsToHide = [controlsToHide arrayByAddingObject:_icon];
    }
    return controlsToHide;
}


@end
