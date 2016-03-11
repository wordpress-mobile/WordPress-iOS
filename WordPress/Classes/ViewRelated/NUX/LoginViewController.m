#import <WPXMLRPC/WPXMLRPC.h>
#import <Helpshift/HelpshiftSupport.h>
#import <WordPressShared/WPFontManager.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

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

#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "NSAttributedString+Util.h"
#import "NSURL+IDN.h"

#import "Constants.h"
#import "ReachabilityUtils.h"
#import "HelpshiftUtils.h"
#import "WordPress-Swift.h"

#import "LoginViewModel.h"
#import "SVProgressHUD.h"


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface LoginViewController () <UITextFieldDelegate, LoginViewModelPresenter>

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

@property (nonatomic, strong) LoginViewModel *viewModel;

// Measurements
@property (nonatomic, assign) CGFloat                   keyboardOffset;

// SharedCredentials
@property (nonatomic, assign) BOOL shouldAvoidRequestingSharedCredentials;
@property (nonatomic, assign) NSUInteger autofilledUsernameCredentialHash;
@property (nonatomic, assign) NSUInteger autofilledPasswordCredentialHash;

@end


#pragma mark ====================================================================================
#pragma mark LoginViewController
#pragma mark ====================================================================================

@implementation LoginViewController

static CGFloat const GeneralWalkthroughStandardOffset           = 15.0;
static CGFloat const GeneralWalkthroughMaxTextWidth             = 290.0;
static CGSize const GeneralWalkthroughTextFieldSize             = {320.0, 44.0};
static CGFloat const GeneralWalkthroughTextFieldOverlapY        = 1.0;
static CGSize const GeneralWalkthroughButtonSize                = {290.0, 41.0};
static CGFloat const GeneralWalkthroughSecondaryButtonHeight    = 33.0;
static CGFloat const GeneralWalkthroughStatusBarOffset          = 20.0;

static NSTimeInterval const GeneralWalkthroughAnimationDuration = 0.3f;
static CGFloat const GeneralWalkthroughAlphaHidden              = 0.0f;
static CGFloat const GeneralWalkthroughAlphaEnabled             = 1.0f;

static UIEdgeInsets const LoginBackButtonTitleInsets            = {0.0, 7.0, 0.0, 15.0};
static UIEdgeInsets const LoginBackButtonPadding                = {1.0, 0.0, 0.0, 0.0};
static UIEdgeInsets const LoginBackButtonPaddingPad             = {1.0, 13.0, 0.0, 0.0};

static UIEdgeInsets const LoginHelpButtonPadding                = {1.0, 0.0, 0.0, 13.0};
static UIEdgeInsets const LoginHelpButtonPaddingPad             = {1.0, 0.0, 0.0, 20.0};

static UIOffset const LoginOnePasswordPadding                   = {9.0, 0.0f};
static NSInteger const LoginVerificationCodeNumberOfLines       = 3;

static NSString * const LoginSharedWebCredentialFQDN = @"wordpress.com";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initializeViewModel];
    }
    return self;
}

- (void)initializeViewModel
{
    _viewModel = [LoginViewModel new];
    _viewModel.presenter = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.view.backgroundColor = [WPStyleGuide wordPressBlue];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(applicationWillEnterForegroundNotification:)
                          name:UIApplicationWillEnterForegroundNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(applicationDidBecomeActiveNotification:)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
    
    // Initialize Interface
    [self addMainView];
    [self addControls];
    [self bindToViewModel];
    [self update3DTouchForLogIn];
}

