#import <WPXMLRPC/WPXMLRPC.h>
#import <Helpshift/Helpshift.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <1PasswordExtension/OnePasswordExtension.h>

#import "CreateAccountAndBlogViewController.h"
#import "SupportViewController.h"
#import "LoginViewController.h"
#import "JetpackSettingsViewController.h"

#import "WPAccount.h"
#import "WPNUXMainButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPNUXUtility.h"
#import "WPNUXHelpBadgeLabel.h"
#import "WPTabBarController.h"
#import "WPWalkthroughTextField.h"
#import "WPWalkthroughOverlayView.h"
#import "WPWebViewController.h"

#import "WordPressComOAuthClient.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "Blog+Jetpack.h"

#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "NSURL+IDN.h"

#import "Constants.h"
#import "ReachabilityUtils.h"
#import "HelpshiftUtils.h"
#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString *const ForgotPasswordDotComBaseUrl              = @"https://wordpress.com";
static NSString *const ForgotPasswordRelativeUrl                = @"/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F";
static NSString *const GenerateApplicationSpecificPasswordUrl   = @"http://en.support.wordpress.com/security/two-step-authentication/#application-specific-passwords";

static CGFloat const GeneralWalkthroughStandardOffset           = 15.0;
static CGFloat const GeneralWalkthroughMaxTextWidth             = 290.0;
static CGSize const GeneralWalkthroughTextFieldSize             = {320.0, 44.0};
static CGFloat const GeneralWalkthroughTextFieldOverlapY        = 1.0;
static CGSize const GeneralWalkthroughButtonSize                = {290.0, 41.0};
static CGFloat const GeneralWalkthroughSecondaryButtonHeight    = 33.0;
static CGFloat const GeneralWalkthroughStatusBarOffset          = 20.0;

static NSTimeInterval const GeneralWalkthroughAnimationDuration = 0.3f;
static CGFloat const GeneralWalkthroughAlphaHidden              = 0.0f;
static CGFloat const GeneralWalkthroughAlphaDisabled            = 0.5f;
static CGFloat const GeneralWalkthroughAlphaEnabled             = 1.0f;

static CGFloat const OnePasswordPaddingX                        = 9.0;
static CGFloat const HiddenControlsHeightThreshold              = 480.0;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface LoginViewController () <UITextFieldDelegate>

// Views
@property (nonatomic, strong) UIView                    *mainView;
@property (nonatomic, strong) WPNUXSecondaryButton      *skipToCreateAccount;
@property (nonatomic, strong) WPNUXSecondaryButton      *toggleSignInForm;
@property (nonatomic, strong) WPNUXSecondaryButton      *forgotPassword;
@property (nonatomic, strong) UIButton                  *helpButton;
@property (nonatomic, strong) WPNUXHelpBadgeLabel       *helpBadge;
@property (nonatomic, strong) UIImageView               *icon;
@property (nonatomic, strong) WPWalkthroughTextField    *usernameText;
@property (nonatomic, strong) WPWalkthroughTextField    *passwordText;
@property (nonatomic, strong) UIButton                  *onePasswordButton;
@property (nonatomic, strong) WPWalkthroughTextField    *multifactorText;
@property (nonatomic, strong) WPWalkthroughTextField    *siteUrlText;
@property (nonatomic, strong) WPNUXMainButton           *signInButton;
@property (nonatomic, strong) WPNUXSecondaryButton      *cancelButton;
@property (nonatomic, strong) UILabel                   *statusLabel;

// Measurements
@property (nonatomic, strong) Blog                      *blog;
@property (nonatomic, assign) CGFloat                   keyboardOffset;
@property (nonatomic, assign) NSUInteger                numberOfTimesLoginFailed;
@property (nonatomic, assign) BOOL                      userIsDotCom;
@property (nonatomic, assign) BOOL                      hasDefaultAccount;
@property (nonatomic, assign) BOOL                      shouldDisplayMultifactor;

@end


#pragma mark ====================================================================================
#pragma mark LoginViewController
#pragma mark ====================================================================================

@implementation LoginViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [WPStyleGuide wordPressBlue];
    
    // Do we have a default account?
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    // Initialize flags!
    self.hasDefaultAccount = (defaultAccount != nil);
    self.userIsDotCom = (defaultAccount == nil) && (self.onlyDotComAllowed || !self.prefersSelfHosted);

    // Initialize Interface
    [self addMainView];
    [self addControls];
    
    // Reauth: Pre-populate username. If needed
    if (!self.shouldReauthenticateDefaultAccount) {
        return;
    }
    
    self.usernameText.text = defaultAccount.username;
    self.userIsDotCom = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(helpshiftUnreadCountUpdated:) name:HelpshiftUnreadCountUpdatedNotification object:nil];

    [HelpshiftUtils refreshUnreadNotificationCount];

    [self reloadInterface];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [self layoutControls];
}


