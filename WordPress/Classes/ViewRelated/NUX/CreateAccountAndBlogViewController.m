#import "CreateAccountAndBlogViewController.h"
#import <EmailChecker/EmailChecker.h>
#import <QuartzCore/QuartzCore.h>
#import "SupportViewController.h"
#import "WordPressComApi.h"
#import "WPNUXBackButton.h"
#import "WPNUXMainButton.h"
#import "WPPostViewController.h"
#import "WPWalkthroughTextField.h"
#import "WPAsyncBlockOperation.h"
#import "WPComLanguages.h"
#import "WPWalkthroughOverlayView.h"
#import "SelectWPComLanguageViewController.h"
#import "WPNUXUtility.h"
#import "WPWebViewController.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "UILabel+SuggestSize.h"
#import "WPAccount.h"
#import "Blog.h"
#import "WordPressComOAuthClient.h"
#import "WordPressComServiceRemote.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "NSString+XMLExtensions.h"
#import "Constants.h"

#import "WordPress-Swift.h"

#import <OnePasswordExtension/OnePasswordExtension.h>


@interface CreateAccountAndBlogViewController ()<UITextFieldDelegate,UIGestureRecognizerDelegate> {
    // Page 1
    WPNUXBackButton *_backButton;
    UIButton *_helpButton;
    UILabel *_titleLabel;
    UILabel *_TOSLabel;
    UILabel *_siteAddressWPComLabel;
    WPWalkthroughTextField *_emailField;
    WPWalkthroughTextField *_usernameField;
    WPWalkthroughTextField *_passwordField;
    UIButton *_onePasswordButton;
    WPNUXMainButton *_createAccountButton;
    WPWalkthroughTextField *_siteAddressField;

    NSOperationQueue *_operationQueue;

    BOOL _authenticating;
    BOOL _keyboardVisible;
    BOOL _shouldCorrectEmail;
    BOOL _userDefinedSiteAddress;
    CGFloat _keyboardOffset;
    NSString *_defaultSiteUrl;

    NSDictionary *_currentLanguage;

    WPAccount *_account;
}

@end

@implementation CreateAccountAndBlogViewController

static CGFloat const CreateAccountAndBlogStandardOffset             = 15.0;
static CGFloat const CreateAccountAndBlogMaxTextWidth               = 260.0;
static CGFloat const CreateAccountAndBlogTextFieldWidth             = 320.0;
static CGFloat const CreateAccountAndBlogTextFieldHeight            = 44.0;
static CGFloat const CreateAccountAndBlogTextFieldPhoneHeight       = 38.0;
static CGFloat const CreateAccountAndBlogiOS7StatusBarOffset        = 20.0;
static CGFloat const CreateAccountAndBlogButtonWidth                = 290.0;
static CGFloat const CreateAccountAndBlogButtonHeight               = 41.0;
static UIOffset const CreateAccountAndBlogOnePasswordPadding        = {9.0, 0.0};

static UIEdgeInsets const CreateAccountAndBlogBackButtonPadding     = {1.0, 0.0, 0.0, 0.0};
static UIEdgeInsets const CreateAccountAndBlogBackButtonPaddingPad  = {1.0, 13.0, 0.0, 0.0};

static UIEdgeInsets const CreateAccountAndBlogHelpButtonPadding     = {1.0, 0.0, 0.0, 13.0};
static UIEdgeInsets const CreateAccountAndBlogHelpButtonPaddingPad  = {1.0, 0.0, 0.0, 20.0};

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldCorrectEmail = YES;
        _operationQueue = [[NSOperationQueue alloc] init];
        _currentLanguage = [WPComLanguages currentLanguage];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [WPStyleGuide wordPressBlue];

    [self initializeView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self layoutControls];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskPortrait;
    }

    return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    [self layoutControls];
}

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _emailField) {
        [_usernameField becomeFirstResponder];
    } else if (textField == _usernameField) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        [_siteAddressField becomeFirstResponder];
    } else if (textField == _siteAddressField) {
        if (_createAccountButton.enabled) {
            [self createAccountButtonAction];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
                                                       replacementString:(NSString *)string
{
    if ([string isEqualToString:@" "] && ![textField isEqual:_passwordField]) { // Disallow spaces in every field except password
        return NO;
    }
    
    NSArray *fields = @[_emailField, _usernameField, _passwordField, _siteAddressField];

    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];

    if ([fields containsObject:textField]) {
        [self updateCreateAccountButtonForTextfield:textField andUpdatedString:updatedString];
    }

    if ([textField isEqual:_siteAddressField]) {
        _userDefinedSiteAddress = YES;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:_usernameField]) {
        if ([[_siteAddressField.text trim] length] == 0 || !_userDefinedSiteAddress) {
            _siteAddressField.text = _defaultSiteUrl = _usernameField.text;
            _userDefinedSiteAddress = NO;
            [self updateCreateAccountButtonForTextfield:_siteAddressField andUpdatedString:_siteAddressField.text];
        }
    }
}

