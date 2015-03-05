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
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString *JetpackInstallRelativePath             = @"plugin-install.php?tab=plugin-information&plugin=jetpack";
static NSString *JetpackMoreInformationURL              = @"http://ios.wordpress.org/faq/#faq_15";

static CGFloat const JetpackiOS7StatusBarOffset         = 20.0;
static CGFloat const JetpackStandardOffset              = 16;
static CGFloat const JetpackTextFieldWidth              = 320.0;
static CGFloat const JetpackMaxTextWidth                = 289.0;
static CGFloat const JetpackTextFieldHeight             = 44.0;
static CGFloat const JetpackIconVerticalOffset          = 77;
static CGFloat const JetpackSignInButtonWidth           = 289.0;
static CGFloat const JetpackSignInButtonHeight          = 41.0;

static NSTimeInterval const JetpackAnimationDuration    = 0.3f;
static CGFloat const JetpackTextFieldAlphaHidden        = 0.0f;
static CGFloat const JetpackTextFieldAlphaDisabled      = 0.5f;
static CGFloat const JetpackTextFieldAlphaEnabled       = 1.0f;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface JetpackSettingsViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView               *icon;
@property (nonatomic, strong) UILabel                   *descriptionLabel;
@property (nonatomic, strong) WPWalkthroughTextField    *usernameTextField;
@property (nonatomic, strong) WPWalkthroughTextField    *passwordTextField;
@property (nonatomic, strong) WPWalkthroughTextField    *multifactorTextField;
@property (nonatomic, strong) WPNUXMainButton           *signInButton;
@property (nonatomic, strong) WPNUXMainButton           *installJetbackButton;
@property (nonatomic, strong) UIButton                  *moreInformationButton;
@property (nonatomic, strong) WPNUXSecondaryButton      *skipButton;

@property (nonatomic, strong) Blog                      *blog;

@property (nonatomic, assign) CGFloat                   keyboardOffset;
@property (nonatomic, assign) BOOL                      authenticating;
@property (nonatomic, assign) BOOL                      shouldDisplayMultifactor;

@end


#pragma mark ====================================================================================
#pragma mark JetpackSettingsViewController
#pragma mark ====================================================================================

@implementation JetpackSettingsViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    self = [super init];
    if (self) {
        _blog = blog;
        _showFullScreen = YES;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutControls];
}


#pragma mark - LifeCycle Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:self.showFullScreen animated:animated];
    [self reloadInterface];
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Jetpack Connect", @"");
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [nc addObserver:self selector:@selector(textFieldDidChangeNotificationReceived:) name:UITextFieldTextDidChangeNotification object:self.usernameTextField];
    [nc addObserver:self selector:@selector(textFieldDidChangeNotificationReceived:) name:UITextFieldTextDidChangeNotification object:self.passwordTextField];

    [self addControls];
    [self addGesturesRecognizer];
    [self addSkipButtonIfNeeded];
    
    [self updateMessage];
    [self updateSaveButton];

    double delayInSeconds = 0.1;
    [self performSelector:@selector(checkForJetpack) withObject:nil afterDelay:delayInSeconds];
}

// This resolves a crash due to JetpackSettingsViewController previously using a .xib.
// Source: http://stackoverflow.com/questions/17708292/not-key-value-coding-compliant-error-from-deleted-xib
- (void)loadView
{
    [super loadView];
}

