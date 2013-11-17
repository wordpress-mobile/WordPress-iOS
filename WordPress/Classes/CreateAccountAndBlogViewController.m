//
//  CreateAccountAndBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogViewController.h"
#import <EmailChecker/EmailChecker.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <QuartzCore/QuartzCore.h>
#import "SupportViewController.h"
#import "WordPressComApi.h"
#import "UIView+FormSheetHelpers.h"
#import "WPNUXBackButton.h"
#import "WPNUXPrimaryButton.h"
#import "WPWalkthroughTextField.h"
#import "WPAsyncBlockOperation.h"
#import "WPComLanguages.h"
#import "WPWalkthroughOverlayView.h"
#import "SelectWPComLanguageViewController.h"
#import "WPNUXUtility.h"
#import "WPWebViewController.h"
#import "WPStyleGuide.h"

@interface CreateAccountAndBlogViewController ()<
    UIScrollViewDelegate,
    UITextFieldDelegate,
    UIGestureRecognizerDelegate> {
    
    // Page 1
    WPNUXBackButton *_cancelButton;
    UIButton *_helpButton;
    UIImageView *_page1Icon;
    UILabel *_page1Title;
    UILabel *_page1TOSLabel;
    UILabel *_page2WordPressComLabel;
    WPWalkthroughTextField *_page1EmailText;
    WPWalkthroughTextField *_page1UsernameText;
    WPWalkthroughTextField *_page1PasswordText;
    WPNUXPrimaryButton *_page1NextButton;
    WPWalkthroughTextField *_page2SiteAddressText;
    
    NSOperationQueue *_operationQueue;

    BOOL _keyboardVisible;
    BOOL _shouldCorrectEmail;
    BOOL _userDefinedSiteAddress;
    CGFloat _keyboardOffset;
    NSString *_defaultSiteUrl;
        
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    NSDictionary *_currentLanguage;
}

@end

@implementation CreateAccountAndBlogViewController

CGFloat const CreateAccountAndBlogStandardOffset = 16.0;
CGFloat const CreateAccountAndBlogIconVerticalOffset = 70.0;
CGFloat const CreateAccountAndBlogMaxTextWidth = 289.0;
CGFloat const CreateAccountAndBlogTextFieldWidth = 320.0;
CGFloat const CreateAccountAndBlogTextFieldHeight = 44.0;
CGFloat const CreateAccountAndBlogKeyboardOffset = 132.0;
CGFloat const CreateAccountAndBlogiOS7StatusBarOffset = 20.0;


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
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
        
    [self addScrollview];
    [self addPage1Controls];
    [self layoutPage1Controls];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
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

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _page1EmailText) {
        [_page1UsernameText becomeFirstResponder];
    } else if (textField == _page1UsernameText) {
        [_page1PasswordText becomeFirstResponder];
    } else if (textField == _page1PasswordText) {
        [_page2SiteAddressText becomeFirstResponder];
    } else if (textField == _page2SiteAddressText) {
        if (_page1NextButton.enabled) {
            [self clickedPage1NextButton];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSArray *fields = @[_page1EmailText, _page1UsernameText, _page1PasswordText, _page2SiteAddressText];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];

    if ([fields containsObject:textField]) {
        [self updatePage1ButtonEnabledStatusFor:textField andUpdatedString:updatedString];
    }
    
    if ([textField isEqual:_page2SiteAddressText]) {
        _userDefinedSiteAddress = YES;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:_page1UsernameText]) {
        if ([[_page2SiteAddressText.text trim] length] == 0 || !_userDefinedSiteAddress) {
            _page2SiteAddressText.text = _defaultSiteUrl = _page1UsernameText.text;
            _userDefinedSiteAddress = NO;
            [self updatePage1ButtonEnabledStatusFor:_page2SiteAddressText andUpdatedString:_page2SiteAddressText.text];
        }
    }
}