- (void)updateCreateAccountButtonForTextfield:(UITextField *)textField andUpdatedString:(NSString *)updatedString
{
    BOOL isEmailFilled = [self isEmailedFilled];
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    BOOL isSiteAddressFilled = [self isSiteAddressFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;

    if (textField == _emailField) {
        isEmailFilled = updatedStringHasContent;
    } else if (textField == _usernameField) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _passwordField) {
        isPasswordFilled = updatedStringHasContent;
    } else if (textField == _siteAddressField) {
        isSiteAddressFilled = updatedStringHasContent;
    }

    _createAccountButton.enabled = isEmailFilled && isUsernameFilled && isPasswordFilled && isSiteAddressFilled;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _createAccountButton.enabled = [self fieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == _emailField) {
        // check email validity
        NSString *suggestedEmail = [EmailChecker suggestDomainCorrection: _emailField.text];
        if (![suggestedEmail isEqualToString:_emailField.text] && _shouldCorrectEmail) {
            textField.text = suggestedEmail;
            _shouldCorrectEmail = NO;
        }
    }
    _createAccountButton.enabled = [self fieldsFilled];
    return YES;
}

#pragma mark - Private Methods

- (void)initializeView
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(viewWasTapped:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:gestureRecognizer];

    [self addControls];
    [self layoutControls];
}

