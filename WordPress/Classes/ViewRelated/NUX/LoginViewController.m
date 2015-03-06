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
#import "NSAttributedString+Util.h"
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

static CGPoint const LoginOnePasswordPadding                    = {9.0, 0.0f};
static NSInteger const LoginVerificationCodeNumberOfLines       = 2;


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
@property (nonatomic, strong) WPNUXSecondaryButton      *sendVerificationCodeButton;
@property (nonatomic, strong) WPNUXSecondaryButton      *cancelButton;
@property (nonatomic, strong) UILabel                   *statusLabel;
@property (nonatomic, strong) UITapGestureRecognizer    *tapGestureRecognizer;

// Measurements
@property (nonatomic, strong) Blog                      *blog;
@property (nonatomic, assign) CGFloat                   keyboardOffset;
@property (nonatomic, assign) BOOL                      userIsDotCom;
@property (nonatomic, assign) BOOL                      hasDefaultAccount;
@property (nonatomic, assign) BOOL                      shouldDisplayMultifactor;
@property (nonatomic, assign) BOOL                      authenticating;

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
    [nc addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
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
    if (textField == self.usernameText) {
        [self.passwordText becomeFirstResponder];
    } else if (textField == self.passwordText) {
        if (self.userIsDotCom) {
            [self signInButtonAction:nil];
        } else {
            [self.siteUrlText becomeFirstResponder];
        }
    } else if (textField == self.siteUrlText) {
        if (self.signInButton.enabled) {
            [self signInButtonAction:nil];
        }
    } else if (textField == self.multifactorText) {
        if ([self isMultifactorFilled]) {
            [self signInButtonAction:nil];
        }
    }

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self isSignInEnabled];
    return !self.authenticating;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self isSignInEnabled];
    return YES;
}

- (void)textFieldDidChange:(NSNotification *)note
{
    [self updateControls];
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
        [webViewController setUsername:self.usernameText.text];
        [webViewController setPassword:self.passwordText.text];
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
    overlayView.secondaryButtonText = NSLocalizedString(@"Contact Us", @"The text on the button at the bottom of the ""error message when a user has repeated trouble logging in");
    overlayView.secondaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
        [self showHelpshiftConversationView];
    };
    overlayView.primaryButtonCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

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

- (void)displayErrorMessages
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) withSupportButton:NO];
}

- (void)displayReservedNameErrorMessage
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Self-hosted site?", nil) message:NSLocalizedString(@"Please enter the URL of your WordPress site.", nil) withSupportButton:NO];
}


#pragma mark - Button Handlers

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
        [self.siteUrlText becomeFirstResponder];
        return;
    }

    [self signIn];
}

- (IBAction)toggleSignInFormAction:(id)sender
{
    self.shouldDisplayMultifactor = false;
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
    NSString *baseUrl = self.userIsDotCom ? ForgotPasswordDotComBaseUrl : [self getSiteUrl];
    NSURL *forgotPasswordURL = [NSURL URLWithString:[baseUrl stringByAppendingString:ForgotPasswordRelativeUrl]];
    
    [[UIApplication sharedApplication] openURL:forgotPasswordURL];
}

- (IBAction)findLoginFromOnePassword:(id)sender
{
    if (self.userIsDotCom == false && self.siteUrlText.text.isEmpty) {
        [self displayOnePasswordEmptySiteAlert];
        return;
    }
 
    NSString *loginURL = self.userIsDotCom ? WPOnePasswordWordPressComURL : self.siteUrlText.text;
    
    [[OnePasswordExtension sharedExtension] findLoginForURLString:loginURL
                                                forViewController:self
                                                           sender:sender
                                                       completion:^(NSDictionary *loginDict, NSError *error) {
        if (!loginDict) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                DDLogError(@"OnePassword Error: %@", error);
                [WPAnalytics track:WPAnalyticsStatOnePasswordFailed];
            }
            return;
        }

        self.usernameText.text = loginDict[AppExtensionUsernameKey];
        self.passwordText.text = loginDict[AppExtensionPasswordKey];
                                                           
        [WPAnalytics track:WPAnalyticsStatOnePasswordLogin];
        [self signIn];
    }];
}

