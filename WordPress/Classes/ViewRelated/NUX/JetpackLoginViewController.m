#import "JetpackLoginViewController.h"
#import "WPWebViewController.h"
#import "WPNUXErrorViewController.h"

#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPNUXUserView.h"
#import "WPNUXUtility.h"

#import "ContextManager.h"
#import "JetpackService.h"

#import "Blog.h"
#import "Blog+Jetpack.h"

@interface JetpackLoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet WPNUXUserView *userView;
@property (weak, nonatomic) IBOutlet WPWalkthroughTextField *userField;
@property (weak, nonatomic) IBOutlet WPWalkthroughTextField *passwordField;
@property (weak, nonatomic) IBOutlet WPNUXMainButton *signInButton;
@property (weak, nonatomic) IBOutlet WPNUXSecondaryButton *skipButton;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *learnMoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *lostPasswordLabel;
@end

@implementation JetpackLoginViewController

+ (instancetype)instantiate
{
    NSBundle *bundle = [NSBundle bundleForClass:[JetpackLoginViewController class]];
    return [[UIStoryboard storyboardWithName:@"JetpackLogin" bundle:bundle] instantiateInitialViewController];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateUserField];
    [self.skipButton setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateNormal];
    [self updateSkipButton];
    [self updateStringsForI18n];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Actions

- (IBAction)signIn:(id)sender
{
    [self endEditing:sender];
    [self.signInButton showActivityIndicator:YES];
    NSString *username = self.username ? self.username : self.userField.text;
    JetpackService *jetpackService = [[JetpackService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [jetpackService validateAndLoginWithUsername:username
                                        password:self.passwordField.text
                                          siteID:self.siteID
                                         success:^(WPAccount *account) {
                                             [self.signInButton showActivityIndicator:NO];
                                             if (self.completionBlock) {
                                                 self.completionBlock(account);
                                             }
                                         } failure:^(NSError *error) {
                                             [self.signInButton showActivityIndicator:NO];
                                             [self displayError:error];
                                         }];
}

- (IBAction)learnMore:(id)sender
{
    // FIXME: This URL is hardly relevant for a generic Jetpack login but it's the best we have so far
    NSURL *learnMoreURL = [NSURL URLWithString:@"https://apps.wordpress.org/support/#faq-ios-15"];
    [self openURL:learnMoreURL];
}

- (IBAction)lostPassword:(id)sender
{
    NSURL *lostPasswordURL = [NSURL URLWithString:@"https://wordpress.com/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F"];
    [self openURL:lostPasswordURL];
}

- (IBAction)endEditing:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)skip:(id)sender
{
    if (self.completionBlock) {
        self.completionBlock(nil);
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self signIn:nil];
    }

    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self isSignInEnabled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self isSignInEnabled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    BOOL isUsernameFilled = [self isUsernameFilled] || [self userProvided];
    BOOL isPasswordFilled = [self isPasswordFilled];

    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == self.userField) {
        isUsernameFilled = updatedStringHasContent || [self userProvided];
    } else if (textField == self.passwordField) {
        isPasswordFilled = updatedStringHasContent;
    }
    self.signInButton.enabled = isUsernameFilled && isPasswordFilled;

    return YES;
}

#pragma mark - Public Accessors

- (void)setUsername:(NSString *)username
{
    _username = [username copy];
    if (self.isViewLoaded) {
        [self updateUserField];
    }
}

- (void)setEmail:(NSString *)email
{
    _email = [email copy];
    if (self.isViewLoaded) {
        [self updateUserField];
    }
}

- (void)setBlog:(Blog *)blog
{
    self.username = [blog getOptionValue:@"jetpack_user_login"];
    self.email = [blog getOptionValue:@"jetpack_user_email"];
    self.siteID = [blog jetpackBlogID];
}

- (void)setCanBeSkipped:(BOOL)canBeSkipped
{
    _canBeSkipped = canBeSkipped;
    if (self.isViewLoaded) {
        [self updateSkipButton];
    }
}

#pragma mark - Private

- (BOOL)isSignInEnabled
{
    return [self userProvided] ? [self isPasswordFilled] : [self areUsernameAndPasswordFilled];
}

- (BOOL)areUsernameAndPasswordFilled
{
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)isUsernameFilled
{
    return [[self.userField.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[self.passwordField.text trim] length] != 0;
}

- (BOOL)userProvided
{
    return (self.email && self.username);
}

- (void)updateUserField
{
    if ([self userProvided]) {
        self.userView.username = self.username;
        self.userView.email = self.email;
        self.userView.hidden = NO;
        self.userField.hidden = YES;
    } else {
        self.userView.hidden = YES;
        self.userField.hidden = NO;
    }
}

- (void)updateSkipButton
{
    self.skipButton.hidden = !self.canBeSkipped;
}

/*
 This is only needed since our translation system currently doesn't translate storyboards
 */
- (void)updateStringsForI18n
{
    self.title = NSLocalizedString(@"Jetpack Manage", @"Title for the Jetpack Login view");
    self.messageLabel.text = NSLocalizedString(@"We need your WordPress.com password to unleash all the power of Jetpack Manage", @"Main message on Jetpack Manage login screen");
    self.learnMoreLabel.text = NSLocalizedString(@"Learn More", @"Link to more information on Jetpack Manage login screen");
    self.lostPasswordLabel.text = NSLocalizedString(@"Lost your password?", nil);
    [self.skipButton setTitle:NSLocalizedString(@"Skip", @"Button to skip the Jetpack Login screen") forState:UIControlStateNormal];
}

- (void)updateBottomLayoutConstraintWithNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGFloat animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedKeyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.window];
    UIViewAnimationCurve rawAnimationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationOptionsWithCurve = rawAnimationCurve << 16;

    self.bottomLayoutConstraint.constant = 20 + CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame);

    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | animationOptionsWithCurve
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:nil];
}

- (void)openURL:(NSURL *)url
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    [webViewController setUrl:url];
    [self.navigationController pushViewController:webViewController animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)displayError:(NSError *)error
{
    WPNUXErrorViewController *errorViewController = [[WPNUXErrorViewController alloc] initWithRemoteError:error];
    errorViewController.dismissCompletionBlock = ^(UIViewController *controller) {
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:errorViewController animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    [self updateBottomLayoutConstraintWithNotification:notification];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    [self updateBottomLayoutConstraintWithNotification:notification];
}

@end