- (void)bindToViewModel
{
    RAC(self.viewModel, username) = self.usernameText.rac_textSignal;
    RAC(self.viewModel, password) = self.passwordText.rac_textSignal;
    RAC(self.viewModel, multifactorCode) = self.multifactorText.rac_textSignal;
    RAC(self.viewModel, siteUrl) = self.siteUrlText.rac_textSignal;
    
    // Do we have a default account?
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    // Initialize flags!
    self.viewModel.onlyDotComAllowed = self.onlyDotComAllowed;
    self.viewModel.cancellable = self.cancellable;
    self.viewModel.hasDefaultAccount = (defaultAccount != nil);
    self.viewModel.userIsDotCom = (defaultAccount == nil) && (self.onlyDotComAllowed || !self.prefersSelfHosted);
    self.viewModel.shouldDisplayMultifactor = NO;
    self.viewModel.shouldReauthenticateDefaultAccount = self.shouldReauthenticateDefaultAccount;
    
    if (self.viewModel.shouldReauthenticateDefaultAccount) {
        self.usernameText.text = defaultAccount.username;
        self.viewModel.username = defaultAccount.username;
        self.viewModel.userIsDotCom = YES;
    }
}

- (void)update3DTouchForLogIn
{
    WP3DTouchShortcutCreator *shortcutCreator = [WP3DTouchShortcutCreator new];
    [shortcutCreator createShortcuts:self.cancellable];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self autoFillLoginWithSharedWebCredentialsIfAvailable];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // Previously we reloaded the interface in viewWillAppear:, however there were certain situations
    // where the view's frame would be in the wrong orientation (e.g. after viewing the support view controller
    // in landscape and then dismissing it) resulting in an incorrect layout.
    // Fortunately, the frame is correct in viewWillLayoutSubviews.
    [self reloadInterface];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameText) {
        [self.passwordText becomeFirstResponder];
    } else if (textField == self.passwordText) {
        if (self.viewModel.userIsDotCom) {
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

#pragma mark - AutoFill Authentication

- (void)autoFillLoginWithSharedWebCredentialsIfAvailable
{
    __weak __typeof(self)weakSelf = self;
    [self requestSharedWebCredentials:^(NSString *username, NSString *password) {
        
        if (!username.length || !password.length) {
            return;
        }
        if (!weakSelf.viewModel.userIsDotCom) {
            // If the user has swtiched away from dotcom sign-in, swith back before autofilling
            [weakSelf.viewModel toggleSignInFormAction];
        }
        
        // Update the model
        weakSelf.viewModel.username = username;
        weakSelf.viewModel.password = password;
        // Update the fields for display
        [weakSelf setUsernameTextValue:username];
        [weakSelf setPasswordTextValue:password];
        
        weakSelf.autofilledUsernameCredentialHash = [username hash];
        weakSelf.autofilledPasswordCredentialHash = [password hash];
        
        [WPAnalytics track:WPAnalyticsStatSafariCredentialsLoginFilled];
    }];
}

- (void)updateAutoFillLoginCredentialsIfNeeded:(NSString *)username password:(NSString *)password
{
    // Don't try and update credentials for self-hosted.
    if (!self.viewModel.userIsDotCom) {
        return;
    }
    
    // If the user changed screen names, don't try and update/create a new shared web credential.
    // We'll let Safari handle creating newly saved usernames/passwords.
    if (self.autofilledUsernameCredentialHash != [username hash]) {
        return;
    }
    
    // If the user didn't change the password from previousl filled password no update is needed.
    if (self.autofilledPasswordCredentialHash == [password hash]) {
        return;
    }
    
    // Update the shared credential
    CFStringRef fqdnStr = (__bridge CFStringRef)LoginSharedWebCredentialFQDN;
    CFStringRef usernameStr = (__bridge CFStringRef)username;
    CFStringRef passwordStr = (__bridge CFStringRef)password;
    SecAddSharedWebCredential(fqdnStr, usernameStr, passwordStr, ^(CFErrorRef  _Nullable error) {
        if (error) {
            DDLogError(@"Error occurred updating shared web credential: %@", error);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [WPAnalytics track:WPAnalyticsStatSafariCredentialsLoginUpdated];
        });
    });
}

- (void)requestSharedWebCredentials:(void(^)(NSString *username, NSString *password))completion
{
    if (self.shouldAvoidRequestingSharedCredentials) {
        return;
    }
    
    // Disable repeat calls for shared credentials.
    self.shouldAvoidRequestingSharedCredentials = YES;
    CFStringRef fqdnStr = (__bridge CFStringRef)LoginSharedWebCredentialFQDN;
    SecRequestSharedWebCredential(fqdnStr, NULL, ^(CFArrayRef credentials, CFErrorRef error) {
        
        if (error != NULL) {
            DDLogError(@"Completed requesting shared web credentials with: %@", error);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, nil);
                });
            }
            return;
        }
        
        // Check if any credential values are available
        if (CFArrayGetCount(credentials) > 0) {
            
            // There will only ever be one credential dictionary since the selection is automatically handled
            CFDictionaryRef credentialDict =CFArrayGetValueAtIndex(credentials, 0);
            CFStringRef userNameStr = CFDictionaryGetValue(credentialDict, kSecAttrAccount);
            CFStringRef passwordStr = CFDictionaryGetValue(credentialDict, kSecSharedPassword);
            if (userNameStr == NULL || passwordStr == NULL) {
                // No complete shared credentials found, or credentials were saved as NULL values
                return;
            }
            
            NSString *userName = (__bridge NSString *)userNameStr;
            NSString *password = (__bridge NSString *)passwordStr;
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(userName, password);
                });
            }
        }
    });
}