- (IBAction)sendVerificationCode:(id)sender
{
    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client requestOneTimeCodeWithUsername:self.usernameText.text
                                  password:self.passwordText.text
                                   success:^{
                                       [WPAnalytics track:WPAnalyticsStatTwoFactorSentSMS];
                                   }
                                   failure:nil];
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
    self.tapGestureRecognizer = gestureRecognizer;
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
    
    usernameText.rightView = onePasswordButton;
    usernameText.rightViewPadding = LoginOnePasswordPadding;
    
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
    
    // Text: Verification Code SMS
    NSString *codeText = NSLocalizedString(@"Enter the code on your authenticator app or ", @"Message displayed when a verification code is needed");
    NSMutableAttributedString *attributedCodeText = [[NSMutableAttributedString alloc] initWithString:codeText];
    
    NSString *smsText = NSLocalizedString(@"send the code via text message.", @"Sends an SMS with the Multifactor Auth Code");
    NSMutableAttributedString *attributedSmsText = [[NSMutableAttributedString alloc] initWithString:smsText];
    [attributedSmsText applyUnderline];
    
    [attributedCodeText appendAttributedString:attributedSmsText];
    [attributedCodeText applyFont:[WPNUXUtility confirmationLabelFont]];
    [attributedCodeText applyForegroundColor:[UIColor whiteColor]];
    
    NSMutableAttributedString *attributedCodeHighlighted = [attributedCodeText mutableCopy];
    [attributedCodeHighlighted applyForegroundColor:[WPNUXUtility confirmationLabelColor]];
    
    // Add Verification Code SMS Button
    WPNUXSecondaryButton *sendVerificationCodeButton = [[WPNUXSecondaryButton alloc] init];
    
    sendVerificationCodeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    sendVerificationCodeButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    sendVerificationCodeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    sendVerificationCodeButton.titleLabel.numberOfLines = LoginVerificationCodeNumberOfLines;
    [sendVerificationCodeButton setAttributedTitle:attributedCodeText forState:UIControlStateNormal];
    [sendVerificationCodeButton setAttributedTitle:attributedCodeHighlighted forState:UIControlStateHighlighted];
    [sendVerificationCodeButton addTarget:self action:@selector(sendVerificationCode:) forControlEvents:UIControlEventTouchUpInside];
    
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
    [self.mainView addSubview:sendVerificationCodeButton];
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
    self.sendVerificationCodeButton = sendVerificationCodeButton;
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
    // Spinner!
    [self.signInButton showActivityIndicator:self.authenticating];
    
    // Background Taps
    self.tapGestureRecognizer.enabled       = self.isGesturesRecognizerEnabled;
    
    // One Password
    BOOL isOnePasswordAvailable             = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    self.usernameText.rightViewMode         = isOnePasswordAvailable ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
    
    // TextFields
    self.usernameText.alpha                 = self.usernameAlpha;
    self.passwordText.alpha                 = self.passwordAlpha;
    self.siteUrlText.alpha                  = self.siteAlpha;
    self.multifactorText.alpha              = self.multifactorAlpha;
    
    self.usernameText.enabled               = self.isUsernameEnabled;
    self.passwordText.enabled               = self.isPasswordEnabled;
    self.onePasswordButton.enabled          = self.isOnePasswordEnabled;
    self.siteUrlText.enabled                = self.isSiteUrlEnabled;
    self.multifactorText.enabled            = self.isMultifactorEnabled;
    
    // Buttons
    self.cancelButton.hidden                = !self.cancellable;
    self.cancelButton.enabled               = self.isCancelButtonEnabled;
    self.forgotPassword.hidden              = !self.isForgotPasswordEnabled;
    self.sendVerificationCodeButton.hidden  = !self.isSendCodeEnabled;
    self.skipToCreateAccount.hidden         = !self.isAccountCreationEnabled;
    
    // SignIn Button
    NSString *signInTitle                   = self.signInButtonTitle;
    self.signInButton.enabled               = self.isSignInEnabled;
    self.signInButton.accessibilityIdentifier = signInTitle;
    [self.signInButton setTitle:signInTitle forState:UIControlStateNormal];
    
    // Dotcom / SelfHosted Button
    NSString *toggleTitle                   = self.toggleSignInButtonTitle;
    self.toggleSignInForm.hidden            = !self.isSignInToggleEnabled;
    self.toggleSignInForm.accessibilityIdentifier = toggleTitle;
    [self.toggleSignInForm setTitle:toggleTitle forState:UIControlStateNormal];
}