#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameText) {
        [_passwordText becomeFirstResponder];
    } else if (textField == _passwordText) {
        if (self.userIsDotCom) {
            [self signInButtonAction:nil];
        } else {
            [_siteUrlText becomeFirstResponder];
        }
    } else if (textField == _siteUrlText && _signInButton.enabled) {
        [self signInButtonAction:nil];
    } else if (textField == _multifactorText) {
        if ([self isMultifactorFilled]) {
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
    BOOL isMultifactorFilled = [self isMultifactorFilled];

    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == _usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _passwordText) {
        isPasswordFilled = updatedStringHasContent;
    } else if (textField == _siteUrlText) {
        isSiteUrlFilled = updatedStringHasContent;
    } else if (textField == _multifactorText) {
        isMultifactorFilled = updatedStringHasContent;
    }

    isSiteUrlFilled         = (self.userIsDotCom || isSiteUrlFilled);
    isMultifactorFilled     = (!_shouldDisplayMultifactor || isMultifactorFilled);
    
    _signInButton.enabled   = isUsernameFilled && isPasswordFilled && isSiteUrlFilled && isMultifactorFilled;
    _forgotPassword.hidden  = !(self.userIsDotCom || isSiteUrlFilled);

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
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];

        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
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

- (void)displayGenerateApplicationSpecificPasswordErrorMessage:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:GenerateApplicationSpecificPasswordUrl]];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.navigationController pushViewController:webViewController animated:YES];
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
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    overlayView.accessibilityIdentifier = @"GenericErrorMessage";
    [self.view addSubview:overlayView];
}

- (void)displayGenericErrorMessageWithHelpshiftButton:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.secondaryButtonText = NSLocalizedString(@"Contact Us", @"The text on the button at the bottom of the error message when a user has repeated trouble logging in");
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
        [self showHelpshiftConversationView];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}


#pragma mark - Button Press Methods

- (IBAction)helpButtonAction:(id)sender
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:supportViewController];
    nc.navigationBar.translucent = NO;
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

- (IBAction)skipToCreateAction:(id)sender
{
    [self showCreateAccountView];
}

- (IBAction)backgroundTapGestureAction:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.view endEditing:YES];
    [self hideMultifactorTextfieldIfNeeded];
}

- (IBAction)signInButtonAction:(id)sender
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

    if ([self isUserNameReserved]) {
        [self displayReservedNameErrorMessage];
        [self toggleSignInFormAction:nil];
        [_siteUrlText becomeFirstResponder];
        return;
    }

    [self signIn];
}

- (IBAction)toggleSignInFormAction:(id)sender
{
    self.userIsDotCom = !self.userIsDotCom;
    self.passwordText.returnKeyType = self.userIsDotCom ? UIReturnKeyDone : UIReturnKeyNext;

    // Controls are layed out in initializeView. Calling this method in an animation block will animate the controls
    // to their new positions.
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         [self reloadInterface];
                     }];
}


- (IBAction)cancelButtonAction:(id)sender
{
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}

- (IBAction)forgotPassword:(id)sender
{
    NSString *baseUrl = ForgotPasswordDotComBaseUrl;
    if (!self.userIsDotCom) {
        baseUrl = [self getSiteUrl];
    }
    NSURL *forgotPasswordURL = [NSURL URLWithString:[baseUrl stringByAppendingString:ForgotPasswordRelativeUrl]];
    [[UIApplication sharedApplication] openURL:forgotPasswordURL];
}

- (IBAction)findLoginFromOnePassword:(id)sender
{
    if (_userIsDotCom == false && _siteUrlText.text.isEmpty) {
        [self displayOnePasswordEmptySiteAlert];
        return;
    }
 
    NSString *loginURL = _userIsDotCom ? WPOnePasswordWordPressComURL : _siteUrlText.text;
    
    [[OnePasswordExtension sharedExtension] findLoginForURLString:loginURL
                                                forViewController:self
                                                           sender:sender
                                                       completion:^(NSDictionary *loginDict, NSError *error) {
        if (!loginDict) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                DDLogError(@"OnePassword Error: %@", error);
            }
            return;
        }

        self.usernameText.text = loginDict[AppExtensionUsernameKey];
        self.passwordText.text = loginDict[AppExtensionPasswordKey];
        [self signIn];
    }];
}