#pragma mark - 1Password Related

- (void)displayOnePasswordEmptySiteAlert
{
    NSString *message = NSLocalizedString(@"A site address is required before 1Password can be used.",
                                          @"Error message displayed when the user is Signing into a self hosted site and "
                                          @"tapped the 1Password Button before typing his siteURL");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Accept", @"Accept Button Title") handler:nil];
    
    [self presentViewController:alertController animated:YES completion:nil];
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
    // When the verification code field is displayed, the username field is disabled which
    // means that the 1Password button cannot be tapped directly (because it's the rightView of the username field).
    // Instead, we can trigger 1Password if the background gesture recognizer detects a tap on the 1Password button.
    CGPoint location = [tapGestureRecognizer locationOfTouch:0 inView:self.onePasswordButton];
    if (CGRectContainsPoint(self.onePasswordButton.bounds, location)) {
        [self findLoginFromOnePassword:self];
    } else {
        [self.view endEditing:YES];
        [self hideMultifactorTextfieldIfNeeded];
    }
}

- (IBAction)signInButtonAction:(id)sender
{
    [self.view endEditing:YES];
    [self.viewModel signInButtonAction];
}

- (IBAction)toggleSignInFormAction:(id)sender
{
    // Controls are layed out in initializeView. Calling this method in an animation block will animate the controls
    // to their new positions.
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         self.viewModel.shouldDisplayMultifactor = NO;
                         self.viewModel.userIsDotCom = !self.viewModel.userIsDotCom;
                         [self reloadInterface];
                     }];
}


- (IBAction)cancelButtonAction:(id)sender
{
    if (self.dismissBlock) {
        self.dismissBlock(YES);
    }
}

- (IBAction)forgotPassword:(id)sender
{
    [self.viewModel forgotPasswordButtonAction];
}

- (IBAction)findLoginFromOnePassword:(id)sender
{
    [self.viewModel onePasswordButtonActionForViewController:self sender:sender];
}