- (void)addControls
{
    // Add Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    if (_helpButton == nil) {
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _helpButton.accessibilityLabel = NSLocalizedString(@"Help", @"Help button");
        [_helpButton setImage:helpButtonImage forState:UIControlStateNormal];
        _helpButton.frame = CGRectMake(0, 0, helpButtonImage.size.width, helpButtonImage.size.height);
        [_helpButton addTarget:self action:@selector(helpButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _helpButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self.view addSubview:_helpButton];
    }

    // Add Cancel Button
    if (_backButton == nil) {
        _backButton = [[WPNUXBackButton alloc] init];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_backButton sizeToFit];
        _backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.view addSubview:_backButton];
    }

    // Add Title
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title")
                                                                     attributes:[WPNUXUtility titleAttributesWithColor:[UIColor whiteColor]]];
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self.view addSubview:_titleLabel];
    }

    // Add Email
    if (_emailField == nil) {
        _emailField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-email-field"]];
        _emailField.backgroundColor = [UIColor whiteColor];
        _emailField.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
        _emailField.font = [WPNUXUtility textFieldFont];
        _emailField.adjustsFontSizeToFitWidth = YES;
        _emailField.delegate = self;
        _emailField.autocorrectionType = UITextAutocorrectionTypeNo;
        _emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _emailField.keyboardType = UIKeyboardTypeEmailAddress;
        _emailField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _emailField.accessibilityIdentifier = @"Email Address";
        _emailField.returnKeyType = UIReturnKeyNext;
        [self.view addSubview:_emailField];
    }

    // Add Username
    if (_usernameField == nil) {
        _usernameField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
        _usernameField.backgroundColor = [UIColor whiteColor];
        _usernameField.placeholder = NSLocalizedString(@"Username", nil);
        _usernameField.font = [WPNUXUtility textFieldFont];
        _usernameField.adjustsFontSizeToFitWidth = YES;
        _usernameField.delegate = self;
        _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _usernameField.showTopLineSeparator = YES;
        _usernameField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _usernameField.accessibilityIdentifier = @"Username";
        _usernameField.returnKeyType = UIReturnKeyNext;
        [self.view addSubview:_usernameField];
    }

    // Add Password
    if (_passwordField == nil) {
        _passwordField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _passwordField.secureTextEntry = YES;
        _passwordField.showSecureTextEntryToggle = YES;
        _passwordField.backgroundColor = [UIColor whiteColor];
        _passwordField.placeholder = NSLocalizedString(@"Password", nil);
        _passwordField.font = [WPNUXUtility textFieldFont];
        _passwordField.adjustsFontSizeToFitWidth = YES;
        _passwordField.delegate = self;
        _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
        _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _passwordField.showTopLineSeparator = YES;
        _passwordField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _passwordField.accessibilityIdentifier = @"Password";
        _passwordField.returnKeyType = UIReturnKeyNext;
        [self.view addSubview:_passwordField];
    }
    
    // Add OnePassword
    if (_onePasswordButton == nil) {
        _onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_onePasswordButton setImage:[UIImage imageNamed:@"onepassword-wp-button"] forState:UIControlStateNormal];
        [_onePasswordButton addTarget:self action:@selector(saveLoginToOnePassword:) forControlEvents:UIControlEventTouchUpInside];
        [_onePasswordButton sizeToFit];
    
        _passwordField.rightView = _onePasswordButton;
        _passwordField.rightViewPadding = CreateAccountAndBlogOnePasswordPadding;
    }
    
    BOOL isOnePasswordAvailable = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    _passwordField.rightViewMode = isOnePasswordAvailable ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
    _passwordField.showSecureTextEntryToggle = !isOnePasswordAvailable;
    
    // Add Site Address
    if (_siteAddressField == nil) {
        _siteAddressField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
        _siteAddressField.backgroundColor = [UIColor whiteColor];
        _siteAddressField.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
        _siteAddressField.font = [WPNUXUtility textFieldFont];
        _siteAddressField.adjustsFontSizeToFitWidth = YES;
        _siteAddressField.delegate = self;
        _siteAddressField.autocorrectionType = UITextAutocorrectionTypeNo;
        _siteAddressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _siteAddressField.returnKeyType = UIReturnKeyDone;
        _siteAddressField.showTopLineSeparator = YES;
        _siteAddressField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _siteAddressField.accessibilityIdentifier = @"Site Address (URL)";
        [self.view addSubview:_siteAddressField];

        // add .wordpress.com label to textfield
        _siteAddressWPComLabel = [[UILabel alloc] init];
        _siteAddressWPComLabel.text = @".wordpress.com";
        _siteAddressWPComLabel.textAlignment = NSTextAlignmentCenter;
        _siteAddressWPComLabel.font = [WPNUXUtility descriptionTextFont];
        _siteAddressWPComLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [_siteAddressWPComLabel sizeToFit];

        UIEdgeInsets siteAddressTextInsets = [(WPWalkthroughTextField *)_siteAddressField textInsets];
        siteAddressTextInsets.right += _siteAddressWPComLabel.frame.size.width + 10;
        [(WPWalkthroughTextField *)_siteAddressField setTextInsets:siteAddressTextInsets];
        [_siteAddressField addSubview:_siteAddressWPComLabel];
    }

    // Add Terms of Service Label
    if (_TOSLabel == nil) {
        
        // Build the string in two parts so the coloring of "Terms of Service." doesn't break when it gets translated
        NSString *plainTosText = NSLocalizedString(@"By creating an account you agree to the fascinating Terms of Service.", @"NUX Create Account TOS Label");
        NSString *tosFindText = NSLocalizedString(@"Terms of Service", @"'Terms of Service' should be the same text that is in 'NUX Create Account TOS Label'");
        
        NSMutableAttributedString *tosText = [[NSMutableAttributedString alloc] initWithString:plainTosText];
        [tosText addAttribute:NSForegroundColorAttributeName
                        value:[WPNUXUtility tosLabelColor]
                        range:NSMakeRange(0, [tosText length])];

        if ([plainTosText rangeOfString:tosFindText options:NSCaseInsensitiveSearch].location != NSNotFound ) {
            [tosText addAttribute:NSForegroundColorAttributeName
                            value:[UIColor whiteColor]
                            range:[plainTosText rangeOfString:tosFindText options:NSCaseInsensitiveSearch]];
        }

        _TOSLabel = [[UILabel alloc] init];
        _TOSLabel.userInteractionEnabled = YES;
        _TOSLabel.textAlignment = NSTextAlignmentCenter;
        _TOSLabel.attributedText = tosText;
        _TOSLabel.numberOfLines = 0;
        _TOSLabel.backgroundColor = [UIColor clearColor];
        _TOSLabel.font = [WPNUXUtility tosLabelFont];
        _TOSLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self.view addSubview:_TOSLabel];

        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(TOSLabelWasTapped)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_TOSLabel addGestureRecognizer:gestureRecognizer];
    }

    // Add Next Button
    if (_createAccountButton == nil) {
        _createAccountButton = [[WPNUXMainButton alloc] init];
        [_createAccountButton setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
        _createAccountButton.enabled = NO;
        [_createAccountButton addTarget:self action:@selector(createAccountButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_createAccountButton sizeToFit];
        _createAccountButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self.view addSubview:_createAccountButton];
    }
}

