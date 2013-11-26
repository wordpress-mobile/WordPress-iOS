//
//  CreateAccountAndBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogViewController.h"
#import <EmailChecker/EmailChecker.h>
#import <QuartzCore/QuartzCore.h>
#import "SupportViewController.h"
#import "WordPressComApi.h"
#import "UIView+FormSheetHelpers.h"
#import "WPNUXBackButton.h"
#import "WPNUXMainButton.h"
#import "WPWalkthroughTextField.h"
#import "WPAsyncBlockOperation.h"
#import "WPComLanguages.h"
#import "WPWalkthroughOverlayView.h"
#import "SelectWPComLanguageViewController.h"
#import "WPNUXUtility.h"
#import "WPWebViewController.h"
#import "WPStyleGuide.h"
#import "UILabel+SuggestSize.h"

@interface CreateAccountAndBlogViewController ()<
    UITextFieldDelegate,
    UIGestureRecognizerDelegate> {
    
    // Page 1
    WPNUXBackButton *_cancelButton;
    UIButton *_helpButton;
    UILabel *_titleLabel;
    UILabel *_TOSLabel;
    UILabel *_siteAddressWPComLabel;
    WPWalkthroughTextField *_emailField;
    WPWalkthroughTextField *_usernameField;
    WPWalkthroughTextField *_passwordField;
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
}

@end

@implementation CreateAccountAndBlogViewController

CGFloat const CreateAccountAndBlogStandardOffset = 16.0;
CGFloat const CreateAccountAndBlogIconVerticalOffset = 70.0;
CGFloat const CreateAccountAndBlogMaxTextWidth = 260.0;
CGFloat const CreateAccountAndBlogTextFieldWidth = 320.0;
CGFloat const CreateAccountAndBlogTextFieldHeight = 44.0;
CGFloat const CreateAccountAndBlogKeyboardOffset = 132.0;
CGFloat const CreateAccountAndBlogiOS7StatusBarOffset = 20.0;
CGFloat const CreateAccountAndBlogButtonWidth = 289.0;
CGFloat const CreateAccountAndBlogButtonHeight = 41.0;

- (id)init
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
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountOpened];
    
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
        
    [self initializeView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
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

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
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
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewWasTapped:)];
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
        [_helpButton setImage:helpButtonImage forState:UIControlStateNormal];
        _helpButton.frame = CGRectMake(0, 0, helpButtonImage.size.width, helpButtonImage.size.height);
        [_helpButton addTarget:self action:@selector(helpButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_helpButton];
    }
    
    // Add Cancel Button
    if (_cancelButton == nil) {
        _cancelButton = [[WPNUXBackButton alloc] init];
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton sizeToFit];
        [self.view addSubview:_cancelButton];
    }
    
    // Add Title
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.attributedText = [WPNUXUtility titleAttributedString:NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title")];
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = [UIColor clearColor];
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
        [self.view addSubview:_usernameField];
    }
    
    // Add Password
    if (_passwordField == nil) {
        _passwordField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _passwordField.secureTextEntry = YES;
        _passwordField.backgroundColor = [UIColor whiteColor];
        _passwordField.placeholder = NSLocalizedString(@"Password", nil);
        _passwordField.font = [WPNUXUtility textFieldFont];
        _passwordField.adjustsFontSizeToFitWidth = YES;
        _passwordField.delegate = self;
        _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
        _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _passwordField.showTopLineSeparator = YES;
        [self.view addSubview:_passwordField];
    }
    
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
        _siteAddressField.showTopLineSeparator = YES;
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
        _TOSLabel = [[UILabel alloc] init];
        _TOSLabel.userInteractionEnabled = YES;
        _TOSLabel.textAlignment = NSTextAlignmentCenter;
        _TOSLabel.text = NSLocalizedString(@"By creating an account you agree to the fascinating terms of service.", @"NUX Create Account TOS Label");
        _TOSLabel.numberOfLines = 0;
        _TOSLabel.backgroundColor = [UIColor clearColor];
        _TOSLabel.font = [WPNUXUtility tosLabelFont];
        _TOSLabel.textColor = [WPNUXUtility tosLabelColor];
        [self.view addSubview:_TOSLabel];
        
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(TOSLabelWasTapped)];
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
        [self.view addSubview:_createAccountButton];
    }
}

