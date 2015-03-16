#import "LoginViewModel.h"
#import "NSURL+IDN.h"
#import "ReachabilityService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "NSString+Helpers.h"


@interface LoginFields : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *siteUrl;
@property (nonatomic, copy) NSString *multifactorCode;
@property (nonatomic, assign) BOOL userIsDotCom;
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;


+ (instancetype)loginFieldsWithUsername:(NSString *)username password:(NSString *)password siteUrl:(NSString *)siteUrl multifactorCode:(NSString *)multifactorCode userIsDotCom:(BOOL)userIsDotCom shouldDisplayMultiFactor:(BOOL)shouldDisplayMultifactor;

@end

@implementation LoginFields

+ (instancetype)loginFieldsWithUsername:(NSString *)username password:(NSString *)password siteUrl:(NSString *)siteUrl multifactorCode:(NSString *)multifactorCode userIsDotCom:(BOOL)userIsDotCom shouldDisplayMultiFactor:(BOOL)shouldDisplayMultifactor
{
    LoginFields *loginFields = [LoginFields new];
    loginFields.username = username;
    loginFields.password = password;
    loginFields.siteUrl = siteUrl;
    loginFields.multifactorCode = multifactorCode;
    loginFields.userIsDotCom = userIsDotCom;
    loginFields.shouldDisplayMultifactor = shouldDisplayMultifactor;
    
    return loginFields;
}

@end

@interface LoginViewModel()

@property (nonatomic, strong) NSString *signInButtonTitle;
@property (nonatomic, strong) id<ReachabilityService> reachabilityService;

@end

@implementation LoginViewModel

static CGFloat const LoginViewModelAlphaHidden              = 0.0f;
static CGFloat const LoginViewModelAlphaDisabled            = 0.5f;
static CGFloat const LoginViewModelAlphaEnabled             = 1.0f;

- (instancetype)initWithReachabilityService:(id<ReachabilityService>)reachabilityService
{
    
    if (self = [super init]) {
        _reachabilityService = reachabilityService;
        [self setup];
    }
    return self;
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
    
    [self.delegate signIn];
}

- (BOOL)isUsernameReserved:(NSString *)username
{
    NSArray *reservedUserNames = @[@"admin",@"administrator",@"root"];
    return [reservedUserNames containsObject:[[username trim] lowercaseString]];
}

- (void)toggleSignInFormAction
{
    self.shouldDisplayMultifactor = false;
    self.userIsDotCom = !self.userIsDotCom;
    
    if (self.userIsDotCom) {
        [self.delegate setPasswordTextReturnKeyType:UIReturnKeyDone];
    } else {
        [self.delegate setPasswordTextReturnKeyType:UIReturnKeyNext];
    }
    
    [self.delegate reloadInterfaceWithAnimation:YES];
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
        LoginFields *loginFields = [LoginFields loginFieldsWithUsername:username password:password siteUrl:siteUrl multifactorCode:multifactorCode userIsDotCom:userIsDotCom shouldDisplayMultiFactor:shouldDisplayMultifactor];
        
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

@end