- (void)addControls
{
    // Add Logo
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-jetpack-gray"]];
    icon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Add Description
    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionLabel.font = [WPNUXUtility descriptionTextFont];
    descriptionLabel.text = NSLocalizedString(@"Hold the web in the palm of your hand. Full publishing power in a pint-sized package.", @"NUX First Walkthrough Page 1 Description");
    descriptionLabel.textColor = [WPStyleGuide allTAllShadeGrey];
    descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Add Username
    WPWalkthroughTextField *usernameTextField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
    usernameTextField.backgroundColor = [UIColor whiteColor];
    usernameTextField.placeholder = NSLocalizedString(@"WordPress.com username", @"");
    usernameTextField.font = [WPNUXUtility textFieldFont];
    usernameTextField.adjustsFontSizeToFitWidth = YES;
    usernameTextField.delegate = self;
    usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameTextField.text = self.blog.jetpackUsername;
    usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Add Password
    WPWalkthroughTextField *passwordTextField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
    passwordTextField.backgroundColor = [UIColor whiteColor];
    passwordTextField.placeholder = NSLocalizedString(@"WordPress.com password", @"");
    passwordTextField.font = [WPNUXUtility textFieldFont];
    passwordTextField.delegate = self;
    passwordTextField.secureTextEntry = YES;
    passwordTextField.showSecureTextEntryToggle = YES;
    passwordTextField.text = self.blog.jetpackPassword;
    passwordTextField.clearsOnBeginEditing = YES;
    passwordTextField.showTopLineSeparator = YES;
    passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
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

    // Add Sign In Button
    WPNUXMainButton *signInButton = [[WPNUXMainButton alloc] init];
    [signInButton addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
    signInButton.enabled = NO;
    signInButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Add Download Button
    WPNUXMainButton *installJetbackButton = [[WPNUXMainButton alloc] init];
    [installJetbackButton setTitle:NSLocalizedString(@"Install Jetpack", @"") forState:UIControlStateNormal];
    [installJetbackButton addTarget:self action:@selector(openInstallJetpackURL) forControlEvents:UIControlEventTouchUpInside];
    installJetbackButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Add More Information Button
    UIButton *moreInformationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [moreInformationButton setTitle:NSLocalizedString(@"More information", @"") forState:UIControlStateNormal];
    [moreInformationButton addTarget:self action:@selector(openMoreInformationURL) forControlEvents:UIControlEventTouchUpInside];
    [moreInformationButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    moreInformationButton.titleLabel.font = [WPNUXUtility confirmationLabelFont];
    moreInformationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // Attach Subviews
    [self.view addSubview:icon];
    [self.view addSubview:descriptionLabel];
    [self.view addSubview:usernameTextField];
    [self.view addSubview:passwordTextField];
    [self.view addSubview:multifactorText];
    [self.view addSubview:signInButton];
    [self.view addSubview:installJetbackButton];
    [self.view addSubview:moreInformationButton];
    
    // Keep the Reference!
    self.icon = icon;
    self.descriptionLabel = descriptionLabel;
    self.usernameTextField = usernameTextField;
    self.passwordTextField = passwordTextField;
    self.multifactorTextField = multifactorText;
    self.signInButton = signInButton;
    self.installJetbackButton = installJetbackButton;
    self.moreInformationButton = moreInformationButton;
}

- (void)addGesturesRecognizer
{
    UITapGestureRecognizer *dismissKeyboardTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    dismissKeyboardTapRecognizer.cancelsTouchesInView = YES;
    dismissKeyboardTapRecognizer.delegate = self;
    [self.view addGestureRecognizer:dismissKeyboardTapRecognizer];
}

- (void)addSkipButtonIfNeeded
{
    if (!self.canBeSkipped) {
        return;
    }
    
    if (self.showFullScreen) {
        WPNUXSecondaryButton *skipButton = [[WPNUXSecondaryButton alloc] init];
        [skipButton setTitle:NSLocalizedString(@"Skip", @"") forState:UIControlStateNormal];
        [skipButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
        [skipButton addTarget:self action:@selector(skipAction:) forControlEvents:UIControlEventTouchUpInside];
        skipButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        skipButton.accessibilityIdentifier = @"Skip";
        [skipButton sizeToFit];
        [self.view addSubview:skipButton];
        self.skipButton = skipButton;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Skip", @"")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(skipAction:)];
    }
    
    self.navigationItem.hidesBackButton = YES;
}


#pragma mark Interface Helpers

- (void)updateSaveButton
{
    BOOL enabled = (!_authenticating && _usernameTextField.text.length && _passwordTextField.text.length);
    self.signInButton.enabled = enabled;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
    [self hideMultifactorTextfieldIfNeeded];
}

- (void)reloadInterface
{
    [self updateControls];
    [self layoutControls];
}

- (void)updateControls
{
    BOOL hasJetpack                 = self.blog.hasJetpack;
    
    _usernameTextField.alpha        = self.shouldDisplayMultifactor ? JetpackTextFieldAlphaDisabled : JetpackTextFieldAlphaEnabled;
    _passwordTextField.alpha        = self.shouldDisplayMultifactor ? JetpackTextFieldAlphaDisabled : JetpackTextFieldAlphaEnabled;
    _multifactorTextField.alpha     = self.shouldDisplayMultifactor ? JetpackTextFieldAlphaEnabled  : JetpackTextFieldAlphaHidden;
    
    _usernameTextField.enabled      = !self.shouldDisplayMultifactor;
    _passwordTextField.enabled      = !self.shouldDisplayMultifactor;
    _multifactorTextField.enabled   = self.shouldDisplayMultifactor;
    
    _usernameTextField.hidden       = !hasJetpack;
    _passwordTextField.hidden       = !hasJetpack;
    _multifactorTextField.hidden    = !hasJetpack;
    _signInButton.hidden            = !hasJetpack;
    _installJetbackButton.hidden    = hasJetpack;
    _moreInformationButton.hidden   = hasJetpack;
    
    
    NSString *title = NSLocalizedString(@"Save", nil);
    if (self.shouldDisplayMultifactor) {
        title = NSLocalizedString(@"Verify", nil);
    } else if (self.showFullScreen) {
        title = NSLocalizedString(@"Sign In", nil);
    }
    
    [self.signInButton setTitle:title forState:UIControlStateNormal];
    
}

- (void)layoutControls
{
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);

    CGFloat textFieldX = (viewWidth - JetpackTextFieldWidth) * 0.5f;
    CGFloat buttonX = (viewWidth - JetpackSignInButtonWidth) * 0.5f;
    
    // Layout Icon
    CGFloat iconX = (viewWidth - CGRectGetWidth(_icon.frame)) * 0.5f;
    CGFloat iconY = JetpackiOS7StatusBarOffset + JetpackIconVerticalOffset;
    _icon.frame = CGRectIntegral(CGRectMake(iconX, iconY, CGRectGetWidth(_icon.frame), CGRectGetHeight(_icon.frame)));

    // Layout Description
    CGSize labelSize = [_descriptionLabel suggestedSizeForWidth:JetpackMaxTextWidth];
    CGFloat descriptionLabelX = (viewWidth - labelSize.width) * 0.5f;
    CGFloat descriptionLabelY = CGRectGetMaxY(_icon.frame) + 0.5*JetpackStandardOffset;
    _descriptionLabel.frame = CGRectIntegral(CGRectMake(descriptionLabelX, descriptionLabelY, labelSize.width, labelSize.height));

    // Layout Username
    CGFloat usernameTextFieldY = CGRectGetMaxY(_descriptionLabel.frame) + JetpackStandardOffset;
    _usernameTextField.frame = CGRectIntegral(CGRectMake(textFieldX, usernameTextFieldY, JetpackTextFieldWidth, JetpackTextFieldHeight));
    
    // Layout Password
    CGFloat passwordTextFieldY = CGRectGetMaxY(_usernameTextField.frame);
    _passwordTextField.frame = CGRectIntegral(CGRectMake(textFieldX, passwordTextFieldY, JetpackTextFieldWidth, JetpackTextFieldHeight));
    
    CGFloat multifactorTextY = CGRectGetMaxY(_passwordTextField.frame);
    _multifactorTextField.frame = CGRectIntegral(CGRectMake(textFieldX, multifactorTextY, JetpackTextFieldWidth, JetpackTextFieldHeight));
    
    // Layout Sign in Button
    CGFloat signInButtonY = [self lastTextfieldMaxY] + JetpackStandardOffset;
    _signInButton.frame = CGRectMake(buttonX, signInButtonY, JetpackSignInButtonWidth, JetpackSignInButtonHeight);

    // Layout Download Button
    CGFloat installJetpackButtonY = CGRectGetMaxY(_descriptionLabel.frame) + JetpackStandardOffset;
    _installJetbackButton.frame = CGRectIntegral(CGRectMake(buttonX, installJetpackButtonY, JetpackSignInButtonWidth, JetpackSignInButtonHeight));

    // Layout More Information Button
    CGFloat moreInformationButtonY = CGRectGetMaxY(_installJetbackButton.frame);
    _moreInformationButton.frame = CGRectIntegral(CGRectMake(buttonX, moreInformationButtonY, JetpackSignInButtonWidth, JetpackSignInButtonHeight));

    // Layout Skip Button
    CGFloat skipButtonX = viewWidth - CGRectGetWidth(_skipButton.frame) - JetpackStandardOffset;
    CGFloat skipButtonY = viewHeight - JetpackStandardOffset - CGRectGetHeight(_skipButton.frame);
    _skipButton.frame = CGRectMake(skipButtonX, skipButtonY, CGRectGetWidth(_skipButton.frame), CGRectGetHeight(_skipButton.frame));

    NSArray *viewsToCenter;
    if (self.blog.hasJetpack) {
        viewsToCenter = @[_icon, _descriptionLabel, _usernameTextField, _passwordTextField, _multifactorTextField, _signInButton];
    } else {
        viewsToCenter = @[_icon, _descriptionLabel, _installJetbackButton, _moreInformationButton];
    }
    
    UIView *endingView = [viewsToCenter lastObject];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_icon andEndingView:endingView forHeight:(viewHeight - 100)];
}

- (CGFloat)lastTextfieldMaxY
{
    if (self.shouldDisplayMultifactor) {
        return CGRectGetMaxY(self.multifactorTextField.frame);
    } else {
        return CGRectGetMaxY(self.passwordTextField.frame);
    }
}


#pragma mark - Button Helpers

- (void)skipAction:(id)sender
{
    if (self.completionBlock) {
        self.completionBlock(NO);
    }
}

- (void)saveAction:(id)sender
{
    [self dismissKeyboard];
    [self setAuthenticating:YES];

    void (^finishedBlock)() = ^() {
        [self setAuthenticating:NO];
        if (self.completionBlock) {
            self.completionBlock(YES);
        }
    };

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self setAuthenticating:NO];
        [self handleSignInError:error];
    };

    [self.blog validateJetpackUsername:self.usernameTextField.text
                              password:self.passwordTextField.text
                       multifactorCode:self.multifactorTextField.text
                               success:finishedBlock
                               failure:failureBlock];
}


