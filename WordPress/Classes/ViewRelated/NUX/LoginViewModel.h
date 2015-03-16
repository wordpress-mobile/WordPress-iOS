#import <Foundation/Foundation.h>

@protocol LoginViewModelDelegate;
@protocol ReachabilityService;
@class RACSignal;

@interface LoginViewModel : NSObject

@property (nonatomic, assign) BOOL authenticating;
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;
@property (nonatomic, assign) BOOL userIsDotCom;
@property (nonatomic, assign) BOOL isSiteUrlEnabled;
@property (nonatomic, assign) BOOL isUsernameEnabled;
@property (nonatomic, assign) BOOL isPasswordEnabled;
@property (nonatomic, assign) BOOL isMultifactorEnabled;
@property (nonatomic, assign) BOOL cancellable;
@property (nonatomic, assign) BOOL hasDefaultAccount;
@property (nonatomic, assign) BOOL onlyDotComAllowed;
@property (nonatomic, readonly) NSString *signInButtonTitle;

@property (nonatomic, strong) NSString *siteUrl;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *multifactorCode;

@property (nonatomic, assign) id<LoginViewModelDelegate> delegate;

- (instancetype)initWithReachabilityService:(id<ReachabilityService>)reachabilityService;

- (void)signInButtonAction;
- (void)toggleSignInFormAction;

@end

@protocol LoginViewModelDelegate

- (void)showActivityIndicator:(BOOL)show;

- (void)setUsernameAlpha:(CGFloat)alpha;
- (void)setPasswordAlpha:(CGFloat)alpha;
- (void)setSiteAlpha:(CGFloat)alpha;
- (void)setMultiFactorAlpha:(CGFloat)alpha;

- (void)setUsernameEnabled:(BOOL)enabled;
- (void)setPasswordEnabled:(BOOL)enabled;
- (void)setSiteUrlEnabled:(BOOL)enabled;
- (void)setMultifactorEnabled:(BOOL)enabled;
- (void)setCancelButtonHidden:(BOOL)hidden;
- (void)setForgotPasswordHidden:(BOOL)hidden;
- (void)setSendVerificationCodeButtonHidden:(BOOL)hidden;
- (void)setAccountCreationButtonHidden:(BOOL)hidden;
- (void)setSignInButtonEnabled:(BOOL)enabled;
- (void)setSignInButtonTitle:(NSString *)title;
- (void)setToggleSignInButtonTitle:(NSString *)title;
- (void)setToggleSignInButtonHidden:(BOOL)hidden;
- (void)setPasswordTextReturnKeyType:(UIReturnKeyType)returnKeyType;

- (void)displayErrorMessageForInvalidOrMissingFields;
- (void)displayReservedNameErrorMessage;
- (void)reloadInterfaceWithAnimation:(BOOL)animated;
- (void)setFocusToSiteUrlText;

- (void)signIn;


@end
