//
//  CreateAccountAndBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogViewController.h"
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

@interface CreateAccountAndBlogViewController ()<
    UIScrollViewDelegate,
    UITextFieldDelegate,
    UIGestureRecognizerDelegate> {
    UIScrollView *_scrollView;
    
    // Page 1
    WPNUXBackButton *_cancelButton;
    UIButton *_helpButton;
    UIImageView *_page1Icon;
    UILabel *_page1Title;
    UILabel *_page1TOSLabel;
    UITextField *_page1EmailText;
    UITextField *_page1UsernameText;
    UITextField *_page1PasswordText;
    WPNUXPrimaryButton *_page1NextButton;
    
    // Page 2
    UIImageView *_page2Icon;
    UILabel *_page2Title;
    UILabel *_page2TOSLabel;
    UILabel *_page2WordPressComLabel;
    UITextField *_page2SiteTitleText;
    UITextField *_page2SiteAddressText;
    UITextField *_page2SiteLanguageText;
    UIImageView *_page2SiteLanguageDropdownImage;
    WPNUXPrimaryButton *_page2NextButton;
    WPNUXPrimaryButton *_page2PreviousButton;
    
    // Page 3
    UIImageView *_page3Icon;
    UILabel *_page3Title;
    UILabel *_page3EmailLabel;
    UILabel *_page3UsernameLabel;
    UILabel *_page3SiteTitleLabel;
    UILabel *_page3SiteAddressLabel;
    UILabel *_page3SiteLanguageLabel;
    WPNUXPrimaryButton *_page3NextButton;
    WPNUXPrimaryButton *_page3PreviousButton;
    UIImageView *_page3FirstLineSeparator;
    UIImageView *_page3SecondLineSeparator;
    UIImageView *_page3ThirdLineSeparator;
    UIImageView *_page3FourthLineSeparator;
    UIImageView *_page3FifthLineSeparator;
    UIImageView *_page3SixthLineSeparator;
    
    NSOperationQueue *_operationQueue;
    
    // This is so if the user pages back and forth we aren't validating each time
    BOOL _page1FieldsValid;
    BOOL _page2FieldsValid;

    BOOL _hasViewAppeared;
    BOOL _keyboardVisible;
    BOOL _savedOriginalPositionsOfStickyControls;
    CGFloat _infoButtonOriginalX;
    CGFloat _cancelButtonOriginalX;
    CGFloat _keyboardOffset;
    NSString *_defaultSiteUrl;
    
    NSUInteger _currentPage;
        
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


- (id)init
{
    self = [super init];
    if (self) {
        _currentPage = 1;
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
    [self addPage2Controls];
    [self addPage3Controls];
    [self equalizePreviousAndNextButtonWidths];
    [self layoutPage1Controls];
    [self layoutPage2Controls];
    [self layoutPage3Controls];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self layoutScrollview];
    [self savePositionsOfStickyControls];
    
    if (_hasViewAppeared) {
        // This is for the case when the user pulls up the select language view on page 2 and returns to this view. When that
        // happens the sticky controls on the top won't be in the correct place, so in order to set them up we
        // 'page' to the current content offset in the _scrollView to ensure that the cancel button and help button
        // are in the correct place6
        [self moveStickyControlsForContentOffset:CGPointMake(_scrollView.contentOffset.x, 0)];
    }
    
    _hasViewAppeared = YES;
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
        if (_page1NextButton.enabled) {
            [self clickedPage1NextButton];            
        }
    } else if (textField == _page2SiteTitleText) {
        [_page2SiteAddressText becomeFirstResponder];
    } else if (textField == _page2SiteAddressText) {
        if (_page2NextButton.enabled) {
            [self clickedPage2NextButton];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSArray *page1Fields = @[_page1EmailText, _page1UsernameText, _page1PasswordText];
    NSArray *page2Fields = @[_page2SiteTitleText, _page2SiteAddressText];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];

    if ([page1Fields containsObject:textField]) {
        _page1FieldsValid = NO;
        [self updatePage1ButtonEnabledStatusFor:textField andUpdatedString:updatedString];
    } else if ([page2Fields containsObject:textField]) {
        _page2FieldsValid = NO;
        [self updatePage2ButtonEnabledStatusFor:textField andUpdatedString:updatedString];
    }
    
    return YES;
}

- (void)updatePage1ButtonEnabledStatusFor:(UITextField *)textField andUpdatedString:(NSString *)updatedString
{
    BOOL isEmailFilled = [self isEmailedFilled];
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    
    if (textField == _page1EmailText) {
        isEmailFilled = updatedStringHasContent;
    } else if (textField == _page1UsernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _page1PasswordText) {
        isPasswordFilled = updatedStringHasContent;
    }
    
    _page1NextButton.enabled = isEmailFilled && isUsernameFilled && isPasswordFilled;
}

- (void)updatePage2ButtonEnabledStatusFor:(UITextField *)textField andUpdatedString:(NSString *)updatedString
{
    BOOL isSiteTitleFilled = [self isSiteTitleFilled];
    BOOL isSiteAddressFilled = [self isSiteAddressFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    
    if (textField == _page2SiteTitleText) {
        isSiteTitleFilled = updatedStringHasContent;
    } else if (textField == _page2SiteAddressText) {
        isSiteAddressFilled = updatedStringHasContent;
    }
    
    _page2NextButton.enabled = isSiteTitleFilled && isSiteAddressFilled;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _page1NextButton.enabled = [self page1FieldsFilled];
    _page2NextButton.enabled = [self page2FieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    _page1NextButton.enabled = [self page1FieldsFilled];
    _page2NextButton.enabled = [self page2FieldsFilled];
    return YES;
}

#pragma mark - UIScrollView Delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_viewWidth) + 1;
    [self flagPageViewed:pageViewed];
    [self moveStickyControlsForContentOffset:scrollView.contentOffset];
}

#pragma mark - Private Methods

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _viewWidth * 3;
    _scrollView.scrollEnabled = NO;
    _scrollView.frame = self.view.bounds;
    _scrollView.contentSize = scrollViewSize;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    _scrollView.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedOnScrollView:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = NO;
    [_scrollView addGestureRecognizer:gestureRecognizer];
}

- (void)layoutScrollview
{
    _scrollView.frame = self.view.bounds;
}

- (void)addPage1Controls
{
    // Add Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    UIImage *helpButtonImageHighlighted = [UIImage imageNamed:@"btn-help-tap"];
    if (_helpButton == nil) {
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_helpButton setImage:helpButtonImage forState:UIControlStateNormal];
        [_helpButton setImage:helpButtonImageHighlighted forState:UIControlStateHighlighted];
        _helpButton.frame = CGRectMake(0, 0, helpButtonImage.size.width, helpButtonImage.size.height);
        [_helpButton addTarget:self action:@selector(clickedHelpButton) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_helpButton];
    }
    
    // Add Cancel Button
    if (_cancelButton == nil) {
        _cancelButton = [[WPNUXBackButton alloc] init];
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(clickedCancelButton) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton sizeToFit];
        [_scrollView addSubview:_cancelButton];
    }
    
    // Add Icon
    if (_page1Icon == nil) {
        UIImage *icon = [UIImage imageNamed:@"icon-wp"];
        _page1Icon = [[UIImageView alloc] initWithImage:icon];
        [_scrollView addSubview:_page1Icon];
    }
    
    // Add Title
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.textAlignment = NSTextAlignmentCenter;
        _page1Title.text = NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title");
        _page1Title.numberOfLines = 0;
        _page1Title.backgroundColor = [UIColor clearColor];
        _page1Title.font = [WPNUXUtility titleFont];
        _page1Title.textColor = [UIColor whiteColor];
        _page1Title.lineBreakMode = NSLineBreakByWordWrapping;
        [_scrollView addSubview:_page1Title];
    }
    
    // Add Email
    if (_page1EmailText == nil) {
        _page1EmailText = [[WPWalkthroughTextField alloc] init];
        _page1EmailText.backgroundColor = [UIColor whiteColor];
        _page1EmailText.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
        _page1EmailText.font = [WPNUXUtility textFieldFont];
        _page1EmailText.adjustsFontSizeToFitWidth = YES;
        _page1EmailText.delegate = self;
        _page1EmailText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1EmailText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page1EmailText.keyboardType = UIKeyboardTypeEmailAddress;
        [_scrollView addSubview:_page1EmailText];
    }
    
    // Add Username
    if (_page1UsernameText == nil) {
        _page1UsernameText = [[WPWalkthroughTextField alloc] init];
        _page1UsernameText.backgroundColor = [UIColor whiteColor];
        _page1UsernameText.placeholder = NSLocalizedString(@"Username", nil);
        _page1UsernameText.font = [WPNUXUtility textFieldFont];
        _page1UsernameText.adjustsFontSizeToFitWidth = YES;
        _page1UsernameText.delegate = self;
        _page1UsernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1UsernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_page1UsernameText];
    }
    
    // Add Password
    if (_page1PasswordText == nil) {
        _page1PasswordText = [[WPWalkthroughTextField alloc] init];
        _page1PasswordText.secureTextEntry = YES;
        _page1PasswordText.backgroundColor = [UIColor whiteColor];
        _page1PasswordText.placeholder = NSLocalizedString(@"Password", nil);
        _page1PasswordText.font = [WPNUXUtility textFieldFont];
        _page1PasswordText.adjustsFontSizeToFitWidth = YES;
        _page1PasswordText.delegate = self;
        _page1PasswordText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page1PasswordText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_page1PasswordText];
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
        [_scrollView addSubview:_page1TOSLabel];
        
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
        [_scrollView addSubview:_page1NextButton];
    }
}