- (void)layoutControls
{
    CGFloat x,y;

    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    
    UIEdgeInsets helpButtonPadding = [UIDevice isPad] ? CreateAccountAndBlogHelpButtonPaddingPad : CreateAccountAndBlogHelpButtonPadding;
    UIEdgeInsets backButtonPadding = [UIDevice isPad] ? CreateAccountAndBlogBackButtonPaddingPad : CreateAccountAndBlogBackButtonPadding;
    
    // Layout Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    x = viewWidth - helpButtonImage.size.width - helpButtonPadding.right;
    y = CreateAccountAndBlogiOS7StatusBarOffset + helpButtonPadding.top;
    _helpButton.frame = CGRectMake(x, y, helpButtonImage.size.width, CreateAccountAndBlogButtonHeight);

    // Layout Cancel Button
    x = backButtonPadding.left;
    y = CreateAccountAndBlogiOS7StatusBarOffset + backButtonPadding.top;
    _backButton.frame = CGRectMake(x, y, CGRectGetWidth(_backButton.frame), CreateAccountAndBlogButtonHeight);

    // Layout the controls starting out from y of 0, then offset them once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.

    // Layout Title
    CGSize titleSize = [_titleLabel suggestedSizeForWidth:CreateAccountAndBlogMaxTextWidth];
    x = (viewWidth - titleSize.width)/2.0;
    y = 0;
    _titleLabel.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));

    // In order to fit controls ontol all phones, the textField height is smaller on iPhones
    // versus iPads.
    CGFloat textFieldHeight = IS_IPAD ? CreateAccountAndBlogTextFieldHeight: CreateAccountAndBlogTextFieldPhoneHeight;

    // Layout Email
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_titleLabel.frame) + CreateAccountAndBlogStandardOffset;
    _emailField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));

    // Layout Username
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_emailField.frame) - 1;
    _usernameField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));

    // Layout Password
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameField.frame) - 1;
    _passwordField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));

    // Layout Site Address
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_passwordField.frame) - 1;
    _siteAddressField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));

    // Layout WordPressCom Label
    [_siteAddressWPComLabel sizeToFit];
    CGSize wordPressComLabelSize = _siteAddressWPComLabel.frame.size;
    wordPressComLabelSize.height = _siteAddressField.frame.size.height - 10;
    wordPressComLabelSize.width += 10;
    _siteAddressWPComLabel.frame = CGRectMake(_siteAddressField.frame.size.width - wordPressComLabelSize.width - 5,
                                              (_siteAddressField.frame.size.height - wordPressComLabelSize.height) / 2 - 1,
                                              wordPressComLabelSize.width,
                                              wordPressComLabelSize.height);

    // Layout Create Account Button
    x = (viewWidth - CreateAccountAndBlogButtonWidth)/2.0;
    y = CGRectGetMaxY(_siteAddressField.frame) + CreateAccountAndBlogStandardOffset;
    _createAccountButton.frame = CGRectIntegral(CGRectMake(x,
                                                           y,
                                                           CreateAccountAndBlogButtonWidth,
                                                           CreateAccountAndBlogButtonHeight));

    // Layout Terms of Service
    CGFloat TOSSingleLineHeight = [@"WordPress" sizeWithAttributes:@{NSFontAttributeName:_TOSLabel.font}].height;
    CGSize TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName: _TOSLabel.font}
                                                       context:nil].size;
    // If the terms of service don't fit on two lines, then shrink the font to make sure
    // the entire terms of service is visible.
    if (TOSLabelSize.height > 2*TOSSingleLineHeight) {
        _TOSLabel.font = [WPNUXUtility tosLabelSmallerFont];
        TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName: _TOSLabel.font} context:nil].size;
    }
    x = (viewWidth - TOSLabelSize.width)/2.0;
    y = CGRectGetMaxY(_createAccountButton.frame) + 0.5 * CreateAccountAndBlogStandardOffset;
    _TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));

    NSArray *controls = @[_titleLabel, _emailField, _usernameField, _passwordField,
                          _TOSLabel, _createAccountButton, _siteAddressField];
    [WPNUXUtility centerViews:controls withStartingView:_titleLabel andEndingView:_TOSLabel forHeight:viewHeight];
}

