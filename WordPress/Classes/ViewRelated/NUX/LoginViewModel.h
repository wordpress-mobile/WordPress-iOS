#import <Foundation/Foundation.h>
#import "LoginFacade.h"

@protocol AccountServiceFacade;
@protocol BlogSyncFacade;
@protocol HelpshiftEnabledFacade;
@protocol LoginFacade;
@protocol LoginViewModelPresenter;
@protocol ReachabilityFacade;
@protocol OnePasswordFacade;
@class RACSignal;

/**
 *  This is the view model for the `LoginViewController` that contains the state needed for all the
    classes interactions as well as a few methods to be called from the class when the user engages with the UI.
 */
@interface LoginViewModel : NSObject <LoginFacadeDelegate>

// Facades

/**
 *  A class to determine whether we have internet or not.
 */
@property (nonatomic, strong) id<ReachabilityFacade> reachabilityFacade;

/**
 *  A class to handle logging into a site.
 */
@property (nonatomic, strong) id<LoginFacade> loginFacade;

/**
 *  A class to handle a few things related to a user's account(creation and retrieval of the email address).
 */
@property (nonatomic, strong) id<AccountServiceFacade> accountServiceFacade;

/**
 *  A class to handle synchronizing a newly added site.
 */
@property (nonatomic, strong) id<BlogSyncFacade> blogSyncFacade;

/**
 *  A class to determine if Helpshift is available.
 */
@property (nonatomic, strong) id<HelpshiftEnabledFacade> helpshiftEnabledFacade;

/**
 *  A class to determine if OnePassword is available and to display the extension when needed.
 */
@property (nonatomic, strong) id<OnePasswordFacade> onePasswordFacade;

/**
 *  Whether the user is signing into a site.
 */
@property (nonatomic, assign) BOOL authenticating;

/**
 *  This determines whether we should show the multifactor code text field.
 */
@property (nonatomic, assign) BOOL shouldDisplayMultifactor;

/**
 *  Whether the user is a WordPress.com user or not.
 */
@property (nonatomic, assign) BOOL userIsDotCom;

/**
 *  Whether the site url field is enabled.
 */
@property (nonatomic, assign) BOOL isSiteUrlEnabled;

/**
 *  Whether the username field is enabled.
 */
@property (nonatomic, assign) BOOL isUsernameEnabled;

/**
 *  Whether the 1Password button is enabled.
 */
@property (nonatomic, assign) BOOL isPasswordEnabled;

/**
 *  Whether the multifactor text field is enabled.
 */
@property (nonatomic, assign) BOOL isMultifactorEnabled;

/**
 *  Whether this view controller can be cancelled because it's being presented modally.
 */
@property (nonatomic, assign) BOOL cancellable;

/**
 *  Whether the user has a default account already or not
 */
@property (nonatomic, assign) BOOL hasDefaultAccount;

/**
 *  Set to true when we only want to handle a WordPress.com login.
 */
@property (nonatomic, assign) BOOL onlyDotComAllowed;

/**
 *  Whether we need to reauthenticate the default account because a token expired or a password was changed.
 */
@property (nonatomic, assign) BOOL shouldReauthenticateDefaultAccount;


/**
 *  The title of the sign in button
 */
@property (nonatomic, readonly) NSString *signInButtonTitle;

/**
 *  The site url the user entered
 */
@property (nonatomic, strong) NSString *siteUrl;

/**
 *  The username the user entered
 */
@property (nonatomic, strong) NSString *username;

/**
 *  The password the user entered
 */
@property (nonatomic, strong) NSString *password;

/**
 *  The multifactor code the user entered
 */
@property (nonatomic, strong) NSString *multifactorCode;

/**
 *  A protocol representing an instance of `LoginViewModelPresenter` which is the way this class tells the view what to display.
 */
@property (nonatomic, weak) id<LoginViewModelPresenter> presenter;


/**
 *  This method kicks off the sign in process.
 */
- (void)signInButtonAction;