- (void)layoutPage1Controls
{
    CGFloat x,y;
    CGFloat currentPage=1;
    
    // Layout Help Button
    UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
    x = _viewWidth - helpButtonImage.size.width;
    y = 0;
    _helpButton.frame = CGRectMake(x, y, helpButtonImage.size.width, helpButtonImage.size.height);
    
    // Layout Cancel Button
    x = 0;
    y = 0;
    _cancelButton.frame = CGRectMake(x, y, CGRectGetWidth(_cancelButton.frame), CGRectGetHeight(_cancelButton.frame));
        
    // Layout the controls starting out from y of 0, then offset them once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.
    
    // Layout Icon
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = 0;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1Icon.frame) + CreateAccountAndBlogStandardOffset;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Email
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1Title.frame) + CreateAccountAndBlogStandardOffset;
    _page1EmailText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Username
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1EmailText.frame) - 1;
    _page1UsernameText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));

    // Layout Password
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1UsernameText.frame) - 1;
    _page1PasswordText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout Next Button
    x = (_viewWidth - CGRectGetWidth(_page1NextButton.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1PasswordText.frame) + 0.5*CreateAccountAndBlogStandardOffset;
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
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page1NextButton.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page1TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));
    
    NSArray *controls = @[_page1Icon, _page1Title, _page1EmailText, _page1UsernameText, _page1PasswordText, _page1TOSLabel, _page1NextButton];
    [WPNUXUtility centerViews:controls withStartingView:_page1Icon andEndingView:_page1TOSLabel forHeight:_viewHeight];
}