#pragma mark - Helpers

- (void)handleSignInError:(NSError *)error
{
    // If needed, show the multifactor field
    if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
        [self displayMultifactorTextfield];
        return;
    }
    
    [WPError showNetworkingAlertWithError:error];
}


#pragma mark - Multifactor Helpers

- (void)displayMultifactorTextfield
{
    self.shouldDisplayMultifactor = YES;
    
    [UIView animateWithDuration:JetpackAnimationDuration
                     animations:^{
                         [self reloadInterface];
                         [self.multifactorTextField becomeFirstResponder];
                     }];
}

- (void)hideMultifactorTextfieldIfNeeded
{
    if (!self.shouldDisplayMultifactor) {
        return;
    }
    
    self.shouldDisplayMultifactor = NO;
    [UIView animateWithDuration:JetpackAnimationDuration
                     animations:^{
                         [self reloadInterface];
                     } completion:^(BOOL finished) {
                         self.multifactorTextField.text = nil;
                     }];
}



#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField || textField == self.multifactorTextField) {
        [self saveAction:nil];
    }

    return YES;
}

- (void)textFieldDidChangeNotificationReceived:(NSNotification *)notification
{
    [self updateSaveButton];
}


#pragma mark - Keyboard Helpers

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat newKeyboardOffset = (CGRectGetMaxY(_signInButton.frame) - CGRectGetMinY(keyboardFrame)) + JetpackStandardOffset;

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
            control.alpha = JetpackTextFieldAlphaHidden;
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
            control.alpha = JetpackTextFieldAlphaEnabled;
        }
    }];
}