- (IBAction)helpButtonAction
{
    SupportViewController *supportVC = [[SupportViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:supportVC];
    nc.navigationBar.translucent = NO;
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

- (IBAction)backButtonAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)viewWasTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

- (IBAction)saveLoginToOnePassword:(id)sender
{
    // Dismiss the keyboard right away
    [self.view endEditing:YES];
    
    // Hit 1Password!
    NSDictionary *newLoginDetails = @{
        AppExtensionTitleKey        : WPOnePasswordWordPressTitle,
        AppExtensionUsernameKey     : _usernameField.text ?: [NSString string],
        AppExtensionPasswordKey     : _passwordField.text ?: [NSString string],
    };
    
    NSDictionary *passwordGenerationOptions = @{
        AppExtensionGeneratedPasswordMinLengthKey: @(WPOnePasswordGeneratedMinLength),
        AppExtensionGeneratedPasswordMaxLengthKey: @(WPOnePasswordGeneratedMaxLength)
    };
    
    [[OnePasswordExtension sharedExtension] storeLoginForURLString:WPOnePasswordWordPressComURL
                                                      loginDetails:newLoginDetails
                                         passwordGenerationOptions:passwordGenerationOptions
                                                 forViewController:self
                                                            sender:sender
                                                        completion:^(NSDictionary *loginDict, NSError *error) {
        
        if (!loginDict) {
            if (error.code != AppExtensionErrorCodeCancelledByUser) {
                DDLogError(@"Failed to use 1Password App Extension to save a new Login: %@", error);
                [WPAnalytics track:WPAnalyticsStatOnePasswordFailed];
            }
            return;
        }
                                                            
        _usernameField.text = loginDict[AppExtensionUsernameKey] ?: [NSString string];
        _passwordField.text = loginDict[AppExtensionPasswordKey] ?: [NSString string];
                                                            
        [WPAnalytics track:WPAnalyticsStatOnePasswordSignup];
                 
        // Note: Since the Site field is right below the 1Password field, let's continue with the edition flow
        // and make the SiteAddress Field the first responder.
        [_siteAddressField becomeFirstResponder];
    }];
}

- (IBAction)createAccountButtonAction
{
    [self.view endEditing:YES];

    if (![self fieldsValid]) {
        [self showAllErrors];
        return;
    }

    [self createUserAndSite];
}

- (IBAction)TOSLabelWasTapped
{
    NSURL *targetURL = [NSURL URLWithString:WPAutomatticTermsOfServiceURL];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];

    CGFloat newKeyboardOffset = (CGRectGetMaxY(_createAccountButton.frame) - CGRectGetMinY(keyboardFrame)) + CreateAccountAndBlogStandardOffset;

    // make sure keyboard offset is greater than 0, otherwise do not move controls
    if (newKeyboardOffset < 0) {
        return;
    }

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
            CGRect frame = control.frame;
            frame.origin.y -= newKeyboardOffset;
            control.frame = frame;
        }

        for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition]) {
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
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
            CGRect frame = control.frame;
            frame.origin.y += currentKeyboardOffset;
            control.frame = frame;
        }

        for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition]) {
            control.alpha = 1.0;
        }
    }];
}

- (void)keyboardDidShow
{
    _keyboardVisible = YES;
}

- (void)keyboardDidHide
{
    _keyboardVisible = NO;
}

- (NSArray *)controlsToMoveDuringKeyboardTransition
{
    return @[_usernameField, _emailField, _passwordField, _createAccountButton, _siteAddressField];
}