- (void)addPage2Controls
{
    // Add Icon
    if (_page2Icon == nil) {
        UIImage *icon = [UIImage imageNamed:@"icon-wp"];
        _page2Icon = [[UIImageView alloc] initWithImage:icon];
        [_scrollView addSubview:_page2Icon];
    }
    
    // Add Title
    if (_page2Title == nil) {
        _page2Title = [[UILabel alloc] init];
        _page2Title.textAlignment = NSTextAlignmentCenter;
        _page2Title.text = NSLocalizedString(@"Create your first WordPress.com site", @"NUX Create Account Page 2 Title");
        _page2Title.numberOfLines = 0;
        _page2Title.backgroundColor = [UIColor clearColor];
        _page2Title.font = [WPNUXUtility titleFont];
        _page2Title.textColor = [UIColor whiteColor];
        _page2Title.lineBreakMode = NSLineBreakByWordWrapping;
        [_scrollView addSubview:_page2Title];
    }
    
    // Add Site Title
    if (_page2SiteTitleText == nil) {
        _page2SiteTitleText = [[WPWalkthroughTextField alloc] init];
        _page2SiteTitleText.backgroundColor = [UIColor whiteColor];
        _page2SiteTitleText.placeholder = NSLocalizedString(@"Site Title", @"NUX Create Account Page 2 Site Title Placeholder");
        _page2SiteTitleText.font = [WPNUXUtility textFieldFont];
        _page2SiteTitleText.adjustsFontSizeToFitWidth = YES;
        _page2SiteTitleText.delegate = self;
        _page2SiteTitleText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page2SiteTitleText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_page2SiteTitleText];
    }
    
    // Add Site Address
    if (_page2SiteAddressText == nil) {
        _page2SiteAddressText = [[WPWalkthroughTextField alloc] init];
        _page2SiteAddressText.backgroundColor = [UIColor whiteColor];
        _page2SiteAddressText.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
        _page2SiteAddressText.font = [WPNUXUtility textFieldFont];
        _page2SiteAddressText.adjustsFontSizeToFitWidth = YES;
        _page2SiteAddressText.delegate = self;
        _page2SiteAddressText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page2SiteAddressText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_page2SiteAddressText];
        
        // add .wordpress.com label to textfield
        _page2WordPressComLabel = [[UILabel alloc] init];
        _page2WordPressComLabel.text = @".wordpress.com";
        _page2WordPressComLabel.textAlignment = NSTextAlignmentCenter;
        _page2WordPressComLabel.font = [WPNUXUtility descriptionTextFont];
        _page2WordPressComLabel.textColor = [UIColor whiteColor];
        _page2WordPressComLabel.backgroundColor = [WPNUXUtility backgroundColor];
        [_page2WordPressComLabel sizeToFit];
        
        UIEdgeInsets siteAddressTextInsets = [(WPWalkthroughTextField *)_page2SiteAddressText textInsets];
        siteAddressTextInsets.right += _page2WordPressComLabel.frame.size.width + 10;
        [(WPWalkthroughTextField *)_page2SiteAddressText setTextInsets:siteAddressTextInsets];
        [_page2SiteAddressText addSubview:_page2WordPressComLabel];
    }
    
    // Add Site Language
    if (_page2SiteLanguageText == nil) {
        _page2SiteLanguageText = [[WPWalkthroughTextField alloc] init];
        _page2SiteLanguageText.backgroundColor = [UIColor whiteColor];
        _page2SiteLanguageText.placeholder = NSLocalizedString(@"Site Language", @"NUX Create Account Page 2 Site Language Placeholder");
        _page2SiteLanguageText.font = [WPNUXUtility textFieldFont];
        _page2SiteLanguageText.adjustsFontSizeToFitWidth = YES;
        _page2SiteLanguageText.delegate = self;
        _page2SiteLanguageText.autocorrectionType = UITextAutocorrectionTypeNo;
        _page2SiteLanguageText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _page2SiteLanguageText.enabled = NO;
        _page2SiteLanguageText.text = [_currentLanguage objectForKey:@"name"];
        [_scrollView addSubview:_page2SiteLanguageText];
    }
    
    // Add Site Language Dropdown Image
    if (_page2SiteLanguageDropdownImage == nil) {
        UIImage *pushDetailImage = [UIImage imageNamed:@"textPushDetailIcon"];
        _page2SiteLanguageDropdownImage = [[UIImageView alloc] initWithImage:pushDetailImage];
        [_scrollView addSubview:_page2SiteLanguageDropdownImage];
    }
    
    // Add Terms of Service Label
    if (_page2TOSLabel == nil) {
        _page2TOSLabel = [[UILabel alloc] init];
        _page2TOSLabel.userInteractionEnabled = YES;
        _page2TOSLabel.textAlignment = NSTextAlignmentCenter;
        _page2TOSLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
        _page2TOSLabel.numberOfLines = 0;
        _page2TOSLabel.backgroundColor = [UIColor clearColor];
        _page2TOSLabel.font = [WPNUXUtility tosLabelFont];
        _page2TOSLabel.textColor = [WPNUXUtility tosLabelColor];
        [_scrollView addSubview:_page2TOSLabel];
        
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedTOSLabel)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_page2TOSLabel addGestureRecognizer:gestureRecognizer];
    }
    
    // Add Next Button
    if (_page2NextButton == nil) {
        _page2NextButton = [[WPNUXPrimaryButton alloc] init];
        [_page2NextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
        [_page2NextButton addTarget:self action:@selector(clickedPage2NextButton) forControlEvents:UIControlEventTouchUpInside];
        [_page2NextButton sizeToFit];
        [_scrollView addSubview:_page2NextButton];
    }

    // Add Previous Button
    if (_page2PreviousButton == nil) {
        _page2PreviousButton = [[WPNUXPrimaryButton alloc] init];
        [_page2PreviousButton setTitle:NSLocalizedString(@"Previous", nil) forState:UIControlStateNormal];
        [_page2PreviousButton addTarget:self action:@selector(clickedPage2PreviousButton) forControlEvents:UIControlEventTouchUpInside];
        [_page2PreviousButton sizeToFit];
        [_scrollView addSubview:_page2PreviousButton];
    }
}