- (void)layoutControls
{
    CGFloat x,y;
    
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    // Layout Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    x = viewWidth - helpButtonImage.size.width - CreateAccountAndBlogStandardOffset;
    y = 0.5 * CreateAccountAndBlogStandardOffset + CreateAccountAndBlogiOS7StatusBarOffset;
    _helpButton.frame = CGRectMake(x, y, helpButtonImage.size.width, helpButtonImage.size.height);
    
    // Layout Cancel Button
    x = 0;
    y = 0.5 * CreateAccountAndBlogStandardOffset + CreateAccountAndBlogiOS7StatusBarOffset;
    _cancelButton.frame = CGRectMake(x, y, CGRectGetWidth(_cancelButton.frame), CGRectGetHeight(_cancelButton.frame));
        
    // Layout the controls starting out from y of 0, then offset them once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.
    
    // Layout Title
    CGSize titleSize = [_titleLabel suggestedSizeForWidth:CreateAccountAndBlogMaxTextWidth];
    x = (viewWidth - titleSize.width)/2.0;
    y = 0;
    _titleLabel.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Email
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_titleLabel.frame) + CreateAccountAndBlogStandardOffset;
    _emailField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Username
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_emailField.frame) - 1;
    _usernameField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Password
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_usernameField.frame) - 1;
    _passwordField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout Site Address
    x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_passwordField.frame) - 1;
    _siteAddressField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout WordPressCom Label
    [_siteAddressWPComLabel sizeToFit];
    CGSize wordPressComLabelSize = _siteAddressWPComLabel.frame.size;
    wordPressComLabelSize.height = _siteAddressField.frame.size.height - 10;
    wordPressComLabelSize.width += 10;
    _siteAddressWPComLabel.frame = CGRectMake(_siteAddressField.frame.size.width - wordPressComLabelSize.width - 5, (_siteAddressField.frame.size.height - wordPressComLabelSize.height) / 2 - 1, wordPressComLabelSize.width, wordPressComLabelSize.height);
    
    // Layout Create Account Button
    x = (viewWidth - CreateAccountAndBlogButtonWidth)/2.0;
    y = CGRectGetMaxY(_siteAddressField.frame) + CreateAccountAndBlogStandardOffset;
    _createAccountButton.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogButtonWidth, CreateAccountAndBlogButtonHeight));

    // Layout Terms of Service
    CGFloat TOSSingleLineHeight = [@"WordPress" sizeWithAttributes:@{NSFontAttributeName:_TOSLabel.font}].height;
    CGSize TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _TOSLabel.font} context:nil].size;
    // If the terms of service don't fit on two lines, then shrink the font to make sure the entire terms of service is visible.
    if (TOSLabelSize.height > 2*TOSSingleLineHeight) {
        _TOSLabel.font = [WPNUXUtility tosLabelSmallerFont];
        TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: _TOSLabel.font} context:nil].size;
    }
    x = (viewWidth - TOSLabelSize.width)/2.0;
    y = CGRectGetMaxY(_createAccountButton.frame) + 0.5 * CreateAccountAndBlogStandardOffset;
    _TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));
    
    NSArray *controls = @[_titleLabel, _emailField, _usernameField, _passwordField, _TOSLabel, _createAccountButton, _siteAddressField];
    [WPNUXUtility centerViews:controls withStartingView:_titleLabel andEndingView:_TOSLabel forHeight:viewHeight];
}


- (void)helpButtonAction
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedHelp];
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:supportViewController];
    nc.navigationBar.translucent = NO;
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}

- (void)cancelButtonAction
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedCancel];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWasTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

- (void)createAccountButtonAction
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedAccountPageNext];
    
    [self.view endEditing:YES];
    
    if (![self fieldsValid]) {
        [self showAllErrors];
        return;
    } else {
        // Check if user changed default URL and if so track the stat for it.
        if (![_siteAddressField.text isEqualToString:_defaultSiteUrl]) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountChangedDefaultURL];
        }
        
        [self createUserAndSite];
    }
}