- (NSArray *)controlsToShowOrHideDuringKeyboardTransition
{
    return @[_titleLabel, _helpButton, _backButton, _TOSLabel];
}

- (void)displayRemoteError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    [self showError:errorMessage];
}

- (BOOL)fieldsFilled
{
    return [self isEmailedFilled] && [self isUsernameFilled] && [self isPasswordFilled] && [self isSiteAddressFilled];
}

- (BOOL)isEmailedFilled
{
    return ([[_emailField.text trim] length] != 0);
}

- (BOOL)isUsernameFilled
{
    return ([[_usernameField.text trim] length] != 0);
}

- (BOOL)isUsernameUnderFiftyCharacters
{
    return [[_usernameField.text trim] length] <= 50;
}

- (BOOL)isPasswordFilled
{
    return ([[_passwordField.text trim] length] != 0);
}

- (BOOL)isSiteAddressFilled
{
    return ([[_siteAddressField.text trim] length] != 0);
}

- (BOOL)fieldsValid
{
    return [self fieldsFilled] && [self isUsernameUnderFiftyCharacters] && ![self emailOrUsernameOrSiteAddressContainsSpaces];
}

- (NSString *)generateSiteTitleFromUsername:(NSString *)username
{
    // Currently, we set the title of a new site to the username of the account.
    // Another possibility would be to name the site "username's blog", which is
    // why this has been placed in a separate method.
    return username;
}

- (void)showAllErrors
{
    if (![self isUsernameUnderFiftyCharacters]) {
        [self showError:NSLocalizedString(@"Username must be less than fifty characters.", nil)];
    } else if ([self emailOrUsernameOrSiteAddressContainsSpaces]) {
        [self showError:NSLocalizedString(@"Email, Username, and Site Address cannot contain spaces", @"No spaces error message")];
    } else {
        [self showFieldsNotFilledError];
    }
}

- (BOOL)emailOrUsernameOrSiteAddressContainsSpaces {
    NSString *space = @" ";
    NSString *emailTrimmed = [_emailField.text trim];
    NSString *userNameTrimmed = [_usernameField.text trim];
    NSString *siteAddressTrimmed = [_siteAddressField.text trim];
    
    return ([emailTrimmed containsString:space] || [userNameTrimmed containsString:space] || [siteAddressTrimmed containsString:space]);
}

- (void)showFieldsNotFilledError
{
    [self showError:NSLocalizedString(@"Please fill out all the fields", nil)];
}

- (NSString *)getSiteAddressWithoutWordPressDotCom
{
    NSRegularExpression *dotCom = [NSRegularExpression regularExpressionWithPattern:@"\\.wordpress\\.com/?$"
                                                                            options:NSRegularExpressionCaseInsensitive error:nil];
    return [dotCom stringByReplacingMatchesInString:_siteAddressField.text options:0
                                              range:NSMakeRange(0, [_siteAddressField.text length]) withTemplate:@""];
}

- (void)showError:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayTitle = NSLocalizedString(@"Error", nil);
    overlayView.overlayDescription = message;
    overlayView.dismissCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)setAuthenticating:(BOOL)authenticating
{
    _authenticating = authenticating;
    _createAccountButton.enabled = !authenticating;
    _onePasswordButton.enabled = !authenticating;
    [_createAccountButton showActivityIndicator:authenticating];
}