- (void)layoutPage2Controls
{
    CGFloat x,y;
    CGFloat currentPage=2;
    
    // Layout the controls starting out from y of 0, then offset them once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.

    // Layout Icon
    x = (_viewWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = 0;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page2Title.text sizeWithFont:_page2Title.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2Icon.frame) + CreateAccountAndBlogStandardOffset;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Site Title
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2Title.frame) + CreateAccountAndBlogStandardOffset;
    _page2SiteTitleText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout Site Address
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2SiteTitleText.frame) - 1;
    _page2SiteAddressText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout WordPressCom Label
    [_page2WordPressComLabel sizeToFit];
    CGSize wordPressComLabelSize = _page2WordPressComLabel.frame.size;
    wordPressComLabelSize.height = _page2SiteAddressText.frame.size.height - 10;
    wordPressComLabelSize.width += 10;
    _page2WordPressComLabel.frame = CGRectMake(_page2SiteAddressText.frame.size.width - wordPressComLabelSize.width - 5, (_page2SiteAddressText.frame.size.height - wordPressComLabelSize.height) / 2, wordPressComLabelSize.width, wordPressComLabelSize.height);

    // Layout Site Language
    x = (_viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2SiteAddressText.frame) - 1;
    _page2SiteLanguageText.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, CreateAccountAndBlogTextFieldHeight));
    
    // Layout Dropdown Image
    x = CGRectGetMaxX(_page2SiteLanguageText.frame) - CGRectGetWidth(_page2SiteLanguageDropdownImage.frame) - CreateAccountAndBlogStandardOffset;
    y = CGRectGetMinY(_page2SiteLanguageText.frame) + (CGRectGetHeight(_page2SiteLanguageText.frame) - CGRectGetHeight(_page2SiteLanguageDropdownImage.frame))/2.0;
    _page2SiteLanguageDropdownImage.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2SiteLanguageDropdownImage.frame), CGRectGetHeight(_page2SiteLanguageDropdownImage.frame)));
    
    // Layout Previous Button
    x = (_viewWidth - CGRectGetWidth(_page2PreviousButton.frame) - CGRectGetWidth(_page2NextButton.frame) - CreateAccountAndBlogStandardOffset)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2SiteLanguageText.frame) + CreateAccountAndBlogStandardOffset;
    _page2PreviousButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2PreviousButton.frame), CGRectGetHeight(_page2PreviousButton.frame)));
    
    // Layout Next Button
    x = CGRectGetMaxX(_page2PreviousButton.frame) + CreateAccountAndBlogStandardOffset;
    y = CGRectGetMaxY(_page2SiteLanguageText.frame) + CreateAccountAndBlogStandardOffset;
    _page2NextButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2NextButton.frame), CGRectGetHeight(_page2NextButton.frame)));
    
    // Layout Terms of Service
    CGFloat TOSSingleLineHeight = [@"WordPress" sizeWithFont:_page2TOSLabel.font].height;
    CGSize TOSLabelSize = [_page2TOSLabel.text sizeWithFont:_page2TOSLabel.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    // If the terms of service don't fit on two lines, then shrink the font to make sure the entire terms of service is visible.
    if (TOSLabelSize.height > 2*TOSSingleLineHeight) {
        _page2TOSLabel.font = [WPNUXUtility tosLabelSmallerFont];
        TOSLabelSize = [_page2TOSLabel.text sizeWithFont:_page2TOSLabel.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    }
    x = (_viewWidth - TOSLabelSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page2NextButton.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page2TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));
    
    NSArray *controls = @[_page2Icon, _page2Title, _page2SiteTitleText, _page2SiteAddressText, _page2SiteLanguageText, _page2SiteLanguageDropdownImage, _page2TOSLabel, _page2PreviousButton, _page2NextButton];
    [WPNUXUtility centerViews:controls withStartingView:_page2Icon andEndingView:_page2TOSLabel forHeight:_viewHeight];
}