- (IBAction)sendVerificationCode:(id)sender
{
    [self.viewModel requestOneTimeCode];
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
    helpBadge.font = [WPFontManager systemRegularFontOfSize:8.0];
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
    [onePasswordButton setImage:[UIImage imageNamed:@"onepassword-wp-button"] forState:UIControlStateNormal];
    [onePasswordButton addTarget:self action:@selector(findLoginFromOnePassword:) forControlEvents:UIControlEventTouchUpInside];
    [onePasswordButton sizeToFit];
    
    usernameText.rightView = onePasswordButton;
    usernameText.rightViewPadding = LoginOnePasswordPadding;
    
    usernameText.rightViewMode = [self.viewModel isOnePasswordEnabled] ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
    
    // Add Password
    WPWalkthroughTextField *passwordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
    passwordText.backgroundColor = [UIColor whiteColor];
    passwordText.placeholder = NSLocalizedString(@"Password", nil);
    passwordText.font = [WPNUXUtility textFieldFont];
    passwordText.delegate = self;
    passwordText.secureTextEntry = YES;
    passwordText.returnKeyType = self.viewModel.userIsDotCom ? UIReturnKeyDone : UIReturnKeyNext;
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
    [cancelButton setTitleEdgeInsets:LoginBackButtonTitleInsets];
    [cancelButton.titleLabel setFont:[WPFontManager systemRegularFontOfSize:15.0]];
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
    [self layoutControls];
}

- (void)layoutControls
{
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    CGFloat textFieldX = (viewWidth - GeneralWalkthroughTextFieldSize.width) * 0.5f;
    CGFloat textLabelX = (viewWidth - GeneralWalkthroughMaxTextWidth) * 0.5f;
    CGFloat buttonX = (viewWidth - GeneralWalkthroughButtonSize.width) * 0.5f;
    
    UIEdgeInsets helpButtonPadding = [UIDevice isPad] ? LoginHelpButtonPaddingPad : LoginHelpButtonPadding;
    UIEdgeInsets backButtonPadding = [UIDevice isPad] ? LoginBackButtonPaddingPad : LoginBackButtonPadding;
    
    // Layout Help Button
    CGFloat helpButtonX = viewWidth - CGRectGetWidth(self.helpButton.frame) - helpButtonPadding.right;
    CGFloat helpButtonY = GeneralWalkthroughStatusBarOffset + helpButtonPadding.top;
    self.helpButton.frame = CGRectIntegral(CGRectMake(helpButtonX, helpButtonY, CGRectGetWidth(self.helpButton.frame), GeneralWalkthroughButtonSize.height));

    // layout help badge
    CGFloat helpBadgeX = viewWidth - CGRectGetWidth(self.helpBadge.frame) - helpButtonPadding.right + 5;
    CGFloat helpBadgeY = GeneralWalkthroughStatusBarOffset + CGRectGetHeight(self.helpBadge.frame) - 5;
    self.helpBadge.frame = CGRectIntegral(CGRectMake(helpBadgeX, helpBadgeY, CGRectGetWidth(self.helpBadge.frame), CGRectGetHeight(self.helpBadge.frame)));

    // Layout Cancel Button
    CGFloat cancelButtonX = backButtonPadding.left;
    CGFloat cancelButtonY = GeneralWalkthroughStatusBarOffset + backButtonPadding.top;
    self.cancelButton.frame = CGRectIntegral(CGRectMake(cancelButtonX, cancelButtonY, CGRectGetWidth(self.cancelButton.frame), GeneralWalkthroughButtonSize.height));

    // Calculate total height and starting Y origin of controls
    CGFloat heightOfControls = CGRectGetHeight(self.icon.frame) + GeneralWalkthroughStandardOffset + (self.viewModel.userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldSize.height + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonSize.height;
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
    CGFloat multifactorTextY = self.viewModel.userIsDotCom ? CGRectGetMaxY(self.passwordText.frame) : CGRectGetMaxY(self.siteUrlText.frame);
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
        self.dismissBlock(NO);
    }
}

- (void)showCreateAccountView
{
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)showHelpViewController:(BOOL)animated
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:supportViewController animated:animated];
}

#pragma mark - Validation Helpers

- (BOOL)isMultifactorFilled
{
    return self.viewModel.multifactorCode.isEmpty == NO;
}

#pragma mark - Interface Helpers: Buttons

