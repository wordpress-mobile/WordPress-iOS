#import "LoginViewModel.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <WPXMLRPC/WPXMLRPC.h>

#import "AccountServiceFacade.h"
#import "BlogSyncFacade.h"
#import "Constants.h"
#import "HelpshiftEnabledFacade.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "NSURL+IDN.h"
#import "OnePasswordFacade.h"
#import "ReachabilityFacade.h"
#import "WPWalkthroughOverlayView.h"

@implementation LoginViewModel

static CGFloat const LoginViewModelAlphaHidden = 0.0f;
static CGFloat const LoginViewModelAlphaDisabled = 0.5f;
static CGFloat const LoginViewModelAlphaEnabled = 1.0f;
static NSString *const ForgotPasswordDotComBaseUrl = @"https://wordpress.com";
static NSString *const ForgotPasswordRelativeUrl = @"/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F";

- (instancetype)init
{
    if (self = [super init]) {
        [self initializeFacades];
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializeFacades
{
    LoginFacade *loginFacade = [LoginFacade new];
    loginFacade.delegate = self;
    _loginFacade = loginFacade;
    _reachabilityFacade = [ReachabilityFacade new];
    _accountServiceFacade = [AccountServiceFacade new];
    _blogSyncFacade = [BlogSyncFacade new];
    _helpshiftEnabledFacade = [HelpshiftEnabledFacade new];
    _onePasswordFacade = [OnePasswordFacade new];
}

- (void)setup
{
    [self setupObservationForAuthenticating];
    [self setupObservationForShouldDisplayMultifactor];
    [self setupObserationForUsernameEnabled];
    [self setupObservationForPasswordEnabled];
    [self setupObservationForUserIsDotCom];
    [self setupObservationForIsSiteUrlEnabled];
    [self setupObservationForIsMultifactorEnabled];
    [self setupObservationForCancellable];
    [self setupObservationForForgotPasswordButtonVisibility];
    [self setupObservationForTheSendVerificationCodeButtonVisibility];
    [self setupObservationForTheAccountCreationButtonsVisibility];
    [self setupObservationForSignInButtonTitle];
    [self setupObserverationForTheSignInButtonsEnabledState];
    [self setupObserverationForTheToggleSignInButtonsVisibility];
    [self setupObservationForApplicationDidEnterBackground];
}

- (LoginFields *)loginFields
{
    // Do not return the Multifactor Code, unless the field is actually onscreen!
    NSString *multifactorCode = self.isMultifactorEnabled ? self.multifactorCode : nil;
    return [LoginFields loginFieldsWithUsername:self.username password:self.password siteUrl:self.siteUrl multifactorCode:multifactorCode userIsDotCom:self.userIsDotCom shouldDisplayMultiFactor:self.shouldDisplayMultifactor];
}

- (void)signInButtonAction
{
    if (![self.reachabilityFacade isInternetReachable]) {
        [self.reachabilityFacade showAlertNoInternetConnection];
        return;
    }
    
    LoginFields *loginFields = [self loginFields];
    if (![self areFieldsValid:loginFields]) {
        [self.presenter displayErrorMessageForInvalidOrMissingFields];
        return;
    }
    
    if (loginFields.userIsDotCom && [self isUsernameReserved:loginFields.username]) {
        [self.presenter displayReservedNameErrorMessage];
        [self toggleSignInFormAction];
        [self.presenter setFocusToSiteUrlText];
        return;
    }
   
    [self.loginFacade signInWithLoginFields:loginFields];
}

- (void)onePasswordButtonActionForViewController:(UIViewController *)viewController sender:(id)sender
{
    [self.presenter endViewEditing];
    
    if (self.userIsDotCom == false && self.siteUrl.isEmpty) {
        [self.presenter displayOnePasswordEmptySiteAlert];
        return;
    }
 
    NSString *loginURL = self.userIsDotCom ? WPOnePasswordWordPressComURL : self.siteUrl;
    
    [self.onePasswordFacade findLoginForURLString:loginURL viewController:viewController sender:sender completion:^(NSString *username, NSString *password, NSString *oneTimePassword, NSError *error) {
        BOOL blankUsernameOrPassword = (username.length == 0) || (password.length == 0);
        if (blankUsernameOrPassword || (error != nil)) {
            if (error != nil) {
                DDLogError(@"OnePassword Error: %@", error);
                [WPAnalytics track:WPAnalyticsStatOnePasswordFailed];
            }
            return;
        }
        
        self.username = username;
        self.password = password;
        self.multifactorCode = oneTimePassword;
        
        [self.presenter setUsernameTextValue:username];
        [self.presenter setPasswordTextValue:password];
        [self.presenter setMultifactorTextValue:oneTimePassword];
        
        if (oneTimePassword) {
            self.isMultifactorEnabled = YES;
        }
        
        [WPAnalytics track:WPAnalyticsStatOnePasswordLogin];
        [self signInButtonAction];
    }];
}

- (void)forgotPasswordButtonAction
{
    NSString *baseUrl = self.userIsDotCom ? ForgotPasswordDotComBaseUrl : [self baseSiteUrl];
    NSURL *forgotPasswordURL = [NSURL URLWithString:[baseUrl stringByAppendingString:ForgotPasswordRelativeUrl]];
    
    [self.presenter openURLInSafari:forgotPasswordURL];
}

- (NSString *)baseSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:self.siteUrl]];
    NSString *url = [siteURL absoluteString];

    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if (url.isWordPressComPath) {
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

- (BOOL)isUsernameReserved:(NSString *)username
{
    NSArray *reservedUserNames = @[@"admin",@"administrator",@"root"];
    return [reservedUserNames containsObject:[[username trim] lowercaseString]];
}

- (void)toggleSignInFormAction
{
    self.shouldDisplayMultifactor = NO;
    self.userIsDotCom = !self.userIsDotCom;
    
    [self.presenter reloadInterfaceWithAnimation:YES];
}

- (void)displayMultifactorTextField
{
    self.shouldDisplayMultifactor = YES;
    [self.presenter reloadInterfaceWithAnimation:YES];
    [self.presenter setFocusToMultifactorText];
}

- (BOOL)isOnePasswordEnabled
{
    return [self.onePasswordFacade isOnePasswordEnabled];
}

- (void)requestOneTimeCode
{
    NSString *message = NSLocalizedString(@"SMS Sent", @"One Time Code has been sent via SMS");
    [self.presenter showAlertWithMessage:message];
    [self.loginFacade requestOneTimeCodeWithLoginFields:[self loginFields]];
}

- (BOOL)areFieldsValid:(LoginFields *)loginFields
{
    if ([self areSelfHostedFieldsFilled:loginFields] && !loginFields.userIsDotCom) {
        return [self isUrlValid:loginFields.siteUrl];
    }
    
    return [self areDotComFieldsFilled:loginFields];
}

- (void)setupObservationForAuthenticating
{
    [RACObserve(self, authenticating) subscribeNext:^(NSNumber *authenticating) {
        [self.presenter showActivityIndicator:[authenticating boolValue]];
    }];
}

- (void)setupObservationForShouldDisplayMultifactor {
    [RACObserve(self, shouldDisplayMultifactor) subscribeNext:^(NSNumber *shouldDisplayMultifactor) {
        BOOL displayMultifactor = [shouldDisplayMultifactor boolValue];
        if (displayMultifactor) {
            [self.presenter setUsernameAlpha:LoginViewModelAlphaDisabled];
            [self.presenter setPasswordAlpha:LoginViewModelAlphaDisabled];
            [self.presenter setMultiFactorAlpha:LoginViewModelAlphaEnabled];
        } else {
            [self.presenter setUsernameAlpha:LoginViewModelAlphaEnabled];
            [self.presenter setPasswordAlpha:LoginViewModelAlphaEnabled];
            [self.presenter setMultiFactorAlpha:LoginViewModelAlphaHidden];
        }
        
        self.isUsernameEnabled = !displayMultifactor;
        self.isPasswordEnabled = !displayMultifactor;
        self.isMultifactorEnabled = displayMultifactor;
    }];
}

- (void)setupObserationForUsernameEnabled
{
    [RACObserve(self, isUsernameEnabled) subscribeNext:^(NSNumber *isUsernameEnabled) {
        [self.presenter setUsernameEnabled:[isUsernameEnabled boolValue]];
    }];
}

- (void)setupObservationForPasswordEnabled
{
    [RACObserve(self, isPasswordEnabled) subscribeNext:^(NSNumber *isPasswordEnabled) {
        [self.presenter setPasswordEnabled:[isPasswordEnabled boolValue]];
    }];
}

- (void)setupObservationForUserIsDotCom
{
    [RACObserve(self, userIsDotCom) subscribeNext:^(NSNumber *userIsDotCom) {
        BOOL dotComUser = [userIsDotCom boolValue];
        self.isSiteUrlEnabled = !dotComUser;
    }];
}

- (void)setupObservationForIsSiteUrlEnabled
{
    [[RACSignal combineLatest:@[RACObserve(self, isSiteUrlEnabled), RACObserve(self, userIsDotCom), RACObserve(self, shouldDisplayMultifactor)]] subscribeNext:^(RACTuple *values) {
        BOOL isSiteUrlEnabled = [[values first] boolValue];
        BOOL userIsDotcom = [[values second] boolValue];
        BOOL shouldDisplayMultifactor = [[values third] boolValue];
        
        if (isSiteUrlEnabled) {
            if (shouldDisplayMultifactor) {
                [self.presenter setSiteAlpha:LoginViewModelAlphaDisabled];
            } else {
                [self.presenter setSiteAlpha:LoginViewModelAlphaEnabled];
            }
        } else {
            [self.presenter setSiteAlpha:LoginViewModelAlphaHidden];
        }
        [self.presenter setSiteUrlEnabled:isSiteUrlEnabled];
        
        
        if (userIsDotcom) {
            [self.presenter setPasswordTextReturnKeyType:UIReturnKeyDone];
            [self.presenter setToggleSignInButtonTitle:NSLocalizedString(@"Add Self-Hosted Site", nil)];
        } else {
            [self.presenter setPasswordTextReturnKeyType:UIReturnKeyNext];
            [self.presenter setToggleSignInButtonTitle:NSLocalizedString(@"Sign in to WordPress.com", nil)];
        }
    }];
}

- (void)setupObservationForIsMultifactorEnabled
{
    [RACObserve(self, isMultifactorEnabled) subscribeNext:^(NSNumber *isMultifactorEnabled) {
        [self.presenter setMultifactorEnabled:[isMultifactorEnabled boolValue]];
    }];
}

- (void)setupObservationForCancellable
{
    [RACObserve(self, cancellable) subscribeNext:^(NSNumber *cancellable) {
        [self.presenter setCancelButtonHidden:![cancellable boolValue]];
    }];
}

- (void)setupObservationForForgotPasswordButtonVisibility
{
    [[[RACSignal combineLatest:@[RACObserve(self, userIsDotCom), RACObserve(self, siteUrl), RACObserve(self, authenticating), RACObserve(self, isMultifactorEnabled)]] reduceEach:^id(NSNumber *userIsDotCom, NSString *siteUrl, NSNumber *authenticating, NSNumber *isMultifactorEnabled){
        BOOL isEnabled = [userIsDotCom boolValue] || [self isUrlValid:siteUrl];
        return @(!isEnabled || [authenticating boolValue] || [isMultifactorEnabled boolValue]);
    }] subscribeNext:^(NSNumber *forgotPasswordHidden) {
        [self.presenter setForgotPasswordHidden:[forgotPasswordHidden boolValue]];
    }];
}

- (void)setupObservationForTheSendVerificationCodeButtonVisibility
{
    [[[RACSignal combineLatest:@[RACObserve(self, shouldDisplayMultifactor), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *shouldDisplayMultifactor, NSNumber *authenticating){
        return @(![shouldDisplayMultifactor boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *sendVerificationCodeButtonHidden) {
        [self.presenter setSendVerificationCodeButtonHidden:[sendVerificationCodeButtonHidden boolValue]];
    }];
}

- (void)setupObservationForTheAccountCreationButtonsVisibility
{
    [[[RACSignal combineLatest:@[RACObserve(self, hasDefaultAccount), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *hasDefaultAccount, NSNumber *authenticating){
        return @([hasDefaultAccount boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *accountCreationHidden) {
        [self.presenter setAccountCreationButtonHidden:[accountCreationHidden boolValue]];
    }];
}

- (void)setupObservationForSignInButtonTitle
{
    [[[RACSignal combineLatest:@[RACObserve(self, shouldDisplayMultifactor), RACObserve(self, userIsDotCom)]] reduceEach:^id(NSNumber *shouldDisplayMultifactor, NSNumber *userIsDotCom){
        if ([shouldDisplayMultifactor boolValue]) {
            return NSLocalizedString(@"Verify", @"Button title for Two Factor code verification");
        } else if ([userIsDotCom boolValue]) {
            return NSLocalizedString(@"Sign In", @"Button title for Sign In Action");
        }
        
        return NSLocalizedString(@"Add Site", @"Button title for Add SelfHosted Site");
    }] subscribeNext:^(NSString *signInButtonTitle) {
        [self.presenter setSignInButtonTitle:signInButtonTitle];
    }];
}

- (void)setupObserverationForTheSignInButtonsEnabledState
{
    [[[RACSignal combineLatest:@[RACObserve(self, userIsDotCom), RACObserve(self, username), RACObserve(self, password), RACObserve(self, siteUrl), RACObserve(self, multifactorCode), RACObserve(self, shouldDisplayMultifactor)]] reduceEach:^id(NSNumber *userIsDotCom, NSString *username, NSString *password, NSString *siteUrl, NSString *multifactorCode, NSNumber *shouldDisplayMultifactor){
        LoginFields *loginFields = [LoginFields loginFieldsWithUsername:username password:password siteUrl:siteUrl multifactorCode:multifactorCode userIsDotCom:[userIsDotCom boolValue] shouldDisplayMultiFactor:[shouldDisplayMultifactor boolValue]];
        
        if ([userIsDotCom boolValue]) {
            return @([self areDotComFieldsFilled:loginFields]);
        } else {
            return @([self areSelfHostedFieldsFilled:loginFields]);
        }
    }] subscribeNext:^(NSNumber *signInButtonEnabled) {
        [self.presenter setSignInButtonEnabled:[signInButtonEnabled boolValue]];
    }];
}

- (void)setupObserverationForTheToggleSignInButtonsVisibility
{
    [[[RACSignal combineLatest:@[RACObserve(self, onlyDotComAllowed), RACObserve(self, hasDefaultAccount), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *onlyDotComAllowed, NSNumber *hasDefaultAccount, NSNumber *authenticating){
        return @([onlyDotComAllowed boolValue] || [hasDefaultAccount boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *toggleSignInButtonHidden) {
        [self.presenter setToggleSignInButtonHidden:[toggleSignInButtonHidden boolValue]];
    }];
}

- (void)setupObservationForApplicationDidEnterBackground
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [self.presenter setPasswordSecureEntry:YES];
}

- (BOOL)isUrlValid:(NSString *)url
{
    if (url.length == 0) {
        return NO;
    }
    
    NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:url]];
    return siteURL != nil;
}

- (BOOL)areDotComFieldsFilled:(LoginFields *)loginFields
{
    BOOL areCredentialsFilled = [self isUsernameFilled:loginFields.username] && [self isPasswordFilled:loginFields.password];
    
    if (!loginFields.shouldDisplayMultifactor) {
        return areCredentialsFilled;
    }
    
    return areCredentialsFilled && [self isMultifactorFilled:loginFields.multifactorCode];
}

- (BOOL)isUsernameFilled:(NSString *)username
{
    return [username trim].length != 0;
}

- (BOOL)isPasswordFilled:(NSString *)password
{
    return [password trim].length != 0;
}

- (BOOL)isMultifactorFilled:(NSString *)multifactorCode
{
    return multifactorCode.isEmpty == NO;
}

- (BOOL)areSelfHostedFieldsFilled:(LoginFields *)loginFields
{
    return [self areDotComFieldsFilled:loginFields] && [self isSiteUrlFilled:loginFields.siteUrl];
}

- (BOOL)isSiteUrlFilled:(NSString *)siteUrl
{
    return [siteUrl trim].length != 0;
}

- (void)dismissLoginMessage
{
    [self.presenter dismissLoginMessage];
}

- (void)finishedLogin
{
    [self.presenter dismissLoginView];
}

#pragma mark - LoginFacadeDelegate Related Methods

- (void)displayLoginMessage:(NSString *)message
{
    [self.presenter displayLoginMessage:message];
}

- (void)needsMultifactorCode
{
    [self dismissLoginMessage];
    [self displayMultifactorTextField];
}

- (void)displayRemoteError:(NSError *)error
{
    DDLogError(@"%@", error);
    
    [self.presenter dismissLoginMessage];
    
    NSString *message = [error localizedDescription];
    if (![[error domain] isEqualToString:WPXMLRPCFaultErrorDomain] && [error code] != NSURLErrorBadURL) {
        if ([self.helpshiftEnabledFacade isHelpshiftEnabled]) {
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

- (void)finishedLoginWithUsername:(NSString *)username authToken:(NSString *)authToken requiredMultifactorCode:(BOOL)requiredMultifactorCode
{
    [self dismissLoginMessage];
    [self.presenter updateAutoFillLoginCredentialsIfNeeded:username password:self.password];
    
    if (self.shouldReauthenticateDefaultAccount) {
        [self.accountServiceFacade removeLegacyAccount:username];
    }
    
    [self createWordPressComAccountForUsername:username authToken:authToken requiredMultifactorCode:requiredMultifactorCode];
}

- (void)finishedLoginWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options
{
    [self dismissLoginMessage];
    [self createSelfHostedBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
}

- (void)createWordPressComAccountForUsername:(NSString *)username authToken:(NSString *)authToken requiredMultifactorCode:(BOOL)requiredMultifactorCode
{
    id failureHandler = ^(NSError *error) {
        [self dismissLoginMessage];
        [self displayRemoteError:error];
    };
    
    [self displayLoginMessage:NSLocalizedString(@"Getting account information", nil)];
    
    WPAccount *account = [self.accountServiceFacade createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
    [self.blogSyncFacade syncBlogsForAccount:account success:^{
        // once blogs for the accounts are synced, we want to update account details for it
        [self.accountServiceFacade updateUserDetailsForAccount:account success:^{
            // Dismiss the UI
            [self dismissLoginMessage];
            [self finishedLogin];
            
            // Hit the Tracker
            NSDictionary *properties = @{
                                         @"multifactor" : @(requiredMultifactorCode),
                                         @"dotcom_user" : @(YES)
                                         };
            
            [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:properties];
            [WPAnalytics refreshMetadata];
        } failure:failureHandler];
    } failure:failureHandler];
}


- (void)createSelfHostedBlogWithUsername:(NSString *)username
                                password:(NSString *)password
                                  xmlrpc:(NSString *)xmlrpc
                                 options:(NSDictionary *)options
{
    [self.blogSyncFacade syncBlogWithUsername:username password:password xmlrpc:xmlrpc options:options finishedSync:^{
        [self finishedLogin];
    }];
}

#pragma mark - Overlay View Related Methods

- (void)displayGenericErrorMessage:(NSString *)message
{
    OverlayViewCallback secondButtonCallback = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
        [self.presenter displayHelpViewControllerWithAnimation:NO];
    };
    
    [self displayOverlayViewWithMessage:message firstButtonText:nil firstButtonCallback:nil secondButtonText:nil secondButtonCallback:secondButtonCallback accessibilityIdentifier:@"GenericErrorMessage"];
}


- (void)displayGenericErrorMessageWithHelpshiftButton:(NSString *)message
{
    NSString *secondButtonText = NSLocalizedString(@"Contact Us", @"The text on the button at the bottom of the ""error message when a user has repeated trouble logging in");
    
    OverlayViewCallback secondButtonCallback = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
        [self.presenter displayHelpshiftConversationView];
    };
    
    [self displayOverlayViewWithMessage:message firstButtonText:nil firstButtonCallback:nil secondButtonText:secondButtonText secondButtonCallback:secondButtonCallback accessibilityIdentifier:nil];
}

- (void)displayErrorMessageForXMLRPC:(NSString *)message
{
    NSString *firstButtonText = NSLocalizedString(@"Enable Now", nil);
    OverlayViewCallback firstButtonCallback = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
        
        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSRange rng = [regex rangeOfFirstMatchInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (rng.location == NSNotFound) {
            path = self.baseSiteUrl;
            path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
            path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
        } else {
            path = [message substringWithRange:rng];
        }
        
        [self.presenter displayWebViewForURL:[NSURL URLWithString:path] username:self.username password:self.password];
    };
    OverlayViewCallback secondButtonCallback = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
        [self.presenter displayHelpViewControllerWithAnimation:NO];
    };
    
    [self displayOverlayViewWithMessage:message firstButtonText:firstButtonText firstButtonCallback:firstButtonCallback secondButtonText:nil secondButtonCallback:secondButtonCallback accessibilityIdentifier:nil];
}

- (void)displayErrorMessageForBadUrl:(NSString *)message
{
    OverlayViewCallback secondButtonCallback = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
        [self.presenter displayWebViewForURL:[NSURL URLWithString:@"https://apps.wordpress.org/support/#faq-ios-3"] username:nil password:nil];
    };
    
    [self displayOverlayViewWithMessage:message firstButtonText:nil firstButtonCallback:nil secondButtonText:nil secondButtonCallback:secondButtonCallback accessibilityIdentifier:nil];
}

- (void)displayOverlayViewWithMessage:(NSString *)message firstButtonText:(NSString *)firstButtonText firstButtonCallback:(OverlayViewCallback)firstButtonCallback secondButtonText:(NSString *)secondButtonText secondButtonCallback:(OverlayViewCallback)secondButtonCallback accessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    NSParameterAssert(message.length > 0);
    NSParameterAssert(secondButtonCallback != nil);
    
    NSString *firstButtonTextOrDefault = NSLocalizedString(@"OK", nil);
    NSString *secondButtonTextOrDefault = NSLocalizedString(@"Need Help?", nil);
    
    OverlayViewCallback firstButtonCallbackOrDefault = ^(WPWalkthroughOverlayView *overlayView) {
        [overlayView dismiss];
    };
    
    if (firstButtonCallback != nil) {
        firstButtonCallbackOrDefault = firstButtonCallback;
    }
    
    if (firstButtonText.length > 0) {
        firstButtonTextOrDefault = firstButtonText;
    }
    
    if (secondButtonText.length > 0) {
        secondButtonTextOrDefault = secondButtonText;
    }
    
    [self.presenter displayOverlayViewWithMessage:message firstButtonText:firstButtonTextOrDefault firstButtonCallback:firstButtonCallbackOrDefault secondButtonText:secondButtonTextOrDefault secondButtonCallback:secondButtonCallback accessibilityIdentifier:accessibilityIdentifier];
}

@end