- (void)addPage3Controls
{
    // Add Icon
    if (_page3Icon == nil) {
        UIImage *icon = [UIImage imageNamed:@"icon-wp"];
        _page3Icon = [[UIImageView alloc] initWithImage:icon];
        [_scrollView addSubview:_page3Icon];
    }
    
    // Add Title
    if (_page3Title == nil) {
        _page3Title = [[UILabel alloc] init];
        _page3Title.textAlignment = NSTextAlignmentCenter;
        _page3Title.text = NSLocalizedString(@"Review your information", @"NUX Create Account Page 3 Title");
        _page3Title.numberOfLines = 0;
        _page3Title.backgroundColor = [UIColor clearColor];
        _page3Title.font = [WPNUXUtility titleFont];
        _page3Title.textColor = [UIColor whiteColor];
        _page3Title.lineBreakMode = NSLineBreakByWordWrapping;
        [_scrollView addSubview:_page3Title];
    }

    // Add First Line Separator
    if (_page3FirstLineSeparator == nil) {
        _page3FirstLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3FirstLineSeparator];
    }

    // Add Email Label
    if (_page3EmailLabel == nil) {
        _page3EmailLabel = [[UILabel alloc] init];
        _page3EmailLabel.textAlignment = NSTextAlignmentCenter;
        _page3EmailLabel.text = @"Email: ";
        _page3EmailLabel.numberOfLines = 1;
        _page3EmailLabel.backgroundColor = [UIColor clearColor];
        _page3EmailLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        _page3EmailLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _page3EmailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_scrollView addSubview:_page3EmailLabel];
    }

    // Add Second Line Separator
    if (_page3SecondLineSeparator == nil) {
        _page3SecondLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3SecondLineSeparator];
    }

    // Add Username
    if (_page3UsernameLabel == nil) {
        _page3UsernameLabel = [[UILabel alloc] init];
        _page3UsernameLabel.textAlignment = NSTextAlignmentCenter;
        _page3UsernameLabel.text = @"Username: ";
        _page3UsernameLabel.numberOfLines = 1;
        _page3UsernameLabel.backgroundColor = [UIColor clearColor];
        _page3UsernameLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        _page3UsernameLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _page3UsernameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_scrollView addSubview:_page3UsernameLabel];
    }

    // Add Third Line Separator
    if (_page3ThirdLineSeparator == nil) {
        _page3ThirdLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3ThirdLineSeparator];
    }

    // Add Site Title
    if (_page3SiteTitleLabel == nil) {
        _page3SiteTitleLabel = [[UILabel alloc] init];
        _page3SiteTitleLabel.textAlignment = NSTextAlignmentCenter;
        _page3SiteTitleLabel.text = @"Site Title: ";
        _page3SiteTitleLabel.numberOfLines = 1;
        _page3SiteTitleLabel.backgroundColor = [UIColor clearColor];
        _page3SiteTitleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        _page3SiteTitleLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _page3SiteTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_scrollView addSubview:_page3SiteTitleLabel];
    }

    // Add Fourth Line Separator
    if (_page3FourthLineSeparator == nil) {
        _page3FourthLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3FourthLineSeparator];
    }

    // Add Site Address
    if (_page3SiteAddressLabel == nil) {
        _page3SiteAddressLabel = [[UILabel alloc] init];
        _page3SiteAddressLabel.textAlignment = NSTextAlignmentCenter;
        _page3SiteAddressLabel.text = @"Site Address: ";
        _page3SiteAddressLabel.numberOfLines = 1;
        _page3SiteAddressLabel.backgroundColor = [UIColor clearColor];
        _page3SiteAddressLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        _page3SiteAddressLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _page3SiteAddressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_scrollView addSubview:_page3SiteAddressLabel];
    }

    // Add Fifth Line Separator
    if (_page3FifthLineSeparator == nil) {
        _page3FifthLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3FifthLineSeparator];
    }
    
    // Add Site Language
    if (_page3SiteLanguageLabel == nil) {
        _page3SiteLanguageLabel = [[UILabel alloc] init];
        _page3SiteLanguageLabel.textAlignment = NSTextAlignmentCenter;
        _page3SiteLanguageLabel.text = @"Site Language: ";
        _page3SiteLanguageLabel.numberOfLines = 1;
        _page3SiteLanguageLabel.backgroundColor = [UIColor clearColor];
        _page3SiteLanguageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        _page3SiteLanguageLabel.textColor = [WPNUXUtility confirmationLabelColor];
        _page3SiteLanguageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_scrollView addSubview:_page3SiteLanguageLabel];
    }
    
    // Add Sixth Line Separator
    if (_page3SixthLineSeparator == nil) {
        _page3SixthLineSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3SixthLineSeparator];
    }
    
    // Add Next Button
    if (_page3NextButton == nil) {
        _page3NextButton = [[WPNUXPrimaryButton alloc] init];
        [_page3NextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
        [_page3NextButton addTarget:self action:@selector(clickedPage3NextButton) forControlEvents:UIControlEventTouchUpInside];
        [_page3NextButton sizeToFit];
        [_scrollView addSubview:_page3NextButton];
    }
    
    // Add Previous Button
    if (_page3PreviousButton == nil) {
        _page3PreviousButton = [[WPNUXPrimaryButton alloc] init];
        [_page3PreviousButton setTitle:NSLocalizedString(@"Previous", nil) forState:UIControlStateNormal];
        [_page3PreviousButton addTarget:self action:@selector(clickedPage3PreviousButton) forControlEvents:UIControlEventTouchUpInside];
        [_page3PreviousButton sizeToFit];
        [_scrollView addSubview:_page3PreviousButton];
    }
}