- (CGFloat)lastTextfieldMaxY
{
    if (self.viewModel.shouldDisplayMultifactor) {
        return CGRectGetMaxY(self.multifactorText.frame);
    } else if (self.viewModel.userIsDotCom) {
        return CGRectGetMaxY(self.passwordText.frame);
    }
    
    return CGRectGetMaxY(self.siteUrlText.frame);
}

- (CGFloat)editionModeMaxY
{
    UIView *bottomView = self.viewModel.shouldDisplayMultifactor ? self.sendVerificationCodeButton : self.signInButton;
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
    self.viewModel.authenticating = authenticating;
    
    self.statusLabel.hidden = !(status.length > 0);
    self.statusLabel.text = status;
    
    self.view.userInteractionEnabled = !authenticating;
}

#pragma mark - Multifactor Helpers

- (void)displayMultifactorTextfield
{
    [WPAnalytics track:WPAnalyticsStatTwoFactorCodeRequested];
    
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         self.viewModel.shouldDisplayMultifactor = YES;
                         [self reloadInterface];
                         [self.multifactorText becomeFirstResponder];
                     }];
}

- (void)hideMultifactorTextfieldIfNeeded
{
    if (!self.viewModel.shouldDisplayMultifactor) {
        return;
    }
    
    [UIView animateWithDuration:GeneralWalkthroughAnimationDuration
                     animations:^{
                         self.viewModel.shouldDisplayMultifactor = NO;
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
            // Fix: Revert to Enabled only those fields that were, effectively, hidden!
            if (control.alpha == GeneralWalkthroughAlphaHidden) {
                control.alpha = GeneralWalkthroughAlphaEnabled;
            }
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
    loginViewController.dismissBlock = ^(BOOL cancelled){
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navController.navigationBar.translucent = NO;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - LoginViewModelPresenter

- (void)showActivityIndicator:(BOOL)show
{
    [self.signInButton showActivityIndicator:show];
}

- (void)showAlertWithMessage:(NSString *)message
{
    NSParameterAssert(message);
    [SVProgressHUD showSuccessWithStatus:message];
}

- (void)setUsernameAlpha:(CGFloat)alpha
{
    self.usernameText.alpha = alpha;
}

- (void)setUsernameEnabled:(BOOL)enabled
{
    self.usernameText.enabled = enabled;
}

- (void)setUsernameTextValue:(NSString *)username
{
    self.usernameText.text = username;
}

- (void)setPasswordAlpha:(CGFloat)alpha
{
    self.passwordText.alpha = alpha;
}

- (void)setPasswordEnabled:(BOOL)enabled
{
    self.passwordText.enabled = enabled;
}

- (void)setPasswordTextValue:(NSString *)passwordText
{
    self.passwordText.text = passwordText;
}

- (void)setPasswordSecureEntry:(BOOL)secureTextEntry;
{
    [self.passwordText setSecureTextEntry:secureTextEntry];
}

- (void)setSiteAlpha:(CGFloat)alpha
{
    self.siteUrlText.alpha = alpha;
}

- (void)setMultiFactorAlpha:(CGFloat)alpha
{
    self.multifactorText.alpha = alpha;
}

- (void)setSiteUrlEnabled:(BOOL)enabled
{
    self.siteUrlText.enabled = enabled;
}

- (void)setMultifactorEnabled:(BOOL)enabled
{
    self.multifactorText.enabled = enabled;
}

- (void)setMultifactorTextValue:(NSString *)multifactorText
{
    self.multifactorText.text = multifactorText;
}

- (void)setCancelButtonHidden:(BOOL)hidden
{
    self.cancelButton.hidden = hidden;
}

- (void)setForgotPasswordHidden:(BOOL)hidden
{
    self.forgotPassword.hidden = hidden;
}

- (void)setSendVerificationCodeButtonHidden:(BOOL)hidden
{
    self.sendVerificationCodeButton.hidden = hidden;
}

- (void)setAccountCreationButtonHidden:(BOOL)hidden
{
    self.skipToCreateAccount.hidden = hidden;
}

- (void)setSignInButtonEnabled:(BOOL)enabled
{
    self.signInButton.enabled = enabled;
}

- (void)setSignInButtonTitle:(NSString *)title
{
    self.signInButton.accessibilityIdentifier = title;
    [self.signInButton setTitle:title forState:UIControlStateNormal];
}

- (void)setToggleSignInButtonTitle:(NSString *)title
{
    self.toggleSignInForm.accessibilityIdentifier = title;
    [self.toggleSignInForm setTitle:title forState:UIControlStateNormal];
}

- (void)setToggleSignInButtonHidden:(BOOL)hidden
{
    self.toggleSignInForm.hidden = hidden;
}

- (void)setPasswordTextReturnKeyType:(UIReturnKeyType)returnKeyType
{
    self.passwordText.returnKeyType = returnKeyType;
}

- (void)displayErrorMessageForInvalidOrMissingFields
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) withSupportButton:NO];
}

- (void)displayReservedNameErrorMessage
{
    [WPError showAlertWithTitle:NSLocalizedString(@"Self-hosted site?", nil) message:NSLocalizedString(@"Please enter the URL of your WordPress site.", nil) withSupportButton:NO];
}

- (void)reloadInterfaceWithAnimation:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:GeneralWalkthroughAnimationDuration animations:^{
            [self reloadInterface];
        }];
    } else {
        [self reloadInterface];
    }
}

