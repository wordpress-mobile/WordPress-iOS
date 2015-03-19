#import "LoginViewModel.h"
#import "AccountCreationService.h"
#import "BlogSyncService.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "NSURL+IDN.h"
#import "ReachabilityService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface LoginViewModel()

@property (nonatomic, strong) NSString *signInButtonTitle;

@end

@implementation LoginViewModel

static CGFloat const LoginViewModelAlphaHidden              = 0.0f;
static CGFloat const LoginViewModelAlphaDisabled            = 0.5f;
static CGFloat const LoginViewModelAlphaEnabled             = 1.0f;

- (instancetype)init
{
    if (self = [super init]) {
        [self initializeServices];
        [self setup];
    }
    return self;
}

- (void)initializeServices
{
    LoginService *loginService = [LoginService new];
    loginService.delegate = self;
    _loginService = loginService;
    
    _reachabilityService = [ReachabilityService new];
    _accountCreationService = [AccountCreationService new];
    _blogSyncService = [BlogSyncService new];
}

- (void)setup
{
    // TODO : Set default values to kick off this logic
    [RACObserve(self, authenticating) subscribeNext:^(NSNumber *authenticating) {
        [self.delegate showActivityIndicator:[authenticating boolValue]];
    }];
    
    [RACObserve(self, shouldDisplayMultifactor) subscribeNext:^(NSNumber *shouldDisplayMultifactor) {
        [self handleShouldDisplayMultifactorChanged:shouldDisplayMultifactor];
    }];
    
    [RACObserve(self, isUsernameEnabled) subscribeNext:^(NSNumber *isUsernameEnabled) {
        [self.delegate setUsernameEnabled:[isUsernameEnabled boolValue]];
    }];
    
    [RACObserve(self, isPasswordEnabled) subscribeNext:^(NSNumber *isPasswordEnabled) {
        [self.delegate setPasswordEnabled:[isPasswordEnabled boolValue]];
    }];
    
    [RACObserve(self, userIsDotCom) subscribeNext:^(NSNumber *userIsDotCom) {
        BOOL dotComUser = [userIsDotCom boolValue];
        
        self.isSiteUrlEnabled = !dotComUser;
        
        if (dotComUser) {
            [self.delegate setToggleSignInButtonTitle:NSLocalizedString(@"Add Self-Hosted Site", nil)];
        } else {
            [self.delegate setToggleSignInButtonTitle:NSLocalizedString(@"Sign in to WordPress.com", nil)];
        }
    }];
    
    [RACObserve(self, isSiteUrlEnabled) subscribeNext:^(NSNumber *isSiteUrlEnabled) {
        [self handleSiteUrlEnabledChanged:isSiteUrlEnabled];
    }];
    
    [RACObserve(self, isMultifactorEnabled) subscribeNext:^(NSNumber *isMultifactorEnabled) {
        [self.delegate setMultifactorEnabled:[isMultifactorEnabled boolValue]];
    }];
    
    [RACObserve(self, cancellable) subscribeNext:^(NSNumber *cancellable) {
        [self.delegate setCancelButtonHidden:![cancellable boolValue]];
    }];
    
    // Setup monitoring for whether to show/hide the forgot password button
    [[[RACSignal combineLatest:@[RACObserve(self, userIsDotCom), RACObserve(self, siteUrl), RACObserve(self, authenticating), RACObserve(self, isMultifactorEnabled)]] reduceEach:^id(NSNumber *userIsDotCom, NSString *siteUrl, NSNumber *authenticating, NSNumber *isMultifactorEnabled){
        BOOL isEnabled = [userIsDotCom boolValue] || [self isUrlValid:siteUrl];
        return @(!isEnabled || [authenticating boolValue] || [isMultifactorEnabled boolValue]);
    }] subscribeNext:^(NSNumber *forgotPasswordHidden) {
        [self.delegate setForgotPasswordHidden:[forgotPasswordHidden boolValue]];
    }];
    
    // Setup monitoring for whether to show/hide the send verification code button
    [[[RACSignal combineLatest:@[RACObserve(self, shouldDisplayMultifactor), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *shouldDisplayMultifactor, NSNumber *authenticating){
        return @(![shouldDisplayMultifactor boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *sendVerificationCodeButtonHidden) {
        [self.delegate setSendVerificationCodeButtonHidden:[sendVerificationCodeButtonHidden boolValue]];
    }];
    
    [self setupCreateAccountButton];
    [self setupSignInButtonTitle];
    [self setupSignInButtonEnabled];
    [self setupToggleSignInButtonHidden];
}

- (void)signInButtonAction
{
    if (![self.reachabilityService isInternetReachable]) {
        [self.reachabilityService showAlertNoInternetConnection];
        return;
    }
    
    LoginFields *loginFields = [LoginFields loginFieldsWithUsername:self.username password:self.password siteUrl:self.siteUrl multifactorCode:self.multifactorCode userIsDotCom:self.userIsDotCom shouldDisplayMultiFactor:self.shouldDisplayMultifactor];
    if (![self areFieldsValid:loginFields]) {
        [self.delegate displayErrorMessageForInvalidOrMissingFields];
        return;
    }
    
    if (loginFields.userIsDotCom && [self isUsernameReserved:loginFields.username]) {
        [self.delegate displayReservedNameErrorMessage];
        [self toggleSignInFormAction];
        [self.delegate setFocusToSiteUrlText];
        return;
    }
   
    [self.loginService signInWithLoginFields:loginFields];
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
    
    if (self.userIsDotCom) {
        [self.delegate setPasswordTextReturnKeyType:UIReturnKeyDone];
    } else {
        [self.delegate setPasswordTextReturnKeyType:UIReturnKeyNext];
    }
    
    [self.delegate reloadInterfaceWithAnimation:YES];
}

- (void)displayMultifactorTextField
{
    self.shouldDisplayMultifactor = YES;
    [self.delegate reloadInterfaceWithAnimation:YES];
    [self.delegate setFocusToMultifactorText];
}

- (BOOL)areFieldsValid:(LoginFields *)loginFields
{
    if ([self areSelfHostedFieldsFilled:loginFields] && !loginFields.userIsDotCom) {
        return [self isUrlValid:loginFields.siteUrl];
    }
    
    return [self areDotComFieldsFilled:loginFields];
}

- (void)handleShouldDisplayMultifactorChanged:(NSNumber *)shouldDisplayMultifactor {
    BOOL displayMultifactor = [shouldDisplayMultifactor boolValue];
    if (displayMultifactor) {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaDisabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaDisabled];
        [self.delegate setMultiFactorAlpha:LoginViewModelAlphaEnabled];
    } else {
        [self.delegate setUsernameAlpha:LoginViewModelAlphaEnabled];
        [self.delegate setPasswordAlpha:LoginViewModelAlphaEnabled];
        [self.delegate setMultiFactorAlpha:LoginViewModelAlphaHidden];
    }
    
    self.isUsernameEnabled = !displayMultifactor;
    self.isPasswordEnabled = !displayMultifactor;
    self.isMultifactorEnabled = displayMultifactor;
}

- (void)handleSiteUrlEnabledChanged:(NSNumber *)isSiteUrlEnabled
{
    BOOL siteUrlEnabled = [isSiteUrlEnabled boolValue];
    if (siteUrlEnabled) {
        if (self.shouldDisplayMultifactor) {
            [self.delegate setSiteAlpha:LoginViewModelAlphaDisabled];
        } else {
            [self.delegate setSiteAlpha:LoginViewModelAlphaEnabled];
        }
    } else {
        [self.delegate setSiteAlpha:LoginViewModelAlphaHidden];
    }
    [self.delegate setSiteUrlEnabled:siteUrlEnabled];
}

- (void)setupCreateAccountButton
{
    [[[RACSignal combineLatest:@[RACObserve(self, hasDefaultAccount), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *hasDefaultAccount, NSNumber *authenticating){
        return @([hasDefaultAccount boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *accountCreationHidden) {
        [self.delegate setAccountCreationButtonHidden:[accountCreationHidden boolValue]];
    }];
}

- (void)setupSignInButtonTitle
{
    [[[RACSignal combineLatest:@[RACObserve(self, shouldDisplayMultifactor), RACObserve(self, userIsDotCom)]] reduceEach:^id(NSNumber *shouldDisplayMultifactor, NSNumber *userIsDotCom){
        if ([shouldDisplayMultifactor boolValue]) {
            return NSLocalizedString(@"Verify", @"Button title for Two Factor code verification");
        } else if ([userIsDotCom boolValue]) {
            return NSLocalizedString(@"Sign In", @"Button title for Sign In Action");
        }
        
        return NSLocalizedString(@"Add Site", @"Button title for Add SelfHosted Site");
    }] subscribeNext:^(NSString *signInButtonTitle) {
        self.signInButtonTitle = signInButtonTitle;
        [self.delegate setSignInButtonTitle:signInButtonTitle];
    }];
}

- (void)setupSignInButtonEnabled
{
    [[[RACSignal combineLatest:@[RACObserve(self, userIsDotCom), RACObserve(self, username), RACObserve(self, password), RACObserve(self, siteUrl), RACObserve(self, multifactorCode), RACObserve(self, shouldDisplayMultifactor)]] reduceEach:^id(NSNumber *userIsDotCom, NSString *username, NSString *password, NSString *siteUrl, NSString *multifactorCode, NSNumber *shouldDisplayMultifactor){
        LoginFields *loginFields = [LoginFields loginFieldsWithUsername:username password:password siteUrl:siteUrl multifactorCode:multifactorCode userIsDotCom:[userIsDotCom boolValue] shouldDisplayMultiFactor:[shouldDisplayMultifactor boolValue]];
        
        if ([userIsDotCom boolValue]) {
            return @([self areDotComFieldsFilled:loginFields]);
        } else {
            return @([self areSelfHostedFieldsFilled:loginFields]);
        }
    }] subscribeNext:^(NSNumber *signInButtonEnabled) {
        [self.delegate setSignInButtonEnabled:[signInButtonEnabled boolValue]];
    }];
}

- (void)setupToggleSignInButtonHidden
{
    [[[RACSignal combineLatest:@[RACObserve(self, onlyDotComAllowed), RACObserve(self, hasDefaultAccount), RACObserve(self, authenticating)]] reduceEach:^id(NSNumber *onlyDotComAllowed, NSNumber *hasDefaultAccount, NSNumber *authenticating){
        return @([onlyDotComAllowed boolValue] || [hasDefaultAccount boolValue] || [authenticating boolValue]);
    }] subscribeNext:^(NSNumber *toggleSignInButtonHidden) {
        [self.delegate setToggleSignInButtonHidden:[toggleSignInButtonHidden boolValue]];
    }];
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
    [self.delegate dismissLoginMessage];
}

- (void)finishedLogin
{
    [self.delegate dismissLoginView];
}

#pragma LoginServiceDelegate methods

- (void)displayLoginMessage:(NSString *)message
{
    [self.delegate displayLoginMessage:message];
}

- (void)needsMultifactorCode
{
    [self dismissLoginMessage];
    [self displayMultifactorTextField];
}

- (void)displayRemoteError:(NSError *)error
{
    [self.delegate dismissLoginMessage];
    [self.delegate displayRemoteError:error];
}

- (void)showJetpackAuthentication
{
    [self.delegate showJetpackAuthentication];
}

- (void)finishedLoginWithUsername:(NSString *)username authToken:(NSString *)authToken shouldDisplayMultifactor:(BOOL)shouldDisplayMultifactor
{
    [self dismissLoginMessage];
    [self createWordPressComAccountForUsername:username authToken:authToken shouldDisplayMultifactor:shouldDisplayMultifactor];
}

- (void)finishedLoginWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options
{
    [self dismissLoginMessage];
    [self createSelfHostedAccountAndBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
}

- (void)createWordPressComAccountForUsername:(NSString *)username authToken:(NSString *)authToken shouldDisplayMultifactor:(BOOL)shouldDisplayMultifactor
{
    [self displayLoginMessage:NSLocalizedString(@"Getting account information", nil)];
    
    WPAccount *account = [self.accountCreationService createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];
    [self.blogSyncService syncBlogsForAccount:account success:^{
        // Dismiss the UI
        [self dismissLoginMessage];
        [self finishedLogin];
        
        // Hit the Tracker
        NSDictionary *properties = @{
                                     @"multifactor" : @(shouldDisplayMultifactor),
                                     @"dotcom_user" : @(YES)
                                     };
        
        [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:properties];
        [WPAnalytics refreshMetadata];
        
        // once blogs for the accounts are synced, we want to update account details for it
        [self.accountCreationService updateEmailAndDefaultBlogForWordPressComAccount:account];
    } failure:^(NSError *error) {
        [self dismissLoginMessage];
        [self displayRemoteError:error];
    }];
}


- (void)createSelfHostedAccountAndBlogWithUsername:(NSString *)username
                                          password:(NSString *)password
                                            xmlrpc:(NSString *)xmlrpc
                                           options:(NSDictionary *)options
{
    WPAccount *account = [self.accountCreationService createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
    [self.blogSyncService syncBlogForAccount:account username:username password:password xmlrpc:xmlrpc options:options needsJetpack:^{
        [self showJetpackAuthentication];
    } finishedSync:^{
        [self finishedLogin];
    }];
}

@end