- (NSArray *)controlsToMoveForTextEntry
{
    return @[_usernameTextField, _passwordTextField, _multifactorTextField, _signInButton, _icon, _descriptionLabel];
}

- (NSArray *)controlsToHideForTextEntry
{
    NSArray *controlsToHide = @[];
    BOOL isSmallScreen = !(CGRectGetHeight(self.view.bounds) > 480.0);
    if (isSmallScreen) {
        controlsToHide = [controlsToHide arrayByAddingObject:_icon];
        controlsToHide = [controlsToHide arrayByAddingObject:_descriptionLabel];
    }
    
    return controlsToHide;
}


#pragma mark - Custom methods

- (void)setAuthenticating:(BOOL)authenticating
{
    _authenticating = authenticating;
    self.usernameTextField.enabled = !authenticating;
    self.passwordTextField.enabled = !authenticating;
    [self updateSaveButton];
    [self.signInButton showActivityIndicator:authenticating];
}


#pragma mark - Browser

- (void)openInstallJetpackURL
{
    [WPAnalytics track:WPAnalyticsStatSelectedInstallJetpack];

    NSString *targetURL = [_blog adminUrlWithPath:JetpackInstallRelativePath];
    [self openURL:[NSURL URLWithString:targetURL] username:_blog.username password:_blog.password wpLoginURL:[NSURL URLWithString:_blog.loginUrl]];
}