- (void)layoutPage3Controls
{
    CGFloat x,y;
    CGFloat currentPage=3;
    
    // Layout the controls starting out from y of 0, then offset then once the height of the controls
    // is accurately calculated we can determine the vertical center and adjust everything accordingly.
    
    x = (_viewWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = 0;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page3Title.text sizeWithFont:_page3Title.font constrainedToSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3Icon.frame) + CreateAccountAndBlogStandardOffset;
    _page3Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout First Line Separator
    CGFloat lineSeparatorWidth = _viewWidth - CreateAccountAndBlogStandardOffset;
    CGFloat lineSeparatorHeight = 1;
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3Title.frame) + CreateAccountAndBlogStandardOffset;
    _page3FirstLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Email Label
    CGSize emailLabelSize = [_page3EmailLabel.text sizeWithFont:_page3EmailLabel.font forWidth:CreateAccountAndBlogMaxTextWidth lineBreakMode:NSLineBreakByTruncatingTail];
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3FirstLineSeparator.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3EmailLabel.frame = CGRectMake(x, y, emailLabelSize.width, emailLabelSize.height);
    
    // Layout Second Line Separator
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3EmailLabel.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3SecondLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Username Label
    CGSize usernameLabelSize = [_page3UsernameLabel.text sizeWithFont:_page3UsernameLabel.font forWidth:CreateAccountAndBlogMaxTextWidth lineBreakMode:NSLineBreakByTruncatingTail];
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3SecondLineSeparator.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3UsernameLabel.frame = CGRectMake(x, y, usernameLabelSize.width, usernameLabelSize.height);
    
    // Layout Third Line Separator
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3UsernameLabel.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3ThirdLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Site Title Label
    CGSize siteTitleLabel = [_page3SiteTitleLabel.text sizeWithFont:_page3SiteTitleLabel.font forWidth:CreateAccountAndBlogMaxTextWidth lineBreakMode:NSLineBreakByTruncatingTail];
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3ThirdLineSeparator.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3SiteTitleLabel.frame = CGRectMake(x, y, siteTitleLabel.width, siteTitleLabel.height);
    
    // Layout Fourth Line Separator
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3SiteTitleLabel.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3FourthLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Site Address Label
    CGSize siteAddressLabel = [_page3SiteAddressLabel.text sizeWithFont:_page3SiteAddressLabel.font forWidth:CreateAccountAndBlogMaxTextWidth lineBreakMode:NSLineBreakByTruncatingTail];
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3FourthLineSeparator.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3SiteAddressLabel.frame = CGRectMake(x, y, siteAddressLabel.width, siteAddressLabel.height);
    
    // Layout Fifth Line Separator
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3SiteAddressLabel.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3FifthLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Site Address Label
    CGSize siteLanguageLabelSize = [_page3SiteLanguageLabel.text sizeWithFont:_page3SiteLanguageLabel.font forWidth:CreateAccountAndBlogMaxTextWidth lineBreakMode:NSLineBreakByTruncatingTail];
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3FifthLineSeparator.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3SiteLanguageLabel.frame = CGRectMake(x, y, siteLanguageLabelSize.width, siteLanguageLabelSize.height);

    // Layout Sixth Line Separator
    x = CreateAccountAndBlogStandardOffset;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3SiteLanguageLabel.frame) + 0.5*CreateAccountAndBlogStandardOffset;
    _page3SixthLineSeparator.frame = CGRectMake(x, y, lineSeparatorWidth, lineSeparatorHeight);
    
    // Layout Previous Button
    x = (_viewWidth - CGRectGetWidth(_page3PreviousButton.frame) - CGRectGetWidth(_page3NextButton.frame) - CreateAccountAndBlogStandardOffset)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page3SixthLineSeparator.frame) + CreateAccountAndBlogStandardOffset;
    _page3PreviousButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3PreviousButton.frame), CGRectGetHeight(_page3NextButton.frame)));
    
    // Layout Next Button
    x = CGRectGetMaxX(_page3PreviousButton.frame) + CreateAccountAndBlogStandardOffset;
    y = CGRectGetMaxY(_page3SixthLineSeparator.frame) + CreateAccountAndBlogStandardOffset;
    _page3NextButton.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3NextButton.frame), CGRectGetHeight(_page3NextButton.frame)));
    
    NSArray *controls = @[_page3Icon, _page3Title, _page3FirstLineSeparator, _page3EmailLabel, _page3SecondLineSeparator, _page3UsernameLabel, _page3ThirdLineSeparator, _page3SiteTitleLabel, _page3FourthLineSeparator, _page3SiteAddressLabel, _page3FifthLineSeparator, _page3SiteLanguageLabel, _page3SixthLineSeparator, _page3PreviousButton, _page3NextButton];
    [WPNUXUtility centerViews:controls withStartingView:_page3Icon andEndingView:_page3NextButton forHeight:_viewHeight];
}