#pragma mark - One Password Helpers

- (void)displayOnePasswordEmptySiteAlert
{
    NSString *message = NSLocalizedString(@"A site address is required before 1Password can be used.",
                                          @"Error message displayed when the user is Signing into a self hosted site and "
                                          @"tapped the 1Password Button before typing his siteURL");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Accept", @"Accept Button Title")
                                              otherButtonTitles:nil];
    
    [alertView show];
}


#pragma mark - Private Methods

- (void)addMainView
{
    NSAssert(self.view, @"The view should be loaded by now");
    
    UIView *mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapGestureAction:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = YES;
    [mainView addGestureRecognizer:gestureRecognizer];
    
    // Attach + Keep the Reference
    [self.view addSubview:mainView];
    self.mainView = mainView;
}

- (void)addControls
{
    NSAssert(self.view, @"The view should be loaded by now");
    NSAssert(self.mainView, @"Please, initialize the mainView first");
    
    // Add Icon
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-wp"]];
    icon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;

    // Add Info button
    UIImage *infoButtonImage = [UIImage imageNamed:@"btn-help"];
    UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    helpButton.accessibilityLabel = NSLocalizedString(@"Help", @"Help button");
    [helpButton setImage:infoButtonImage forState:UIControlStateNormal];
    helpButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
    helpButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [helpButton addTarget:self action:@selector(helpButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [helpButton sizeToFit];
    [helpButton setExclusiveTouch:YES];

    // Help badge
    WPNUXHelpBadgeLabel *helpBadge = [[WPNUXHelpBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    helpBadge.layer.masksToBounds = YES;
    helpBadge.layer.cornerRadius = 6;
    helpBadge.textAlignment = NSTextAlignmentCenter;
    helpBadge.backgroundColor = [UIColor UIColorFromHex:0xdd3d36];
    helpBadge.textColor = [UIColor whiteColor];
    helpBadge.font = [WPFontManager openSansRegularFontOfSize:8.0];
    helpBadge.hidden = YES;

    // Add Username
    WPWalkthroughTextField *usernameText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
    usernameText.backgroundColor = [UIColor whiteColor];
    usernameText.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 2 Username Placeholder");
    usernameText.font = [WPNUXUtility textFieldFont];
    usernameText.adjustsFontSizeToFitWidth = YES;
    usernameText.returnKeyType = UIReturnKeyNext;
    usernameText.delegate = self;
    usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    usernameText.accessibilityIdentifier = @"Username / Email";

    // Add OnePassword
    UIButton *onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [onePasswordButton setImage:[UIImage imageNamed:@"onepassword-button"] forState:UIControlStateNormal];
    [onePasswordButton addTarget:self action:@selector(findLoginFromOnePassword:) forControlEvents:UIControlEventTouchUpInside];
    [onePasswordButton sizeToFit];
    
    CGRect containerFrame = onePasswordButton.frame;
    containerFrame.size.width += OnePasswordPaddingX;

    UIView *onePasswordView = [[UIView alloc] initWithFrame:containerFrame];
    [onePasswordView addSubview:onePasswordButton];
    usernameText.rightView = onePasswordView;
    
    BOOL isOnePasswordAvailable = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    usernameText.rightViewMode = isOnePasswordAvailable ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
    
    // Add Password
    WPWalkthroughTextField *passwordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
    passwordText.backgroundColor = [UIColor whiteColor];
    passwordText.placeholder = NSLocalizedString(@"Password", nil);
    passwordText.font = [WPNUXUtility textFieldFont];
    passwordText.delegate = self;
    passwordText.secureTextEntry = YES;
    passwordText.returnKeyType = self.userIsDotCom ? UIReturnKeyDone : UIReturnKeyNext;
    passwordText.showSecureTextEntryToggle = YES;
    passwordText.showTopLineSeparator = YES;
    passwordText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    passwordText.accessibilityIdentifier = @"Password";
    
    // Add Multifactor
    WPWalkthroughTextField *multifactorText = [[WPWalkthroughTextField alloc] init];
    multifactorText.backgroundColor = [UIColor whiteColor];
    multifactorText.placeholder = NSLocalizedString(@"Verification Code", nil);
    multifactorText.font = [WPNUXUtility textFieldFont];
    multifactorText.delegate = self;
    multifactorText.keyboardType = UIKeyboardTypeNumberPad;
    multifactorText.textAlignment = NSTextAlignmentCenter;
    multifactorText.returnKeyType = UIReturnKeyDone;
    multifactorText.showTopLineSeparator = YES;
    multifactorText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    multifactorText.accessibilityIdentifier = @"Verification Code";

    // Add Site Url
    WPWalkthroughTextField *siteUrlText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
    siteUrlText.backgroundColor = [UIColor whiteColor];
    siteUrlText.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 2 Site Address Placeholder");
    siteUrlText.font = [WPNUXUtility textFieldFont];
    siteUrlText.adjustsFontSizeToFitWidth = YES;
    siteUrlText.delegate = self;
    siteUrlText.keyboardType = UIKeyboardTypeURL;
    siteUrlText.returnKeyType = UIReturnKeyDone;
    siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
    siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    siteUrlText.showTopLineSeparator = YES;
    siteUrlText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    siteUrlText.accessibilityIdentifier = @"Site Address (URL)";
    
    // Add Sign In Button
    WPNUXMainButton *signInButton = [[WPNUXMainButton alloc] init];
    [signInButton addTarget:self action:@selector(signInButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    signInButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    signInButton.accessibilityIdentifier = @"Sign In";
    
    // Add Cancel Button
    WPNUXSecondaryButton *cancelButton = [[WPNUXSecondaryButton alloc] init];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setExclusiveTouch:YES];
    [cancelButton sizeToFit];

    // Add status label
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.font = [WPNUXUtility confirmationLabelFont];
    statusLabel.textColor = [WPNUXUtility confirmationLabelColor];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;

    // Add Account type toggle
    WPNUXSecondaryButton *toggleSignInForm = [[WPNUXSecondaryButton alloc] init];
    [toggleSignInForm addTarget:self action:@selector(toggleSignInFormAction:) forControlEvents:UIControlEventTouchUpInside];
    toggleSignInForm.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    // Add Skip to Create Account Button
    WPNUXSecondaryButton *skipToCreateAccount = [[WPNUXSecondaryButton alloc] init];
    skipToCreateAccount.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [skipToCreateAccount setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
    [skipToCreateAccount addTarget:self action:@selector(skipToCreateAction:) forControlEvents:UIControlEventTouchUpInside];

    // Add Lost Password Button
    WPNUXSecondaryButton *forgotPassword = [[WPNUXSecondaryButton alloc] init];
    forgotPassword.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [forgotPassword setTitle:NSLocalizedString(@"Lost your password?", nil) forState:UIControlStateNormal];
    [forgotPassword addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    forgotPassword.titleLabel.font = [WPNUXUtility tosLabelFont];
    [forgotPassword setTitleColor:[WPNUXUtility tosLabelColor] forState:UIControlStateNormal];
    
    // Attach Subviews
    [self.view addSubview:cancelButton];
    [self.mainView addSubview:icon];
    [self.mainView addSubview:helpButton];
    [self.mainView addSubview:helpBadge];
    [self.mainView addSubview:usernameText];
    [self.mainView addSubview:passwordText];
    [self.mainView addSubview:multifactorText];
    [self.mainView addSubview:siteUrlText];
    [self.mainView addSubview:signInButton];
    [self.mainView addSubview:statusLabel];
    [self.mainView addSubview:toggleSignInForm];
    [self.mainView addSubview:skipToCreateAccount];
    [self.mainView addSubview:forgotPassword];

    // Keep the references!
    self.cancelButton = cancelButton;
    self.icon = icon;
    self.helpButton = helpButton;
    self.helpBadge = helpBadge;
    self.usernameText = usernameText;
    self.passwordText = passwordText;
    self.onePasswordButton = onePasswordButton;
    self.multifactorText = multifactorText;
    self.siteUrlText = siteUrlText;
    self.signInButton = signInButton;
    self.statusLabel = statusLabel;
    self.toggleSignInForm = toggleSignInForm;
    self.skipToCreateAccount = skipToCreateAccount;
    self.forgotPassword = forgotPassword;
}


#pragma mark - Private Helpers

- (void)reloadInterface
{
    [self updateControls];
    [self layoutControls];
}

- (void)updateControls
{
    // TextFields
    self.usernameText.alpha         = self.shouldDisplayMultifactor ? GeneralWalkthroughAlphaDisabled : GeneralWalkthroughAlphaEnabled;
    self.passwordText.alpha         = self.shouldDisplayMultifactor ? GeneralWalkthroughAlphaDisabled : GeneralWalkthroughAlphaEnabled;
    self.multifactorText.alpha      = self.shouldDisplayMultifactor ? GeneralWalkthroughAlphaEnabled  : GeneralWalkthroughAlphaHidden;
    self.siteUrlText.alpha          = self.userIsDotCom             ? GeneralWalkthroughAlphaHidden   : GeneralWalkthroughAlphaEnabled;
    
    self.usernameText.enabled       = !self.shouldDisplayMultifactor;
    self.passwordText.enabled       = !self.shouldDisplayMultifactor;
    self.multifactorText.enabled    = self.shouldDisplayMultifactor;
    self.siteUrlText.enabled        = !self.userIsDotCom;
    
    // Cancel Button
    self.cancelButton.hidden        = !self.cancellable;
    
    // SignIn Button
    NSString *signInTitle = @"Add Site";
    
    if (self.shouldDisplayMultifactor) {
        signInTitle = @"Verify";
    } else if (self.userIsDotCom) {
        signInTitle = @"Sign In";
    }
    
    self.signInButton.enabled       = self.isSignInEnabled;
    self.signInButton.accessibilityIdentifier = signInTitle;
    [self.signInButton setTitle:NSLocalizedString(signInTitle, nil) forState:UIControlStateNormal];
    
    // Dotcom / SelfHosted Button
    NSString *toggleTitle           = self.userIsDotCom ? @"Add Self-Hosted Site" : @"Sign in to WordPress.com";
    self.toggleSignInForm.hidden    = !self.isSignInToggleEnabled;
    self.toggleSignInForm.accessibilityIdentifier = toggleTitle;
    [self.toggleSignInForm setTitle:NSLocalizedString(toggleTitle, nil) forState:UIControlStateNormal];
    
    // Create Account Button
    self.skipToCreateAccount.hidden = !self.isAccountCreationEnabled;
    
    // Forgot Password Button
    self.forgotPassword.hidden      = !self.isForgotPasswordEnabled;
}

- (void)layoutControls
{
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    CGFloat textFieldX = (viewWidth - GeneralWalkthroughTextFieldSize.width) * 0.5f;
    CGFloat textLabelX = (viewWidth - GeneralWalkthroughMaxTextWidth) * 0.5f;
    CGFloat buttonX = (viewWidth - GeneralWalkthroughButtonSize.width) * 0.5f;
    
    // Layout Help Button
    CGFloat helpButtonX = viewWidth - CGRectGetWidth(_helpButton.frame) - GeneralWalkthroughStandardOffset;
    CGFloat helpButtonY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    _helpButton.frame = CGRectIntegral(CGRectMake(helpButtonX, helpButtonY, CGRectGetWidth(_helpButton.frame), GeneralWalkthroughButtonSize.height));

    // layout help badge
    CGFloat helpBadgeX = viewWidth - CGRectGetWidth(_helpBadge.frame) - GeneralWalkthroughStandardOffset + 5;
    CGFloat helpBadgeY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset + CGRectGetHeight(_helpBadge.frame) - 5;
    _helpBadge.frame = CGRectIntegral(CGRectMake(helpBadgeX, helpBadgeY, CGRectGetWidth(_helpBadge.frame), CGRectGetHeight(_helpBadge.frame)));

    // Layout Cancel Button
    CGFloat cancelButtonX = 0;
    CGFloat cancelButtonY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    _cancelButton.frame = CGRectIntegral(CGRectMake(cancelButtonX, cancelButtonY, CGRectGetWidth(_cancelButton.frame), GeneralWalkthroughButtonSize.height));

    // Calculate total height and starting Y origin of controls
    CGFloat heightOfControls = CGRectGetHeight(_icon.frame) + GeneralWalkthroughStandardOffset + (self.userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldSize.height + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonSize.height;
    CGFloat startingYForCenteredControls = floorf((viewHeight - 2 * GeneralWalkthroughSecondaryButtonHeight - heightOfControls)/2.0);

    CGFloat iconX = (viewWidth - CGRectGetWidth(_icon.frame)) * 0.5f;
    CGFloat iconY = startingYForCenteredControls;
    _icon.frame = CGRectIntegral(CGRectMake(iconX, iconY, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));

    // Layout Username
    CGFloat usernameTextY = CGRectGetMaxY(_icon.frame) + GeneralWalkthroughStandardOffset;
    _usernameText.frame = CGRectIntegral(CGRectMake(textFieldX, usernameTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));

    // Layout Password
    CGFloat passwordTextY = CGRectGetMaxY(_usernameText.frame) - GeneralWalkthroughTextFieldOverlapY;
    _passwordText.frame = CGRectIntegral(CGRectMake(textFieldX, passwordTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));

    // Layout Multifactor
    CGFloat multifactorTextY = CGRectGetMaxY(_passwordText.frame) - GeneralWalkthroughTextFieldOverlapY;
    _multifactorText.frame = CGRectIntegral(CGRectMake(textFieldX, multifactorTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));
    
    // Layout Site URL
    CGFloat siteUrlTextY = CGRectGetMaxY(_passwordText.frame) - GeneralWalkthroughTextFieldOverlapY;
    _siteUrlText.frame = CGRectIntegral(CGRectMake(textFieldX, siteUrlTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));

    // Layout Sign in Button
    CGFloat signInButtonY = [self lastTextfieldMaxY] + GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectIntegral(CGRectMake(buttonX, signInButtonY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughButtonSize.height));

    // Layout Lost password Button
    CGFloat forgotPasswordY = CGRectGetMaxY(_signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    CGFloat forgotPasswordHeight = [_forgotPassword.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:_forgotPassword.titleLabel.font}].height;
    _forgotPassword.frame = CGRectIntegral(CGRectMake(buttonX, forgotPasswordY, GeneralWalkthroughButtonSize.width, forgotPasswordHeight));

    // Layout Skip to Create Account Button
    CGFloat skipToCreateAccountY = viewHeight - GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    _skipToCreateAccount.frame = CGRectIntegral(CGRectMake(buttonX, skipToCreateAccountY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughSecondaryButtonHeight));

    // Layout Status Label
    CGFloat statusLabelY = CGRectGetMaxY(_signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    _statusLabel.frame = CGRectIntegral(CGRectMake(textLabelX, statusLabelY, GeneralWalkthroughMaxTextWidth, _statusLabel.font.lineHeight));

    // Layout Toggle Button
    CGFloat toggleSignInY = CGRectGetMinY(_skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    _toggleSignInForm.frame = CGRectIntegral(CGRectMake(textLabelX, toggleSignInY, GeneralWalkthroughMaxTextWidth, GeneralWalkthroughSecondaryButtonHeight));
}

- (void)dismiss
{
    // If we were invoked from the post tab proceed to the editor. Our work here is done.
    if (_showEditorAfterAddingSites) {
        [[WPTabBarController sharedInstance] showPostTab];
        return;
    }

    // Check if there is an active WordPress.com account. If not, switch tab bar
    // away from Reader to // blog list view
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (!defaultAccount) {
        [[WPTabBarController sharedInstance] showMySitesTab];
    }

    if (self.dismissBlock) {
        self.dismissBlock();
    }
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
        if (didAuthenticate) {
            [WPAnalytics track:WPAnalyticsStatSignedInToJetpack];
            [WPAnalytics refreshMetadata];
        } else {
            [WPAnalytics track:WPAnalyticsStatSkippedConnectingToJetpack];
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

- (void)showHelpshiftConversationView
{
    NSDictionary *metaData = @{@"Source": @"Failed login",
                               @"Username": _usernameText.text,
                               @"SiteURL": _siteUrlText.text};

    [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:_siteUrlText.text]];
    NSString *url = [siteURL absoluteString];

    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if (url.isWordPressComURL) {
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
    if ([self areSelfHostedFieldsFilled] && !self.userIsDotCom) {
        return [self isUrlValid];
    }

    return [self areDotComFieldsFilled];
}

- (BOOL)isUsernameFilled
{
    return [[_usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[_passwordText.text trim] length] != 0;
}

- (BOOL)isMultifactorFilled
{
    return self.multifactorText.text.isEmpty == NO;
}
- (BOOL)isSiteUrlFilled
{
    return [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)isSignInEnabled
{
    return self.userIsDotCom ? [self areDotComFieldsFilled] : [self areSelfHostedFieldsFilled];
}

- (BOOL)isSignInToggleEnabled
{
    return !self.onlyDotComAllowed && !self.hasDefaultAccount;
}

- (BOOL)isAccountCreationEnabled
{
    return self.hasDefaultAccount == NO;
}

- (BOOL)isForgotPasswordEnabled
{
    return self.userIsDotCom || [self isUrlValid];
}

- (BOOL)areDotComFieldsFilled
{
    BOOL areCredentialsFilled = [self isUsernameFilled] && [self isPasswordFilled];
    
    if (![self shouldDisplayMultifactor]) {
        return areCredentialsFilled;
    }
    
    return areCredentialsFilled && [self isMultifactorFilled];
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
    if (_siteUrlText.text.length == 0) {
        return NO;
    }
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:_siteUrlText.text]];
    return siteURL != nil;
}

- (BOOL)isUserNameReserved
{
    if (!self.userIsDotCom) {
        return NO;
    }
    NSString *username = [[_usernameText.text trim] lowercaseString];
    NSArray *reservedUserNames = @[@"admin",@"administrator",@"root"];
    
    return [reservedUserNames containsObject:username];
}

- (CGFloat)lastTextfieldMaxY
{
    if (self.shouldDisplayMultifactor) {
        return CGRectGetMaxY(self.multifactorText.frame);
    } else if (self.userIsDotCom) {
        return CGRectGetMaxY(self.passwordText.frame);
    } else {
        return CGRectGetMaxY(self.siteUrlText.frame);
    }
}

- (void)displayErrorMessages
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) withSupportButton:NO];
}

- (void)displayReservedNameErrorMessage
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Self-hosted site?", nil) message:NSLocalizedString(@"Please enter the URL of your WordPress site.", nil) withSupportButton:NO];
}

- (void)setAuthenticating:(BOOL)authenticating withStatusMessage:(NSString *)status
{
    _statusLabel.hidden = !(status.length > 0);
    _statusLabel.text = status;

    _onePasswordButton.enabled = !authenticating;
    _signInButton.enabled = !authenticating;
    _toggleSignInForm.hidden = authenticating;
    _skipToCreateAccount.hidden = authenticating;
    _forgotPassword.hidden = authenticating;
    _cancelButton.enabled = !authenticating;
    [_signInButton showActivityIndicator:authenticating];
}

- (void)signIn
{
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Authenticating", nil)];

    NSString *username = self.usernameText.text;
    NSString *password = self.passwordText.text;
    NSString *multifactor = self.shouldDisplayMultifactor ? self.multifactorText.text : nil;

    if (self.userIsDotCom) {
        [self signInWithWPComForUsername:username password:password multifactor:multifactor];
        return;
    }

    if (_siteUrlText.text.isWordPressComURL) {
        [self signInWithWPComForUsername:username password:password multifactor:multifactor];
        return;
    }

    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];

        [api getBlogOptionsWithSuccess:^(id options){
            [self setAuthenticating:NO withStatusMessage:nil];

            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInWithWPComForUsername:username password:password multifactor:multifactor];
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

    NSString *siteUrl = [NSURL IDNEncodedURL:_siteUrlText.text];

    [WordPressXMLRPCApi guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)signInWithWPComForUsername:(NSString *)username
                          password:(NSString *)password
                       multifactor:(NSString *)multifactor
{
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];

    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                     multifactorCode:multifactor
                             success:^(NSString *authToken) {
                                 [self setAuthenticating:NO withStatusMessage:nil];
                                 self.userIsDotCom = YES;
                                 [self createWordPressComAccountForUsername:username password:password authToken:authToken];
                             } failure:^(NSError *error) {
                                 [self setAuthenticating:NO withStatusMessage:nil];
                                 
                                 // If needed, show the multifactor field
                                 if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
                                     [self displayMultifactorTextfield];
                                 } else {
                                     [self displayRemoteError:error];
                                 }
                             }];
}

- (void)createWordPressComAccountForUsername:(NSString *)username
                                    password:(NSString *)password
                                   authToken:(NSString *)authToken
{
    [self setAuthenticating:YES withStatusMessage:NSLocalizedString(@"Getting account information", nil)];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username password:password authToken:authToken];

    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlogsForAccount:account
                                success:^{
                                    [self setAuthenticating:NO withStatusMessage:nil];
                                    [self dismiss];
                                    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:@{ @"dotcom_user" : @(YES) }];
                                    [WPAnalytics refreshMetadata];

                                    // once blogs for the accounts are synced, we want to update account details for it
                                    [accountService updateEmailAndDefaultBlogForWordPressComAccount:account];
                                }
                                failure:^(NSError *error) {
                                    [self setAuthenticating:NO withStatusMessage:nil];
                                    [self displayRemoteError:error];
                                }];
}

- (void)createSelfHostedAccountAndBlogWithUsername:(NSString *)username
                                          password:(NSString *)password
                                            xmlrpc:(NSString *)xmlrpc
                                           options:(NSDictionary *)options
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    WPAccount *account = [accountService createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    if (!url) {
        url = [options stringForKeyPath:@"blog_url.value"];
    }
    _blog = [blogService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!_blog) {
        _blog = [blogService createBlogWithAccount:account];
        if (url) {
            _blog.url = url;
        }
        if (blogName) {
            _blog.blogName = [blogName stringByDecodingXMLCharacters];
        }
    }
    _blog.xmlrpc = xmlrpc;
    _blog.options = options;
    [_blog dataSave];
    [blogService syncBlog:_blog success:nil failure:nil];

    if ([_blog hasJetpack]) {
        if ([_blog hasJetpackAndIsConnectedToWPCom]) {
            [self showJetpackAuthentication];
        } else {
            [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom];
            [self dismiss];
        }
    } else {
        [self dismiss];
    }

    [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSite];
    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:@{ @"dotcom_user" : @(NO) }];
    [WPAnalytics refreshMetadata];
}

- (void)handleGuessXMLRPCURLFailure:(NSError *)error
{
    [self setAuthenticating:NO withStatusMessage:nil];
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        [self displayRemoteError:nil];
    } else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
        [self displayRemoteError:error];
    } else if ([error.domain isEqual:AFURLRequestSerializationErrorDomain] || [error.domain isEqual:AFURLResponseSerializationErrorDomain]) {
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", nil), [error localizedDescription]];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: str};
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
        [self displayRemoteError:err];
    } else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil)};
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
        [self displayRemoteError:err];
    }
}