- (void)updatePage1ButtonEnabledStatusFor:(UITextField *)textField andUpdatedString:(NSString *)updatedString
{
    BOOL isEmailFilled = [self isEmailedFilled];
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    BOOL isSiteAddressFilled = [self isSiteAddressFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    
    if (textField == _page1EmailText) {
        isEmailFilled = updatedStringHasContent;
    } else if (textField == _page1UsernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _page1PasswordText) {
        isPasswordFilled = updatedStringHasContent;
    } else if (textField == _page2SiteAddressText) {
        isSiteAddressFilled = updatedStringHasContent;
    }
    
    _page1NextButton.enabled = isEmailFilled && isUsernameFilled && isPasswordFilled && isSiteAddressFilled;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _page1NextButton.enabled = [self page1FieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField == _page1EmailText) {
        // check email validity
        NSString *suggestedEmail = [EmailChecker suggestDomainCorrection: _page1EmailText.text];
        if (![suggestedEmail isEqualToString:_page1EmailText.text] && _shouldCorrectEmail) {
            textField.text = suggestedEmail;
            _shouldCorrectEmail = NO;
        }
    }
    _page1NextButton.enabled = [self page1FieldsFilled];
    return YES;
}

#pragma mark - Private Methods

- (void)addScrollview
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedOnScrollView:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (void)addPage1Controls
{
    // Add Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    if (_helpButton == nil) {
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_helpButton setImage:helpButtonImage forState:UIControlStateNormal];
        _helpButton.frame = CGRectMake(0, 0, helpButtonImage.size.width, helpButtonImage.size.height);
        [_helpButton addTarget:self action:@selector(clickedHelpButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_helpButton];
    }
    
    // Add Cancel Button
    if (_cancelButton == nil) {
        _cancelButton = [[WPNUXBackButton alloc] init];
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(clickedCancelButton) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton sizeToFit];
        [self.view addSubview:_cancelButton];
    }
    
    // Add Icon
    if (_page1Icon == nil) {
        UIImage *icon = [UIImage imageNamed:@"icon-wp"];
        _page1Icon = [[UIImageView alloc] initWithImage:icon];
        [self.view addSubview:_page1Icon];
    }
    
    // Add Title
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.attributedText = [WPNUXUtility titleAttributedString:NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title")];
        _page1Title.numberOfLines = 0;
        _page1Title.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_page1Title];
    }
    
    // Add Email
    if (_page1EmailText == nil) {
        _page1EmailText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-email-field"]];
        _page1EmailText.backgroundColor = [UIColor whiteColor];
        _page1EmailText.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
        _page1EmailText.font = [WPNUXUtility textFieldFont];
        _page1EmailText.adjustsFontSizeToFitWidth = YES;
        _page1EmailText.delegate = self;
        _page1EmailText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1EmailText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page1EmailText.keyboardType = UIKeyboardTypeEmailAddress;
        [self.view addSubview:_page1EmailText];
    }
    
    // Add Username
    if (_page1UsernameText == nil) {
        _page1UsernameText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
        _page1UsernameText.backgroundColor = [UIColor whiteColor];
        _page1UsernameText.placeholder = NSLocalizedString(@"Username", nil);
        _page1UsernameText.font = [WPNUXUtility textFieldFont];
        _page1UsernameText.adjustsFontSizeToFitWidth = YES;
        _page1UsernameText.delegate = self;
        _page1UsernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1UsernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page1UsernameText.showTopLineSeparator = YES;
        [self.view addSubview:_page1UsernameText];
    }
    
    // Add Password
    if (_page1PasswordText == nil) {
        _page1PasswordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
        _page1PasswordText.secureTextEntry = YES;
        _page1PasswordText.backgroundColor = [UIColor whiteColor];
        _page1PasswordText.placeholder = NSLocalizedString(@"Password", nil);
        _page1PasswordText.font = [WPNUXUtility textFieldFont];
        _page1PasswordText.adjustsFontSizeToFitWidth = YES;
        _page1PasswordText.delegate = self;
        _page1PasswordText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1PasswordText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page1PasswordText.showTopLineSeparator = YES;
        [self.view addSubview:_page1PasswordText];
    }
    
    // Add Site Address
    if (_page2SiteAddressText == nil) {
        _page2SiteAddressText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
        _page2SiteAddressText.backgroundColor = [UIColor whiteColor];
        _page2SiteAddressText.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
        _page2SiteAddressText.font = [WPNUXUtility textFieldFont];
        _page2SiteAddressText.adjustsFontSizeToFitWidth = YES;
        _page2SiteAddressText.delegate = self;
        _page2SiteAddressText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page2SiteAddressText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page2SiteAddressText.showTopLineSeparator = YES;
        [self.view addSubview:_page2SiteAddressText];
        
        // add .wordpress.com label to textfield
        _page2WordPressComLabel = [[UILabel alloc] init];
        _page2WordPressComLabel.text = @".wordpress.com";
        _page2WordPressComLabel.textAlignment = NSTextAlignmentCenter;
        _page2WordPressComLabel.font = [WPNUXUtility descriptionTextFont];
        _page2WordPressComLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [_page2WordPressComLabel sizeToFit];
        
        UIEdgeInsets siteAddressTextInsets = [(WPWalkthroughTextField *)_page2SiteAddressText textInsets];
        siteAddressTextInsets.right += _page2WordPressComLabel.frame.size.width + 10;
        [(WPWalkthroughTextField *)_page2SiteAddressText setTextInsets:siteAddressTextInsets];
        [_page2SiteAddressText addSubview:_page2WordPressComLabel];
    }
    
    // Add Terms of Service Label
    if (_page1TOSLabel == nil) {
        _page1TOSLabel = [[UILabel alloc] init];
        _page1TOSLabel.userInteractionEnabled = YES;
        _page1TOSLabel.textAlignment = NSTextAlignmentCenter;
        _page1TOSLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
        _page1TOSLabel.numberOfLines = 0;
        _page1TOSLabel.backgroundColor = [UIColor clearColor];
        _page1TOSLabel.font = [WPNUXUtility tosLabelFont];
        _page1TOSLabel.textColor = [WPNUXUtility tosLabelColor];
        [self.view addSubview:_page1TOSLabel];
        
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedTOSLabel)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_page1TOSLabel addGestureRecognizer:gestureRecognizer];
    }
    
    // Add Next Button
    if (_page1NextButton == nil) {
        _page1NextButton = [[WPNUXPrimaryButton alloc] init];
        [_page1NextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
        _page1NextButton.enabled = NO;
        [_page1NextButton addTarget:self action:@selector(clickedPage1NextButton) forControlEvents:UIControlEventTouchUpInside];
        [_page1NextButton sizeToFit];
        [self.view addSubview:_page1NextButton];
    }
}