- (void)equalizePreviousAndNextButtonWidths
{
    // Ensure Buttons are same width as the sizeToFit command will generate slightly different widths and we want to make the
    // all the previous/next buttons appear uniform.
    
    CGFloat nextButtonWidth = CGRectGetWidth(_page2NextButton.frame);
    CGFloat previousButtonWidth = CGRectGetWidth(_page2PreviousButton.frame);
    CGFloat biggerWidth = nextButtonWidth > previousButtonWidth ? nextButtonWidth : previousButtonWidth;
    NSArray *controls = @[_page1NextButton, _page2PreviousButton, _page2NextButton, _page3PreviousButton, _page3NextButton];
    for (UIControl *control in controls) {
        CGRect frame = control.frame;
        frame.size.width = biggerWidth;
        control.frame = frame;
    }
}

- (void)updatePage3Labels
{
    _page3EmailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Email: %@", @"NUX Create Account Page 3 Email Review Label"), _page1EmailText.text];
    _page3UsernameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Username: %@", @"NUX Create Account Page 3 Username Review Label"), _page1UsernameText.text];
    _page3SiteTitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Site Title: %@", @"NUX Create Account Page 3 Site Title Review Label"), _page2SiteTitleText.text];
    _page3SiteAddressLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Site Address: %@", @"NUX Create Account Page 3 Site Address Review Label"), [NSString stringWithFormat:@"%@.wordpress.com", [self getSiteAddressWithoutWordPressDotCom]]];
    _page3SiteLanguageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Site Language: %@", @"NUX Create Account Page 3 Site Language Review Label"), [_currentLanguage objectForKey:@"name"]];
    
    [self layoutPage3Controls];
}

- (void)clickedHelpButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedHelp];
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
}

- (void)clickedCancelButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedCancel];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)moveToPage:(NSUInteger)page
{
    [_scrollView setContentOffset:CGPointMake(_viewWidth*(page-1), 0) animated:YES];
}

- (void)clickedOnScrollView:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:_scrollView];
    BOOL clickedSiteLanguage = CGRectContainsPoint(_page2SiteLanguageText.frame, touchPoint);
    
    if (clickedSiteLanguage) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedViewLanguages];
        [self showLanguagePicker];
    } else {
        BOOL clickedPage1Next = CGRectContainsPoint(_page1NextButton.frame, touchPoint) && _page1NextButton.enabled;
        BOOL clickedPage2Next = CGRectContainsPoint(_page2NextButton.frame, touchPoint) && _page2NextButton.enabled;
        BOOL clickedPage2Previous = CGRectContainsPoint(_page2PreviousButton.frame, touchPoint);

        if (_keyboardVisible) {
            // When the keyboard is displayed, the normal button events don't fire off properly as
            // this gesture recognizer intercepts them. We double check that the user didn't press a button
            // while in this mode and if they did hand off the event.
            if (clickedPage1Next) {
                [self clickedPage1NextButton];
            } else if(clickedPage2Next) {
                [self clickedPage2NextButton];
            } else if (clickedPage2Previous) {
                [self clickedPage2PreviousButton];
            }            
        }
        
        [self.view endEditing:YES];
    }
}

- (void)clickedPage1NextButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage1Next];
    
    [self.view endEditing:YES];
    
    if (![self page1FieldsValid]) {
        [self showPage1Errors];
        return;
    }
    
    if (_page1FieldsValid) {
        [self moveToPage:2];
    } else {
        _page1NextButton.enabled = NO;
        [self validateUserFields];
    }
}

- (void)clickedPage2NextButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage2Next];

    [self.view endEditing:YES];
    
    if (![self page2FieldsValid]) {
        [self showFieldsNotFilledError];
        return;
    }
    
    if (_page2FieldsValid) {
        [self moveToPage:3];
    } else {
        // Check if user changed default URL and if so track the stat for it.
        if (![_page2SiteAddressText.text isEqualToString:_defaultSiteUrl]) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountChangedDefaultURL];
        }
        
        _page2NextButton.enabled = NO;
        [self validateSiteFields];
    }
}

- (void)clickedPage2PreviousButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage2Previous];

    [self.view endEditing:YES];
    [self moveToPage:1];
}

- (void)clickedPage3NextButton
{
    [self createUserAndSite];
}

- (void)clickedPage3PreviousButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage3Previous];
    
    [self moveToPage:2];
}

- (void)clickedTOSLabel
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:@"http://en.wordpress.com/tos/"]];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:webViewController animated:NO];
}