- (void)layoutControls
{
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    CGFloat textFieldX = (viewWidth - GeneralWalkthroughTextFieldSize.width) * 0.5f;
    CGFloat textLabelX = (viewWidth - GeneralWalkthroughMaxTextWidth) * 0.5f;
    CGFloat buttonX = (viewWidth - GeneralWalkthroughButtonSize.width) * 0.5f;
    
    // Layout Help Button
    CGFloat helpButtonX = viewWidth - CGRectGetWidth(self.helpButton.frame) - GeneralWalkthroughStandardOffset;
    CGFloat helpButtonY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    self.helpButton.frame = CGRectIntegral(CGRectMake(helpButtonX, helpButtonY, CGRectGetWidth(self.helpButton.frame), GeneralWalkthroughButtonSize.height));

    // layout help badge
    CGFloat helpBadgeX = viewWidth - CGRectGetWidth(self.helpBadge.frame) - GeneralWalkthroughStandardOffset + 5;
    CGFloat helpBadgeY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset + CGRectGetHeight(self.helpBadge.frame) - 5;
    self.helpBadge.frame = CGRectIntegral(CGRectMake(helpBadgeX, helpBadgeY, CGRectGetWidth(self.helpBadge.frame), CGRectGetHeight(self.helpBadge.frame)));

    // Layout Cancel Button
    CGFloat cancelButtonX = 0;
    CGFloat cancelButtonY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
    self.cancelButton.frame = CGRectIntegral(CGRectMake(cancelButtonX, cancelButtonY, CGRectGetWidth(self.cancelButton.frame), GeneralWalkthroughButtonSize.height));

    // Calculate total height and starting Y origin of controls
    CGFloat heightOfControls = CGRectGetHeight(self.icon.frame) + GeneralWalkthroughStandardOffset + (self.userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldSize.height + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonSize.height;
    CGFloat startingYForCenteredControls = floorf((viewHeight - 2 * GeneralWalkthroughSecondaryButtonHeight - heightOfControls)/2.0);

    CGFloat iconX = (viewWidth - CGRectGetWidth(self.icon.frame)) * 0.5f;
    CGFloat iconY = startingYForCenteredControls;
    self.icon.frame = CGRectIntegral(CGRectMake(iconX, iconY, CGRectGetWidth(self.icon.frame), CGRectGetHeight(self.icon.frame)));

    // Layout Username
    CGFloat usernameTextY = CGRectGetMaxY(self.icon.frame) + GeneralWalkthroughStandardOffset;
    self.usernameText.frame = CGRectIntegral(CGRectMake(textFieldX, usernameTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));

    // Layout Password
    CGFloat passwordTextY = CGRectGetMaxY(self.usernameText.frame) - GeneralWalkthroughTextFieldOverlapY;
    self.passwordText.frame = CGRectIntegral(CGRectMake(textFieldX, passwordTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));
    
    // Layout Site URL
    CGFloat siteUrlTextY = CGRectGetMaxY(self.passwordText.frame) - GeneralWalkthroughTextFieldOverlapY;
    self.siteUrlText.frame = CGRectIntegral(CGRectMake(textFieldX, siteUrlTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));

    // Layout Multifactor
    CGFloat multifactorTextY = self.userIsDotCom ? CGRectGetMaxY(self.passwordText.frame) : CGRectGetMaxY(self.siteUrlText.frame);
    multifactorTextY -= GeneralWalkthroughTextFieldOverlapY;
    self.multifactorText.frame = CGRectIntegral(CGRectMake(textFieldX, multifactorTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));
    
    // Layout Sign in Button
    CGFloat signInButtonY = [self lastTextfieldMaxY] + GeneralWalkthroughStandardOffset;
    self.signInButton.frame = CGRectIntegral(CGRectMake(buttonX, signInButtonY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughButtonSize.height));

    // Layout SMS Label
    CGFloat smsLabelY = CGRectGetMaxY(self.signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    CGSize targetSize = [self.sendVerificationCodeButton.titleLabel sizeThatFits:CGSizeMake(GeneralWalkthroughButtonSize.width, CGFLOAT_MAX)];
    self.sendVerificationCodeButton.frame = CGRectIntegral(CGRectMake(textLabelX, smsLabelY, GeneralWalkthroughButtonSize.width, targetSize.height));
    
    // Layout Lost password Button
    CGFloat forgotPasswordY = CGRectGetMaxY(self.signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    CGFloat forgotPasswordHeight = [self.forgotPassword.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.forgotPassword.titleLabel.font}].height;
    self.forgotPassword.frame = CGRectIntegral(CGRectMake(buttonX, forgotPasswordY, GeneralWalkthroughButtonSize.width, forgotPasswordHeight));

    // Layout Skip to Create Account Button
    CGFloat skipToCreateAccountY = viewHeight - GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    self.skipToCreateAccount.frame = CGRectIntegral(CGRectMake(buttonX, skipToCreateAccountY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughSecondaryButtonHeight));

    // Layout Status Label
    CGFloat statusLabelY = CGRectGetMaxY(self.signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
    self.statusLabel.frame = CGRectIntegral(CGRectMake(textLabelX, statusLabelY, GeneralWalkthroughMaxTextWidth, self.statusLabel.font.lineHeight));

    // Layout Toggle Button
    CGFloat toggleSignInY = CGRectGetMinY(self.skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
    self.toggleSignInForm.frame = CGRectIntegral(CGRectMake(textLabelX, toggleSignInY, GeneralWalkthroughMaxTextWidth, GeneralWalkthroughSecondaryButtonHeight));
}

- (void)dismiss
{
    // If we were invoked from the post tab proceed to the editor. Our work here is done.
    if (self.showEditorAfterAddingSites) {
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
    [self finishedAuthenticating];
    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
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
                               @"Username": self.usernameText.text,
                               @"SiteURL": self.siteUrlText.text};

    [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
    [WPAnalytics track:WPAnalyticsStatSupportOpenedHelpshiftScreen];
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:self.siteUrlText.text]];
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


#pragma mark - Validation Helpers

- (BOOL)areFieldsValid
{
    if ([self areSelfHostedFieldsFilled] && !self.userIsDotCom) {
        return [self isUrlValid];
    }

    return [self areDotComFieldsFilled];
}

- (BOOL)isUsernameFilled
{
    return [[self.usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[self.passwordText.text trim] length] != 0;
}

- (BOOL)isMultifactorFilled
{
    return self.multifactorText.text.isEmpty == NO;
}

- (BOOL)isSiteUrlFilled
{
    return [[self.siteUrlText.text trim] length] != 0;
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

- (BOOL)isUrlValid
{
    if (self.siteUrlText.text.length == 0) {
        return NO;
    }
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:self.siteUrlText.text]];
    return siteURL != nil;
}

- (BOOL)isUserNameReserved
{
    if (!self.userIsDotCom) {
        return NO;
    }
    NSString *username = [[self.usernameText.text trim] lowercaseString];
    NSArray *reservedUserNames = @[@"admin",@"administrator",@"root"];
    
    return [reservedUserNames containsObject:username];
}


#pragma mark - Interface Helpers: TextFields

- (BOOL)isUsernameEnabled
{
    return !self.shouldDisplayMultifactor;
}

- (BOOL)isPasswordEnabled
{
    return !self.shouldDisplayMultifactor;
}

- (BOOL)isOnePasswordEnabled
{
    return !self.authenticating;
}

- (BOOL)isSiteUrlEnabled
{
    return !self.userIsDotCom;
}

- (BOOL)isMultifactorEnabled
{
    return self.shouldDisplayMultifactor;
}

- (CGFloat)usernameAlpha
{
    return self.isUsernameEnabled ? GeneralWalkthroughAlphaEnabled : GeneralWalkthroughAlphaDisabled;
}

- (CGFloat)passwordAlpha
{
    return self.isPasswordEnabled ? GeneralWalkthroughAlphaEnabled : GeneralWalkthroughAlphaDisabled;
}

- (CGFloat)siteAlpha
{
    if (self.isSiteUrlEnabled) {
        return self.isMultifactorEnabled ? GeneralWalkthroughAlphaDisabled : GeneralWalkthroughAlphaEnabled;
    }
    
    return GeneralWalkthroughAlphaHidden;
}

- (CGFloat)multifactorAlpha
{
    return self.isMultifactorEnabled ? GeneralWalkthroughAlphaEnabled : GeneralWalkthroughAlphaHidden;
}


#pragma mark - Interface Helpers: Buttons

- (BOOL)isSignInEnabled
{
    BOOL isEnabled = self.userIsDotCom ? [self areDotComFieldsFilled] : [self areSelfHostedFieldsFilled];
    return isEnabled && !self.authenticating;
}

- (BOOL)isSignInToggleEnabled
{
    return !self.onlyDotComAllowed && !self.hasDefaultAccount && !self.authenticating;
}

- (BOOL)isSendCodeEnabled
{
    return self.shouldDisplayMultifactor && !self.authenticating;
}

- (BOOL)isAccountCreationEnabled
{
    return self.hasDefaultAccount == NO && !self.authenticating;
}

- (BOOL)isForgotPasswordEnabled
{
    BOOL isEnabled = (self.userIsDotCom || [self isUrlValid]) && !self.shouldDisplayMultifactor;
    return isEnabled && !self.authenticating;
}

- (BOOL)isCancelButtonEnabled
{
    return !self.authenticating;
}

- (BOOL)isGesturesRecognizerEnabled
{
    return !self.authenticating;
}


#pragma mark - Text Helpers

- (NSString *)signInButtonTitle
{
    if (self.shouldDisplayMultifactor) {
        return NSLocalizedString(@"Verify", @"Button title for Two Factor code verification");
    } else if (self.userIsDotCom) {
        return NSLocalizedString(@"Sign In", @"Button title for Sign In Action");
    }
    
    return NSLocalizedString(@"Add Site", @"Button title for Add SelfHosted Site");
}

- (NSString *)toggleSignInButtonTitle
{
    if (self.userIsDotCom) {
        return NSLocalizedString(@"Add Self-Hosted Site", @"Button title for Toggle Sign Mode (Self Hosted vs DotCom");
    }
    
    return NSLocalizedString(@"Sign in to WordPress.com", @"Button title for Toggle Sign Mode (Self Hosted vs DotCom");
}

- (CGFloat)lastTextfieldMaxY
{
    if (self.shouldDisplayMultifactor) {
        return CGRectGetMaxY(self.multifactorText.frame);
    } else if (self.userIsDotCom) {
        return CGRectGetMaxY(self.passwordText.frame);
    }
    
    return CGRectGetMaxY(self.siteUrlText.frame);
}

- (CGFloat)editionModeMaxY
{
    UIView *bottomView = self.shouldDisplayMultifactor ? self.sendVerificationCodeButton : self.signInButton;
    return CGRectGetMaxY(bottomView.frame);
}


#pragma mark - Auth Helpers

- (void)startedAuthenticatingWithMessage:(NSString *)status
{
    [self setAuthenticating:YES status:status];
}

- (void)finishedAuthenticating
{
    [self setAuthenticating:NO status:nil];
}

- (void)setAuthenticating:(BOOL)authenticating status:(NSString *)status
{
    self.authenticating = authenticating;
    
    self.statusLabel.hidden = !(status.length > 0);
    self.statusLabel.text = status;
    
    [self updateControls];
}


#pragma mark - Backend Helpers

- (void)signIn
{
    NSString *username = self.usernameText.text;
    NSString *password = self.passwordText.text;
    NSString *multifactor = self.multifactorText.text;

    if (self.userIsDotCom || self.siteUrlText.text.isWordPressComURL) {
        [self signInWithWPComForUsername:username password:password multifactor:multifactor];
        return;
    }

    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];

        [api getBlogOptionsWithSuccess:^(id options){
            [self finishedAuthenticating];

            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInWithWPComForUsername:username password:password multifactor:multifactor];
            } else {
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self createSelfHostedAccountAndBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
            }
        } failure:^(NSError *error){
            [WPAnalytics track:WPAnalyticsStatLoginFailed];
            [self finishedAuthenticating];
            [self displayRemoteError:error];
        }];
    };

    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [WPAnalytics track:WPAnalyticsStatLoginFailedToGuessXMLRPC];
        [self handleGuessXMLRPCURLFailure:error];
    };

    [self startedAuthenticatingWithMessage:NSLocalizedString(@"Authenticating", nil)];
    
    NSString *siteUrl = [NSURL IDNEncodedURL:self.siteUrlText.text];
    [WordPressXMLRPCApi guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)signInWithWPComForUsername:(NSString *)username
                          password:(NSString *)password
                       multifactor:(NSString *)multifactor
{
    [self startedAuthenticatingWithMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];

    WordPressComOAuthClient *client = [WordPressComOAuthClient client];
    [client authenticateWithUsername:username
                            password:password
                     multifactorCode:multifactor
                             success:^(NSString *authToken) {
                                 
                                 [self finishedAuthenticating];
                                 self.userIsDotCom = YES;
                                 [self createWordPressComAccountForUsername:username authToken:authToken];
                                 
                             } failure:^(NSError *error) {
                                 
                                 // Remove the Spinner + Status Message
                                 [self finishedAuthenticating];
                                 
                                 // If needed, show the multifactor field
                                 if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
                                     [self displayMultifactorTextfield];
                                 } else {
                                     NSDictionary *properties = @{ @"multifactor" : @(self.shouldDisplayMultifactor) };
                                     [WPAnalytics track:WPAnalyticsStatLoginFailed withProperties:properties];
                                     
                                     [self displayRemoteError:error];
                                 }
                             }];
}