- (void)layoutPage1Controls
{
    CGFloat x,y;
    
    // Layout Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    x = _viewWidth - helpButtonImage.size.width - CreateAccountAndBlogStandardOffset;
    y = 0.5 * CreateAccountAndBlogStandardOffset;
    if (IS_IOS7 && IS_IPHONE) {
        y += CreateAccountAndBlogiOS7StatusBarOffset;
    }
    _helpButton.frame = CGRectMake(x, y, helpButtonImage.size.width, helpButtonImage.size.height);
    
    // Layout Cancel Button
    x = 0;
    y = 0.5 * CreateAccountAndBlogStandardOffset;
    if (IS_IOS7 && IS_IPHONE) {
        y += CreateAccountAndBlogiOS7StatusBarOffset;
    }
    _cancelButton.frame = CGRectMake(x, y, CGRectGetWidth(_cancelButton.frame), CGRectGetHeight(_cancelButton.frame));
        
    // Layout the controls starting out from y of 0, then offset them once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.
    
    // Layout Icon
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    y = 0;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    y = CGRectGetMaxY(_page1Icon.frame) + CreateAccountAndBlogStandardOffset;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Email
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_page1Title.frame) + CreateAccountAndBlogStandardOffset;
    _page1EmailText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Username
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_page1EmailText.frame) - 1;
    _page1UsernameText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Password
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_page1UsernameText.frame) - 1;
    _page1PasswordText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout Site Address
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    y = CGRectGetMaxY(_page1PasswordText.frame) - 1;
    _page2SiteAddressText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout WordPressCom Label
    [_page2WordPressComLabel sizeToFit];
    CGSize wordPressComLabelSize = _page2WordPressComLabel.frame.size;
    wordPressComLabelSize.height = _page2SiteAddressText.frame.size.height - 10;
    wordPressComLabelSize.width += 10;
    _page2WordPressComLabel.frame = CGRectMake(_page2SiteAddressText.frame.size.width - wordPressComLabelSize.width - 5, (_page2SiteAddressText.frame.size.height - wordPressComLabelSize.height) / 2 - 1, wordPressComLabelSize.width, wordPressComLabelSize.height);
    
    // Layout Next Button
    x = (_viewWidth - CGRectGetWidth(_page1NextButton.frame))/2.0;
    y = CGRectGetMaxY(_page2SiteAddressText.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page1NextButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1NextButton.frame), CGRectGetHeight(_page1NextButton.frame)));

    // Layout Terms of Service
    CGFloat TOSSingleLineHeight = [@"WordPress" sizeWithFont:_page1TOSLabel.font].height;
    CGSize TOSLabelSize = [_page1TOSLabel.text sizeWithFont:_page1TOSLabel.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    // If the terms of service don't fit on two lines, then shrink the font to make sure the entire terms of service is visible.
    if (TOSLabelSize.height > 2*TOSSingleLineHeight) {
        _page1TOSLabel.font = [WPNUXUtility tosLabelSmallerFont];
        TOSLabelSize = [_page1TOSLabel.text sizeWithFont:_page1TOSLabel.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    }
    x = (_viewWidth - TOSLabelSize.width)/2.0;
    y = CGRectGetMaxY(_page1NextButton.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page1TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));
    
    NSArray *controls = @[_page1Icon, _page1Title, _page1EmailText, _page1UsernameText, _page1PasswordText, _page1TOSLabel, _page1NextButton, _page2SiteAddressText];
    [WPNUXUtility centerViews:controls withStartingView:_page1Icon andEndingView:_page1TOSLabel forHeight:_viewHeight];
}


