    //
//  CreateAccountAndBlogPage1ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import "CreateAccountAndBlogPage1ViewController.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"
#import "NewWPWalkthroughOverlayView.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"

@interface CreateAccountAndBlogPage1ViewController () <UITextFieldDelegate> {
    CGFloat _keyboardOffset;
    BOOL _page1FieldsValid;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *tosLabel;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *username;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *email;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *password;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;

@end

@implementation CreateAccountAndBlogPage1ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.email.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
    self.email.font = [WPNUXUtility textFieldFont];
    
    self.username.placeholder = NSLocalizedString(@"Username", nil);
    self.username.font = [WPNUXUtility textFieldFont];
    
    self.password.placeholder = NSLocalizedString(@"Password", nil);;
    self.password.font = [WPNUXUtility textFieldFont];
    
    [self.nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
    self.nextButton.enabled = NO;
    
    self.tosLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
    self.tosLabel.font = [WPNUXUtility tosLabelFont];
    self.tosLabel.layer.shadowRadius = 2.0;
    self.tosLabel.userInteractionEnabled = true;
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedTOSLabel)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.tosLabel addGestureRecognizer:gestureRecognizer];
    
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.email) {
        [self.username becomeFirstResponder];
    } else if (textField == self.username) {
        [self.password becomeFirstResponder];
    } else if (textField == self.password) {
        if (self.nextButton.enabled) {
            [self clickedNext:nil];
        }
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _page1FieldsValid = false;
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    
    BOOL isEmailFilled = [self isEmailedFilled];
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    
    if (textField == self.email) {
        isEmailFilled = updatedStringHasContent;
    } else if (textField == self.username) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == self.password) {
        isPasswordFilled = updatedStringHasContent;
    }
    
    self.nextButton.enabled = isEmailFilled && isUsernameFilled && isPasswordFilled;

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.nextButton.enabled = [self page1FieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.nextButton.enabled = [self page1FieldsFilled];
    return YES;
}


#pragma mark - Keyboard Related

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardOffset = (CGRectGetMaxY(self.nextButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(self.nextButton.frame);
    
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

#pragma mark - IBAction Methods

- (IBAction)clickedNext:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedPage1Next];
    
    [self.view endEditing:YES];
    
    if (![self page1FieldsValid]) {
        [self showPage1Errors];
        return;
    }
    
    if (_page1FieldsValid) {
        if (self.onClickedNext != nil) {
            self.onClickedNext();
        }
    } else {
        self.nextButton.enabled = NO;
        [self validateUserFields];
    }
}

#pragma mark - Private Methods

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

- (BOOL)page1FieldsFilled
{
    return [self isEmailedFilled] && [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)isEmailedFilled
{
    return ([[self.email.text trim] length] != 0);
}

- (BOOL)isUsernameFilled
{
    return ([[self.username.text trim] length] != 0);
}

- (BOOL)isUsernameUnderFiftyCharacters
{
    return [[self.username.text trim] length] <= 50;
}

- (BOOL)isPasswordFilled
{
    return ([[self.password.text trim] length] != 0);
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

- (void)validateUserFields
{
    NSString *email = self.email.text;
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    
    void (^userValidationSuccess)(id) = ^(id responseObject) {
        self.nextButton.enabled = YES;
        [SVProgressHUD dismiss];
        _page1FieldsValid = true;
        if (self.onValidatedUserFields != nil) {
            self.onValidatedUserFields(email, username, password);
        }
        if (self.onClickedNext != nil) {
            self.onClickedNext();
        }
    };
    
    void (^userValidationFailure)(NSError *) = ^(NSError *error){
        self.nextButton.enabled = YES;
        [SVProgressHUD dismiss];
        [self showRemoteError:error];
    };
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Validating User Data", nil) maskType:SVProgressHUDMaskTypeBlack];
    [[WordPressComApi sharedApi] validateWPComAccountWithEmail:email
                                                   andUsername:username
                                                   andPassword:password
                                                       success:userValidationSuccess
                                                       failure:userValidationFailure];
    
}
@end