- (void)displayRemoteError:(NSError *)error
{
    DDLogError(@"%@", error);
    NSString *message = [error localizedDescription];
    if (![[error domain] isEqualToString:WPXMLRPCFaultErrorDomain]) {
        if ([message rangeOfString:@"application-specific"].location != NSNotFound) {
            [self displayGenerateApplicationSpecificPasswordErrorMessage:message];
        } else {
            if (error.code == WordPressComOAuthErrorInvalidRequest) {
                _numberOfTimesLoginFailed++;
            }

            if ([HelpshiftUtils isHelpshiftEnabled] && _numberOfTimesLoginFailed >= 2) {
                [self displayGenericErrorMessageWithHelpshiftButton:message];
            } else {
                [self displayGenericErrorMessage:message];
            }
        }
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


#pragma mark - Multifactor Helpers

- (void)displayMultifactorTextfield
{
    self.shouldDisplayMultifactor = YES;
    
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         [self reloadInterface];
                         [self.multifactorText becomeFirstResponder];
                     }];
}

- (void)hideMultifactorTextfieldIfNeeded
{
    if (!self.shouldDisplayMultifactor) {
        return;
    }
    
    self.shouldDisplayMultifactor = NO;
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         [self reloadInterface];
                     } completion:^(BOOL finished) {
                         self.multifactorText.text = nil;
                     }];
}