- (void)openURLInSafari:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

- (void)displayLoginMessage:(NSString *)message
{
    [self startedAuthenticatingWithMessage:message];
}

- (void)dismissLoginMessage
{
    [self finishedAuthenticating];
}

- (void)setFocusToSiteUrlText
{
    [self.siteUrlText becomeFirstResponder];
}

- (void)setFocusToMultifactorText
{
    [self.multifactorText becomeFirstResponder];
}

- (void)dismissLoginView
{
    [self dismiss];
}

- (void)displayOverlayViewWithMessage:(NSString *)message firstButtonText:(NSString *)firstButtonText firstButtonCallback:(OverlayViewCallback)firstButtonCallback secondButtonText:(NSString *)secondButtonText secondButtonCallback:(OverlayViewCallback)secondButtonCallback accessibilityIdentifier:(NSString *)accessibilityIdentifier;
{
    WPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.primaryButtonText = firstButtonText;
    overlayView.primaryButtonCompletionBlock = firstButtonCallback;
    overlayView.secondaryButtonText = secondButtonText;
    overlayView.secondaryButtonCompletionBlock = secondButtonCallback;
    
    if (accessibilityIdentifier.length > 0) {
        overlayView.accessibilityIdentifier = accessibilityIdentifier;
    }
    
    [self.view addSubview:overlayView];
}

- (void)displayHelpViewControllerWithAnimation:(BOOL)animated
{
    [self showHelpViewController:animated];
}

- (void)displayHelpshiftConversationView
{
    NSDictionary *metaData = @{@"Source": @"Failed login",
                               @"Username": self.viewModel.username,
                               @"SiteURL": self.viewModel.siteUrl};

    [HelpshiftSupport showConversation:self withOptions:@{HelpshiftSupportCustomMetadataKey: metaData}];
    [WPAnalytics track:WPAnalyticsStatSupportOpenedHelpshiftScreen];
}

- (void)displayWebViewForURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;
{
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:url];
    if (username.length > 0 && password.length > 0) {
        webViewController.username = username;
        webViewController.password = password;
    }

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)endViewEditing
{
    [self.view endEditing:NO];
}

#pragma mark - Status bar management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Notifications

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    // If the user hasn't filled in a username and password, toggle the prompt for autofill when called on didBecomeActive.
    if (self.usernameText.text.length == 0 && self.passwordText.text.length == 0) {
        self.shouldAvoidRequestingSharedCredentials = NO;
    }
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self autoFillLoginWithSharedWebCredentialsIfAvailable];
}

@end