- (void)openMoreInformationURL
{
    NSURL *targetURL = [NSURL URLWithString:JetpackMoreInformationURL];
    [self openURL:targetURL username:nil password:nil wpLoginURL:nil];
}

- (void)openURL:(NSURL *)url username:(NSString *)username password:(NSString *)password wpLoginURL:(NSURL *)wpLoginURL
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    webViewController.url = url;
    webViewController.username = username;
    webViewController.password = password;
    webViewController.wpLoginURL = wpLoginURL;

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

- (void)dismissBrowser
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self checkForJetpack];
    }];
}

- (void)updateMessage
{
    if (self.blog.hasJetpack) {
        self.descriptionLabel.text = NSLocalizedString(@"Looks like you have Jetpack set up on your site. Congrats!\nSign in with your WordPress.com credentials below to enable Stats and Notifications.", @"");
    } else {
        self.descriptionLabel.text = NSLocalizedString(@"Jetpack 1.8.2 or later is required for stats. Do you want to install Jetpack?", @"");
    }
    [self.descriptionLabel sizeToFit];

    [self layoutControls];
}

- (void)checkForJetpack
{
    if (self.blog.hasJetpack) {
        if (!self.blog.jetpackUsername || !self.blog.jetpackPassword) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            self.usernameTextField.text = defaultAccount.username;
            self.passwordTextField.text = defaultAccount.password;
            [self updateSaveButton];
        }
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncOptionsForBlog:self.blog success:^{
        if (self.blog.hasJetpack) {
            [self updateMessage];
        }
    } failure:^(NSError *error) {
        [WPError showNetworkingAlertWithError:error];
    }];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL isusernameTextField = [touch.view isDescendantOfView:self.usernameTextField];
    BOOL isSigninButton = [touch.view isDescendantOfView:self.signInButton];
    
    if (isusernameTextField || isSigninButton) {
        return NO;
    }
    
    return YES;
}

@end