#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat newKeyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + GeneralWalkthroughStandardOffset;

    if (newKeyboardOffset < 0) {
        return;
    }

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveForTextEntry]) {
            CGRect frame = control.frame;
            frame.origin.y -= newKeyboardOffset;
            control.frame = frame;
        }

        for (UIControl *control in [self controlsToHideForTextEntry]) {
            control.alpha = GeneralWalkthroughAlphaHidden;
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
            control.alpha = GeneralWalkthroughAlphaEnabled;
        }
    }];
}

- (NSArray *)controlsToMoveForTextEntry
{
    return @[_icon, _usernameText, _passwordText, _multifactorText, _siteUrlText, _signInButton, _statusLabel];
}

- (NSArray *)controlsToHideForTextEntry
{
    NSArray *controlsToHide = @[_helpButton, _helpBadge];

    // Hide the
    BOOL isSmallScreen = !(CGRectGetHeight(self.view.bounds) > HiddenControlsHeightThreshold);
    if (isSmallScreen) {
        controlsToHide = [controlsToHide arrayByAddingObject:_icon];
    }
    return controlsToHide;
}

#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSInteger unreadCount = [HelpshiftUtils unreadNotificationCount];
    _helpBadge.text = [NSString stringWithFormat:@"%ld", unreadCount];
    _helpBadge.hidden = (unreadCount == 0);
}


#pragma mark - Static Helpers

+ (void)presentModalReauthScreen
{
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    loginViewController.onlyDotComAllowed = YES;
    loginViewController.shouldReauthenticateDefaultAccount = YES;
    loginViewController.cancellable = YES;
    loginViewController.dismissBlock = ^{
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navController.navigationBar.translucent = NO;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

@end
