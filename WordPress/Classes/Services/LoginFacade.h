#import <Foundation/Foundation.h>


@class LoginFields;
@protocol WordPressComOAuthClientFacade;
@protocol WordPressXMLRPCAPIFacade;
@protocol LoginFacadeDelegate;

/**
 *  This protocol represents a class that handles the signing in to a self hosted/.com site.
 */
@protocol LoginFacade

/**
 *  This method will attempt to sign in to a self hosted/.com site.
 *
 *  @param loginFields the fields representing the site we are attempting to login to.
 */
- (void)signInWithLoginFields:(LoginFields *)loginFields;

/**
 *  This method requests a one time code needed for 2fa.
 *
 *  @param loginFields the fields representing the site we need a 2fa code for.
 */
- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields;

/**
 *  A delegate with a few methods that indicate various aspects of the login process
 */
@property (nonatomic, weak) id<LoginFacadeDelegate> delegate;

/**
 *  A class that handles the login to sites requiring oauth(primarily .com sites)
 */
@property (nonatomic, strong) id<WordPressComOAuthClientFacade> wordpressComOAuthClientFacade;

/**
 *  A class that handles the login to self hosted sites
 */
@property (nonatomic, strong) id<WordPressXMLRPCAPIFacade> wordpressXMLRPCAPIFacade;

@end

/**
 *  This class handles the signing in to a self hosted/.com site.
 */
@interface LoginFacade : NSObject <LoginFacade>

@end

/**
 *  Protocol with a few methods that indicate various aspects of the login process.
 */
@protocol LoginFacadeDelegate

/**
 *  This is called when we need to indicate to the a messagea about the current login (e.g. "Signing In", "Authenticating", "Syncing", etc.)
 *
 *  @param message the message to display to the user.
 */
- (void)displayLoginMessage:(NSString *)message;

/**
 *  This is called when the initial login failed because we need a 2fa code.
 */
- (void)needsMultifactorCode;

/**
 *  This is called when there's been an error and we want to inform the user.
 *
 *  @param error the error in question.
 */
- (void)displayRemoteError:(NSError *)error;

/**
 *  Called when finished logging into a self hosted site
 *
 *  @param username username of the site
 *  @param password password of the site
 *  @param xmlrpc   the xmlrpc url of the site
 *  @param options  the options dictionary coming back from the `wp.getOptions` method.
 */
- (void)finishedLoginWithUsername:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary * )options;


/**
 *  Called when finished logging in to a WordPress.com site
 *
 *  @param username                 username of the site
 *  @param authToken                authToken to be used to access the site
 *  @param requiredMultifactorCode  whether the login required a 2fa code
 */
- (void)finishedLoginWithUsername:(NSString *)username authToken:(NSString *)authToken requiredMultifactorCode:(BOOL)requiredMultifactorCode;

@end