- (void)createUserAndSite
{
    if (_authenticating) {
        return;
    }

    [self setAuthenticating:YES];

    // The site must be validated prior to making an account. Without validation,
    // the situation could exist where a user account is created, but the site creation
    // fails.
    WPAsyncBlockOperation *siteValidation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation) {
        WordPressComServiceSuccessBlock blogValidationSuccess = ^(NSDictionary *responseDictionary) {
            [operation didSucceed];
        };
        WordPressComServiceFailureBlock blogValidationFailure = ^(NSError *error) {
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };

        NSString *languageId = [_currentLanguage stringForKey:@"lang_id"];
        
        WordPressComApi *api = [WordPressComApi anonymousApi];
        WordPressComServiceRemote *service = [[WordPressComServiceRemote alloc] initWithApi:api];
        
        [service validateWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                             andBlogTitle:[self generateSiteTitleFromUsername:_usernameField.text]
                            andLanguageId:languageId
                                  success:blogValidationSuccess
                                  failure:blogValidationFailure];
    }];

    WPAsyncBlockOperation *userCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        WordPressComServiceSuccessBlock createUserSuccess = ^(NSDictionary *responseDictionary){
            [operation didSucceed];
        };
        
        WordPressComServiceFailureBlock createUserFailure = ^(NSError *error) {
            DDLogError(@"Failed creating user: %@", error);
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };
        
        WordPressComApi *api = [WordPressComApi anonymousApi];
        WordPressComServiceRemote *service = [[WordPressComServiceRemote alloc] initWithApi:api];
        
        [service createWPComAccountWithEmail:_emailField.text
                                 andUsername:_usernameField.text
                                 andPassword:_passwordField.text
                                     success:createUserSuccess
                                     failure:createUserFailure];

    }];
    WPAsyncBlockOperation *userSignIn = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^signInSuccess)(NSString *authToken) = ^(NSString *authToken) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

            _account = [accountService createOrUpdateAccountWithUsername:_usernameField.text authToken:authToken];
            _account.email = _emailField.text;
            if (![accountService defaultWordPressComAccount]) {
                [accountService setDefaultWordPressComAccount:_account];
            }
            [operation didSucceed];
        };
        void (^signInFailure)(NSError *) = ^(NSError *error) {
            DDLogError(@"Failed signing in user: %@", error);
            // We've hit a strange failure at this point, the user has been created successfully but for some reason
            // we are unable to sign in and proceed
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };

        WordPressComOAuthClient *client = [WordPressComOAuthClient client];
        [client authenticateWithUsername:_usernameField.text
                                password:_passwordField.text
                         multifactorCode:nil
                                 success:signInSuccess
                                 failure:signInFailure];
    }];

    WPAsyncBlockOperation *blogCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        WordPressComServiceSuccessBlock createBlogSuccess = ^(NSDictionary *responseDictionary){
            [WPAnalytics track:WPAnalyticsStatCreatedAccount];
            [operation didSucceed];

            NSMutableDictionary *blogOptions = [[responseDictionary dictionaryForKey:@"blog_details"] mutableCopy];
            if ([blogOptions objectForKey:@"blogname"]) {
                [blogOptions setObject:[blogOptions objectForKey:@"blogname"] forKey:@"blogName"];
                [blogOptions removeObjectForKey:@"blogname"];
            }

            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
            WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

            Blog *blog = [blogService findBlogWithXmlrpc:blogOptions[@"xmlrpc"] inAccount:defaultAccount];
            if (!blog) {
                blog = [blogService createBlogWithAccount:defaultAccount];
                blog.xmlrpc = blogOptions[@"xmlrpc"];
            }
            blog.dotComID = [blogOptions numberForKey:@"blogid"];
            blog.url = blogOptions[@"url"];
            blog.settings.name = [blogOptions[@"blogname"] stringByDecodingXMLCharacters];
            defaultAccount.defaultBlog = blog;

            [[ContextManager sharedInstance] saveContext:context];

            [accountService updateUserDetailsForAccount:defaultAccount success:nil failure:nil];
            [blogService syncBlog:blog completionHandler:nil];
            [WPAnalytics refreshMetadata];
            [self setAuthenticating:NO];
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        WordPressComServiceFailureBlock createBlogFailure = ^(NSError *error) {
            DDLogError(@"Failed creating blog: %@", error);
            [self setAuthenticating:NO];
            [operation didFail];
            [self displayRemoteError:error];
        };

        NSString *languageId = [_currentLanguage stringForKey:@"lang_id"];
        
        WordPressComApi *api = [_account restApi];
        WordPressComServiceRemote *service = [[WordPressComServiceRemote alloc] initWithApi:api];
        
        [service createWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                           andBlogTitle:[self generateSiteTitleFromUsername:_usernameField.text]
                          andLanguageId:languageId
                      andBlogVisibility:WordPressComServiceBlogVisibilityPublic
                                success:createBlogSuccess
                                failure:createBlogFailure];
    }];

    [blogCreation addDependency:userSignIn];
    [userSignIn addDependency:userCreation];
    [userCreation addDependency:siteValidation];

    [_operationQueue addOperation:siteValidation];
    [_operationQueue addOperation:userCreation];
    [_operationQueue addOperation:userSignIn];
    [_operationQueue addOperation:blogCreation];
}

#pragma mark - Status bar management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