- (void)TOSLabelWasTapped
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:@"http://en.wordpress.com/tos/"]];
    [self.navigationController pushViewController:webViewController animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    
    _keyboardOffset = (CGRectGetMaxY(_createAccountButton.frame) - CGRectGetMinY(keyboardFrame)) + 0.5 * CreateAccountAndBlogStandardOffset;
    
    // make sure keyboard offset is greater than 0, otherwise do not move controls
    if (_keyboardOffset < 0) {
        _keyboardOffset = 0;
        return;
    }

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
            CGRect frame = control.frame;
            frame.origin.y -= _keyboardOffset;
            control.frame = frame;
        }
        
        for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition]) {
            control.alpha = 0.0;
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
            CGRect frame = control.frame;
            frame.origin.y += _keyboardOffset;
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
    return @[_titleLabel, _helpButton, _cancelButton, _TOSLabel];
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
    return [self fieldsFilled] && [self isUsernameUnderFiftyCharacters];
}

- (NSString *)generateSiteTitleFromUsername:(NSString *)username {
    
    // Currently, we set the title of a new site to the username of the account.
    // Another possibility would be to name the site "username's blog", which is
    // why this has been placed in a separate method.
    return username;
}

- (void)showAllErrors
{
    if (![self isUsernameUnderFiftyCharacters]) {
        [self showError:NSLocalizedString(@"Username must be less than fifty characters.", nil)];
    } else {
        [self showFieldsNotFilledError];
    }
}

- (void)showFieldsNotFilledError
{
    [self showError:NSLocalizedString(@"Please fill out all the fields", nil)];
}

- (NSString *)getSiteAddressWithoutWordPressDotCom
{
    NSRegularExpression *dotCom = [NSRegularExpression regularExpressionWithPattern:@"\\.wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    return [dotCom stringByReplacingMatchesInString:_siteAddressField.text options:0 range:NSMakeRange(0, [_siteAddressField.text length]) withTemplate:@""];
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
        void (^blogValidationSuccess)(id) = ^(id responseObject) {
            [operation didSucceed];
        };
        void (^blogValidationFailure)(NSError *) = ^(NSError *error) {
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };
        
        NSNumber *languageId = [_currentLanguage objectForKey:@"lang_id"];
        [[WordPressComApi sharedApi] validateWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                                                 andBlogTitle:[self generateSiteTitleFromUsername:_usernameField.text]
                                                andLanguageId:languageId
                                                      success:blogValidationSuccess
                                                      failure:blogValidationFailure];
    }];
    
    WPAsyncBlockOperation *userCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createUserSuccess)(id) = ^(id responseObject){
            [operation didSucceed];
        };
        void (^createUserFailure)(NSError *) = ^(NSError *error) {
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] createWPComAccountWithEmail:_emailField.text
                                                     andUsername:_usernameField.text
                                                     andPassword:_passwordField.text
                                                         success:createUserSuccess
                                                         failure:createUserFailure];
        
    }];
    WPAsyncBlockOperation *userSignIn = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^signInSuccess)(void) = ^{
            [operation didSucceed];
        };
        void (^signInFailure)(NSError *) = ^(NSError *error) {
            // We've hit a strange failure at this point, the user has been created successfully but for some reason
            // we are unable to sign in and proceed
            [operation didFail];
            [self setAuthenticating:NO];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] signInWithUsername:_usernameField.text
                                               password:_passwordField.text
                                                success:signInSuccess
                                                failure:signInFailure];
    }];
    
    WPAsyncBlockOperation *blogCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createBlogSuccess)(id) = ^(id responseObject){
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountCreatedAccount];
            [operation didSucceed];
            [self setAuthenticating:NO];
            if (self.onCreatedUser) {
                self.onCreatedUser(_usernameField.text, _passwordField.text);
            }
        };
        void (^createBlogFailure)(NSError *error) = ^(NSError *error) {
            [self setAuthenticating:NO];
            [operation didFail];
            [self displayRemoteError:error];
        };
        
        NSNumber *languageId = [_currentLanguage objectForKey:@"lang_id"];
        [[WordPressComApi sharedApi] createWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                                               andBlogTitle:[self generateSiteTitleFromUsername:_usernameField.text]
                                              andLanguageId:languageId
                                          andBlogVisibility:WordPressComApiBlogVisibilityPublic
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

@end