- (void)clickedHelpButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedHelp];
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)clickedCancelButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedCancel];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickedOnScrollView:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self.view];
    
    BOOL clickedPage1Next = CGRectContainsPoint(_page1NextButton.frame, touchPoint) && _page1NextButton.enabled;
    
    if (_keyboardVisible) {
        // When the keyboard is displayed, the normal button events don't fire off properly as
        // this gesture recognizer intercepts them. We double check that the user didn't press a button
        // while in this mode and if they did hand off the event.
        if (clickedPage1Next) {
            [self clickedPage1NextButton];
        }
    }
    
    [self.view endEditing:YES];
}

- (void)clickedPage1NextButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedAccountPageNext];
    
    [self.view endEditing:YES];
    
    if (![self page1FieldsValid]) {
        [self showPage1Errors];
        return;
    } else {
        // Check if user changed default URL and if so track the stat for it.
        if (![_page2SiteAddressText.text isEqualToString:_defaultSiteUrl]) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountChangedDefaultURL];
        }
        
        [self createUserAndSite];
    }
}

- (void)clickedTOSLabel
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:@"http://en.wordpress.com/tos/"]];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:webViewController animated:NO];
}

- (CGFloat)topButtonYOrigin {
    
    if ([self respondsToSelector:@selector(topLayoutGuide)])
    {
        return [[self topLayoutGuide] length] + 0.5 * CreateAccountAndBlogStandardOffset;
    } else
    {
        return CreateAccountAndBlogStandardOffset;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    
    _keyboardOffset = (CGRectGetMaxY(_page1NextButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_page1NextButton.frame);
    
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
    return @[_page1Title, _page1UsernameText, _page1EmailText, _page1PasswordText, _page1NextButton, _page2SiteAddressText];
}

- (NSArray *)controlsToShowOrHideDuringKeyboardTransition
{
    return @[_page1Icon, _helpButton, _cancelButton, _page1TOSLabel];
}

- (void)displayRemoteError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    [self showError:errorMessage];
}

- (BOOL)page1FieldsFilled
{
    return [self isEmailedFilled] && [self isUsernameFilled] && [self isPasswordFilled] && [self isSiteAddressFilled];
}

- (BOOL)isEmailedFilled
{
    return ([[_page1EmailText.text trim] length] != 0);
}

- (BOOL)isUsernameFilled
{
    return ([[_page1UsernameText.text trim] length] != 0);
}

- (BOOL)isUsernameUnderFiftyCharacters
{
    return [[_page1UsernameText.text trim] length] <= 50;
}

- (BOOL)isPasswordFilled
{
    return ([[_page1PasswordText.text trim] length] != 0);
}

- (BOOL)isSiteAddressFilled
{
    return ([[_page2SiteAddressText.text trim] length] != 0);
}

- (BOOL)page1FieldsValid
{
    return [self page1FieldsFilled] && [self isUsernameUnderFiftyCharacters];
}

#warning Implement proper title generation
- (NSString *)generateSiteTitleFromUsername:(NSString *)username {
    
    return nil;
}

- (void)showPage1Errors
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
    return [dotCom stringByReplacingMatchesInString:_page2SiteAddressText.text options:0 range:NSMakeRange(0, [_page2SiteAddressText.text length]) withTemplate:@""];
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

- (void)createUserAndSite
{
    WPAsyncBlockOperation *userCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createUserSuccess)(id) = ^(id responseObject){
            [operation didSucceed];
        };
        void (^createUserFailure)(NSError *) = ^(NSError *error) {
            [operation didFail];
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] createWPComAccountWithEmail:_page1EmailText.text
                                                     andUsername:_page1UsernameText.text
                                                     andPassword:_page1PasswordText.text
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
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] signInWithUsername:_page1UsernameText.text
                                               password:_page1PasswordText.text
                                                success:signInSuccess
                                                failure:signInFailure];
    }];
    
    WPAsyncBlockOperation *blogCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createBlogSuccess)(id) = ^(id responseObject){
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountCreatedAccount];
            [operation didSucceed];
            [SVProgressHUD dismiss];
            if (self.onCreatedUser) {
                self.onCreatedUser(_page1UsernameText.text, _page1PasswordText.text);
            }
        };
        void (^createBlogFailure)(NSError *error) = ^(NSError *error) {
            [SVProgressHUD dismiss];
            [operation didFail];
            [self displayRemoteError:error];
        };
        
        NSNumber *languageId = [_currentLanguage objectForKey:@"lang_id"];
        [[WordPressComApi sharedApi] createWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                                               andBlogTitle:[self generateSiteTitleFromUsername:_page1UsernameText.text]
                                              andLanguageId:languageId
                                          andBlogVisibility:WordPressComApiBlogVisibilityPublic
                                                    success:createBlogSuccess
                                                    failure:createBlogFailure];

    }];
    
    [blogCreation addDependency:userSignIn];
    [userSignIn addDependency:userCreation];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating User and Site", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    [_operationQueue addOperation:userCreation];
    [_operationQueue addOperation:userSignIn];
    [_operationQueue addOperation:blogCreation];
}

@end