- (void)savePositionsOfStickyControls
{
    if (!_savedOriginalPositionsOfStickyControls) {
        _savedOriginalPositionsOfStickyControls = YES;
        _infoButtonOriginalX = CGRectGetMinX(_helpButton.frame);
        _cancelButtonOriginalX = CGRectGetMinX(_cancelButton.frame);
    }
}

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page
{
    return (x + _viewWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)page
{
    _currentPage = page;
}

- (void)moveStickyControlsForContentOffset:(CGPoint)contentOffset
{
    if (contentOffset.x < 0)
        return;
    
    CGRect cancelButtonFrame = _cancelButton.frame;
    cancelButtonFrame.origin.x = _cancelButtonOriginalX + contentOffset.x;
    _cancelButton.frame =  cancelButtonFrame;
    
    CGRect infoButtonFrame = _helpButton.frame;
    infoButtonFrame.origin.x = _infoButtonOriginalX + contentOffset.x;
    _helpButton.frame = infoButtonFrame;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (_currentPage == 1) {
        _keyboardOffset = (CGRectGetMaxY(_page1NextButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_page1NextButton.frame);
    } else {
        _keyboardOffset = (CGRectGetMaxY(_page2NextButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(_page2NextButton.frame);
    }

    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition:_currentPage]) {
            CGRect frame = control.frame;
            frame.origin.y -= _keyboardOffset;
            control.frame = frame;
        }
        
        for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition:_currentPage]) {
            control.alpha = 0.0;
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        for (UIControl *control in [self controlsToMoveDuringKeyboardTransition:_currentPage]) {
            CGRect frame = control.frame;
            frame.origin.y += _keyboardOffset;
            control.frame = frame;
        }
                
        for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition:_currentPage]) {
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

- (NSArray *)controlsToMoveDuringKeyboardTransition:(NSUInteger)page
{
    if (page == 1) {
        return @[_page1Title, _page1UsernameText, _page1EmailText, _page1PasswordText, _page1NextButton];
    } else if (page == 2) {
        return @[_page2Title, _page2SiteTitleText, _page2SiteAddressText, _page2SiteLanguageText, _page2SiteLanguageDropdownImage, _page2NextButton, _page2PreviousButton];
    } else {
        return nil;
    }
}

- (NSArray *)controlsToShowOrHideDuringKeyboardTransition:(NSUInteger)page
{
    if (page == 1) {
        return @[_page1Icon, _helpButton, _cancelButton, _page1TOSLabel];
    } else if (page == 2) {
        return @[_page2Icon, _helpButton, _cancelButton, _page2TOSLabel];
    } else {
        return nil;
    }
}

- (void)showLanguagePicker
{
    [self.view endEditing:YES];
    SelectWPComLanguageViewController *languageViewController = [[SelectWPComLanguageViewController alloc] init];
    languageViewController.currentlySelectedLanguageId = [[_currentLanguage objectForKey:@"lang_id"] intValue];
    languageViewController.didSelectLanguage = ^(NSDictionary *language){
        [self updateLanguage:language];
    };
    [self.navigationController pushViewController:languageViewController animated:YES];
}

- (void)updateLanguage:(NSDictionary *)language
{
    _currentLanguage = language;
    _page2SiteLanguageText.text = [_currentLanguage objectForKey:@"name"];
    _page2FieldsValid = NO;
}

- (void)displayRemoteError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    [self showError:errorMessage];
}

- (BOOL)page1FieldsFilled
{
    return [self isEmailedFilled] && [self isUsernameFilled] && [self isPasswordFilled];
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

- (BOOL)page1FieldsValid
{
    return [self page1FieldsFilled] && [self isUsernameUnderFiftyCharacters];
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

- (void)validateUserFields
{
    void (^userValidationSuccess)(id) = ^(id responseObject) {
        _page1NextButton.enabled = YES;
        [SVProgressHUD dismiss];
        _page1FieldsValid = YES;
        if ([[_page2SiteAddressText.text trim] length] == 0) {
            _page2SiteAddressText.text = _defaultSiteUrl = _page1UsernameText.text;
        }
        [self updatePage3Labels];
        [self moveToPage:2];
    };
    
    void (^userValidationFailure)(NSError *) = ^(NSError *error){
        _page1NextButton.enabled = YES;
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    };
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Validating User Data", nil) maskType:SVProgressHUDMaskTypeBlack];
    [[WordPressComApi sharedApi] validateWPComAccountWithEmail:_page1EmailText.text
                                                   andUsername:_page1UsernameText.text
                                                   andPassword:_page1PasswordText.text
                                                       success:userValidationSuccess
                                                       failure:userValidationFailure];

}

- (BOOL)page2FieldsValid
{
    return [self page2FieldsFilled];
}

- (BOOL)page2FieldsFilled
{
    return [self isSiteTitleFilled] && [self isSiteAddressFilled];
}

- (BOOL)isSiteTitleFilled
{
    return ([[_page2SiteTitleText.text trim] length] != 0);
}

- (BOOL)isSiteAddressFilled
{
    return ([[_page2SiteAddressText.text trim] length] != 0);
}

- (NSString *)getSiteAddressWithoutWordPressDotCom
{
    NSRegularExpression *dotCom = [NSRegularExpression regularExpressionWithPattern:@"\\.wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    return [dotCom stringByReplacingMatchesInString:_page2SiteAddressText.text options:0 range:NSMakeRange(0, [_page2SiteAddressText.text length]) withTemplate:@""];
}

- (void)showError:(NSString *)message
{
    WPWalkthroughOverlayView *overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    overlayView.overlayTitle = NSLocalizedString(@"Error", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    overlayView.dismissCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)validateSiteFields
{
    void (^blogValidationSuccess)(id) = ^(id responseObject) {
        _page2NextButton.enabled = YES;
        [SVProgressHUD dismiss];
        _page2FieldsValid = YES;
        [self updatePage3Labels];
        [self moveToPage:3];
    };
    void (^blogValidationFailure)(NSError *) = ^(NSError *error) {
        _page2NextButton.enabled = YES;
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    };
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Validating Site Data", nil) maskType:SVProgressHUDMaskTypeBlack];

    NSNumber *languageId = [_currentLanguage objectForKey:@"lang_id"];
    [[WordPressComApi sharedApi] validateWPComBlogWithUrl:[self getSiteAddressWithoutWordPressDotCom]
                                             andBlogTitle:_page2SiteTitleText.text
                                            andLanguageId:languageId
                                                  success:blogValidationSuccess
                                                  failure:blogValidationFailure];
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
                                               andBlogTitle:_page2SiteTitleText.text
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