/**
 *  This method will bring up the 1Password extension
 *
 *  @param viewController the view controller that will display the 1Password extension
 *  @param sender the control that triggered this action
 */
- (void)onePasswordButtonActionForViewController:(UIViewController *)viewController sender:(id)sender;

/**
 *  The method returns the base site url
 *
 *  @return the base site url with http:// or https:// depending on whether the site is WordPress.com or a self hosted.
 */
- (NSString *)baseSiteUrl;

/**
 *  This method will open up the forgot password page for the corresponding site.
 */
- (void)forgotPasswordButtonAction;

/**
 *  This button will toggle the sign in fields between .com and self hosted.
 */
- (void)toggleSignInFormAction;

/**
 *  This indicates whether 1Password is enabled.
 *
 *  @return YES when 1Password is enabled.
 */
- (BOOL)isOnePasswordEnabled;

/**
 *  This requests a one time code used for 2fa.
 */
- (void)requestOneTimeCode;

@end


@class WPWalkthroughOverlayView;
typedef void (^OverlayViewCallback)(WPWalkthroughOverlayView *);

/**
 *  A protocol that should be implemented by a class using `LoginViewModel`. Most of the methods on this
    protocol are very basic as the most of the logic behind them is contained in `LoginViewModel`.
 */
@protocol LoginViewModelPresenter

- (void)showActivityIndicator:(BOOL)show;
- (void)showAlertWithMessage:(NSString *)message;

- (void)setUsernameAlpha:(CGFloat)alpha;
- (void)setUsernameEnabled:(BOOL)enabled;
- (void)setUsernameTextValue:(NSString *)username;

- (void)setPasswordAlpha:(CGFloat)alpha;
- (void)setPasswordEnabled:(BOOL)enabled;
- (void)setPasswordTextValue:(NSString *)password;
- (void)setPasswordSecureEntry:(BOOL)secureTextEntry;

- (void)setMultiFactorAlpha:(CGFloat)alpha;
- (void)setMultifactorEnabled:(BOOL)enabled;
- (void)setMultifactorTextValue:(NSString *)multifactorText;

- (void)setSiteAlpha:(CGFloat)alpha;
- (void)setSiteUrlEnabled:(BOOL)enabled;
- (void)setCancelButtonHidden:(BOOL)hidden;
- (void)setForgotPasswordHidden:(BOOL)hidden;
- (void)setSendVerificationCodeButtonHidden:(BOOL)hidden;
- (void)setAccountCreationButtonHidden:(BOOL)hidden;
- (void)setSignInButtonEnabled:(BOOL)enabled;
- (void)setSignInButtonTitle:(NSString *)title;
- (void)setToggleSignInButtonTitle:(NSString *)title;
- (void)setToggleSignInButtonHidden:(BOOL)hidden;
- (void)setPasswordTextReturnKeyType:(UIReturnKeyType)returnKeyType;
- (void)setFocusToSiteUrlText;
- (void)setFocusToMultifactorText;

- (void)autoFillLoginWithSharedWebCredentialsIfAvailable;
- (void)updateAutoFillLoginCredentialsIfNeeded:(NSString *)username password:(NSString *)password;

- (void)displayErrorMessageForInvalidOrMissingFields;
- (void)displayReservedNameErrorMessage;
- (void)reloadInterfaceWithAnimation:(BOOL)animated;
- (void)openURLInSafari:(NSURL *)url;
- (void)displayOnePasswordEmptySiteAlert;

// Ones we forward from LoginFacade
- (void)displayLoginMessage:(NSString *)message;
- (void)dismissLoginMessage;
- (void)dismissLoginView;
- (void)displayOverlayViewWithMessage:(NSString *)message firstButtonText:(NSString *)firstButtonText firstButtonCallback:(OverlayViewCallback)firstButtonCallback secondButtonText:(NSString *)secondButtonText secondButtonCallback:(OverlayViewCallback)secondButtonCallback accessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)displayHelpViewControllerWithAnimation:(BOOL)animated;
- (void)displayHelpshiftConversationView;
- (void)displayWebViewForURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;
- (void)endViewEditing;

@end