- (void)createWordPressComAccountForUsername:(NSString *)username authToken:(NSString *)authToken
{
    [self startedAuthenticatingWithMessage:NSLocalizedString(@"Getting account information", nil)];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];

    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlogsForAccount:account
                                success:^{
                                    // Dismiss the UI
                                    [self finishedAuthenticating];
                                    [self dismiss];
                                    
                                    // Hit the Tracker
                                    NSDictionary *properties = @{
                                        @"multifactor" : @(self.shouldDisplayMultifactor),
                                        @"dotcom_user" : @(YES)
                                    };
                                    
                                    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:properties];
                                    [WPAnalytics refreshMetadata];

                                    // once blogs for the accounts are synced, we want to update account details for it
                                    [accountService updateEmailAndDefaultBlogForWordPressComAccount:account];
                                }
                                failure:^(NSError *error) {
                                    [self finishedAuthenticating];
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
    self.blog = [blogService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!self.blog) {
        self.blog = [blogService createBlogWithAccount:account];
        if (url) {
            self.blog.url = url;
        }
        if (blogName) {
            self.blog.blogName = [blogName stringByDecodingXMLCharacters];
        }
    }
    self.blog.xmlrpc = xmlrpc;
    self.blog.options = options;
    [self.blog dataSave];
    [blogService syncBlog:self.blog success:nil failure:nil];

    if ([self.blog hasJetpack]) {
        if ([self.blog hasJetpackAndIsConnectedToWPCom]) {
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
    [self finishedAuthenticating];
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
        if ([HelpshiftUtils isHelpshiftEnabled]) {
            [self displayGenericErrorMessageWithHelpshiftButton:message];
        } else {
            [self displayGenericErrorMessage:message];
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
    [WPAnalytics track:WPAnalyticsStatTwoFactorCodeRequested];
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
    
    CGFloat newKeyboardOffset = (self.editionModeMaxY - CGRectGetMinY(keyboardFrame)) + GeneralWalkthroughStandardOffset;

    if (newKeyboardOffset < 0) {
        return;
    }

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToHideWithKeyboardOffset:newKeyboardOffset]) {
            control.alpha = GeneralWalkthroughAlphaHidden;
        }
        
        for (UIControl *control in [self controlsToMoveForTextEntry]) {
            CGRect frame = control.frame;
            frame.origin.y -= newKeyboardOffset;
            control.frame = frame;
        }
        
    } completion:^(BOOL finished) {

        self.keyboardOffset += newKeyboardOffset;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    CGFloat currentKeyboardOffset = self.keyboardOffset;
    self.keyboardOffset = 0;

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToHideWithKeyboardOffset:currentKeyboardOffset]) {
            control.alpha = GeneralWalkthroughAlphaEnabled;
        }
        
        for (UIControl *control in [self controlsToMoveForTextEntry]) {
            CGRect frame = control.frame;
            frame.origin.y += currentKeyboardOffset;
            control.frame = frame;
        }

    }];
}

- (NSArray *)controlsToMoveForTextEntry
{
    return @[ self.icon, self.usernameText, self.passwordText, self.multifactorText, self.sendVerificationCodeButton,
              self.siteUrlText, self.signInButton, self.statusLabel ];
}

- (NSArray *)controlsToHideWithKeyboardOffset:(CGFloat)offset
{
    // Always hide the Help + Badge
    NSMutableArray *controlsToHide = [NSMutableArray array];
    [controlsToHide addObjectsFromArray:@[ self.helpButton, self.helpBadge ]];
    
    // Find  controls that fall off the screen
    for (UIView *control in self.controlsToMoveForTextEntry) {
        if (control.frame.origin.y - offset <= 0) {
            [controlsToHide addObject:control];
        }
    }
    
    return controlsToHide;
}


#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSInteger unreadCount = [HelpshiftUtils unreadNotificationCount];
    self.helpBadge.text = [NSString stringWithFormat:@"%ld", unreadCount];
    self.helpBadge.hidden = (unreadCount == 0);
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
