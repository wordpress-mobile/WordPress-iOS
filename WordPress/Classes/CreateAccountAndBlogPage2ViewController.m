//
//  CreateAccountAndBlogPage2ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage2ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"
#import "NewWPWalkthroughOverlayView.h"
#import "WPComLanguages.h"
#import "SelectWPComLanguageViewController.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"

@interface CreateAccountAndBlogPage2ViewController () {
    NSDictionary *_currentLanguage;
    CGFloat _keyboardOffset;
    NSString *_defaultSiteUrl;
    BOOL _hasDefaultSiteUrlBeenSet;
    BOOL _page2FieldsValid;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITextField *siteTitle;
@property (nonatomic, strong) IBOutlet UITextField *siteAddress;
@property (nonatomic, strong) IBOutlet UITextField *siteLanguage;
@property (nonatomic, strong) IBOutlet UIImageView *dropdownImage;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *previousButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;
@property (nonatomic, strong) IBOutlet UILabel *tosLabel;

@end

@implementation CreateAccountAndBlogPage2ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"Create your first WordPress.com site", @"NUX Create Account Page 2 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.tosLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
    self.tosLabel.font = [WPNUXUtility tosLabelFont];
    self.tosLabel.layer.shadowRadius = 2.0;
    self.tosLabel.userInteractionEnabled = true;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedTOSLabel)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.tosLabel addGestureRecognizer:gestureRecognizer];

    self.siteTitle.placeholder = NSLocalizedString(@"Site Title", @"NUX Create Account Page 2 Site Title Placeholder");
    self.siteTitle.font = [WPNUXUtility textFieldFont];
    
    self.siteAddress.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
    self.siteAddress.font = [WPNUXUtility textFieldFont];
    
    _currentLanguage = [WPComLanguages currentLanguage];
    self.siteLanguage.text = [_currentLanguage objectForKey:@"name"];
    self.siteLanguage.font = [WPNUXUtility textFieldFont];
    
    // Add tap gesture recognizer to view so we can detect if the user has tapped on the general area of the site language textfield.
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedView:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    [self.previousButton setTitle:NSLocalizedString(@"Previous", nil) forState:UIControlStateNormal];
    
    [self.nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
    self.nextButton.enabled = false;
    
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_hasDefaultSiteUrlBeenSet) {
        _hasDefaultSiteUrlBeenSet = true;
        self.siteAddress.text = _defaultSiteUrl;
    }
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.tosLabel;
}

- (IBAction)clickedNext:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage2Next];
    
    [self.view endEditing:YES];
    
    if (![self page2FieldsValid]) {
        [self showFieldsNotFilledError];
        return;
    }
    
    if (_page2FieldsValid) {
        if (self.onClickedNext != nil) {
            self.onClickedNext();
        }
    } else {
        // Check if user changed default URL and if so track the stat for it.
        if (![self.siteAddress.text isEqualToString:_defaultSiteUrl]) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountChangedDefaultURL];
        }
        
        self.nextButton.enabled = NO;
        [self validateSiteFields];
    }
}

- (IBAction)clickedPrevious:(id)sender
{
    if (self.onClickedPrevious != nil) {
        self.onClickedPrevious();
    }
}


- (void)setDefaultSiteAddress:(NSString *)address
{
    if ([[self.siteAddress.text trim] length] == 0) {
        _hasDefaultSiteUrlBeenSet = false;
        _defaultSiteUrl = address;
        self.siteAddress.text = address;
    }
}

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.siteTitle) {
        [self.siteAddress becomeFirstResponder];
    } else if (textField == self.siteAddress) {
        if (self.nextButton.enabled) {
            [self clickedNext:nil];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _page2FieldsValid = false;
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    
    BOOL isSiteTitleFilled = [self isSiteTitleFilled];
    BOOL isSiteAddressFilled = [self isSiteAddressFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    
    if (textField == self.siteTitle) {
        isSiteTitleFilled = updatedStringHasContent;
    } else if (textField == self.siteAddress) {
        isSiteAddressFilled = updatedStringHasContent;
    }
    
    self.nextButton.enabled = isSiteTitleFilled && isSiteAddressFilled;
    
    return YES;
}


#pragma mark - Keyboard Related

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardOffset = (CGRectGetMaxY([self.nextButton convertRect:self.nextButton.frame toView:self.view]) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(self.nextButton.frame);
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.verticalCenteringConstraint.constant -= _keyboardOffset;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.verticalCenteringConstraint.constant += _keyboardOffset;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Private Method

- (void)tappedOnBackground:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

- (void)tappedTOSLabel
{
    [self.view endEditing:YES];
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:[NSURL URLWithString:@"http://en.wordpress.com/tos/"]];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)tappedView:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self.view];
    BOOL clickedSiteLanguage = CGRectContainsPoint(self.siteLanguage.frame, touchPoint);
    
    if (clickedSiteLanguage) {
        [self showLanguagePicker];
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
    self.siteLanguage.text = [_currentLanguage objectForKey:@"name"];
    _page2FieldsValid = false;
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
    return ([[self.siteTitle.text trim] length] != 0);
}

- (BOOL)isSiteAddressFilled
{
    return ([[self.siteAddress.text trim] length] != 0);
}

- (NSString *)getSiteAddressWithoutWordPressDotCom
{
    NSRegularExpression *dotCom = [NSRegularExpression regularExpressionWithPattern:@"\\.wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    return [dotCom stringByReplacingMatchesInString:self.siteAddress.text options:0 range:NSMakeRange(0, [self.siteAddress.text length]) withTemplate:@""];
}

- (void)validateSiteFields
{
    NSString *siteAddress = [self getSiteAddressWithoutWordPressDotCom];
    NSString *siteTitle = self.siteTitle.text;

    void (^blogValidationSuccess)(id) = ^(id responseObject) {
        self.nextButton.enabled = YES;
        [SVProgressHUD dismiss];
        _page2FieldsValid = true;
        if (self.onValidatedSiteFields != nil) {
            self.onValidatedSiteFields(siteAddress, siteTitle, _currentLanguage);
        }
        if (self.onClickedNext != nil) {
            self.onClickedNext();
        }
    };
    void (^blogValidationFailure)(NSError *) = ^(NSError *error) {
        self.nextButton.enabled = YES;
        [SVProgressHUD dismiss];
        [self showRemoteError:error];
    };
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Validating Site Data", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    [[WordPressComApi sharedApi] validateWPComBlogWithUrl:siteAddress
                                             andBlogTitle:siteAddress
                                            andLanguageId:[_currentLanguage objectForKey:@"lang_id"]
                                                  success:blogValidationSuccess
                                                  failure:blogValidationFailure];
}

- (void)clickedPage2PreviousButton
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage2Previous];
    
    if (self.onClickedPrevious != nil) {
        self.onClickedPrevious();
    }
    
    [self.view endEditing:YES];
}

- (void)showFieldsNotFilledError
{
    [self showError:NSLocalizedString(@"Please fill out all the fields", nil)];
}

- (void)showRemoteError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    [self showError:errorMessage];
}

- (void)showError:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [[NewWPWalkthroughOverlayView alloc] initWithFrame:self.containingView.bounds];
    overlayView.overlayMode = NewWPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    overlayView.overlayTitle = NSLocalizedString(@"Error", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    overlayView.singleTapCompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.containingView addSubview:overlayView];
}


@end
