#import "LoginService.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "WordPressComOAuthClientService.h"
#import "WordPressXMLRPCApiService.h"

#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import <NSDictionary+SafeExpectations.h>
#import <NSString+XMLExtensions.h>
#import "Blog.h"
#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"
#import "NSURL+IDN.h"
#import "Blog+Jetpack.h"


@interface LoginService () {
    id<LoginServiceDelegate> _delegate;
    id<WordPressComOAuthClientService> _wordpressComOAuthClientService;
    id<WordPressXMLRPCApiService> _wordpressXMLRPCApiService;
}

@end


@implementation LoginService

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeServices];
    }
    return self;
}

- (void)initializeServices
{
    _wordpressComOAuthClientService = [WordPressComOAuthClientService new];
    _wordpressXMLRPCApiService = [WordPressXMLRPCApiService new];
}

- (id<LoginServiceDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<LoginServiceDelegate>)delegate
{
    _delegate = delegate;
}

- (id<WordPressComOAuthClientService>)wordpressComOAuthClientService
{
    return _wordpressComOAuthClientService;
}

- (void)setWordpressComOAuthClientService:(id<WordPressComOAuthClientService>)wordpressComOAuthClientService
{
    _wordpressComOAuthClientService = wordpressComOAuthClientService;
}

- (id<WordPressXMLRPCApiService>)wordpressXMLRPCApiService
{
    return _wordpressXMLRPCApiService;
}

- (void)setWordpressXMLRPCApiService:(id<WordPressXMLRPCApiService>)wordpressXMLRPCApiService
{
    _wordpressXMLRPCApiService = wordpressXMLRPCApiService;
}

- (void)signInWithLoginFields:(LoginFields *)loginFields
{
    NSAssert(self.delegate != nil, @"Must set delegate to use service");
    
    if (loginFields.userIsDotCom || loginFields.siteUrl.isWordPressComPath) {
        [self signInToWordpressDotCom:loginFields];
    } else {
        [self signInToSelfHosted:loginFields];
    }
}

- (void)signInToWordpressDotCom:(LoginFields *)loginFields
{
    [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    [self.wordpressComOAuthClientService authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:^(NSString *authToken) {
        [self.delegate dismissLoginMessage];
        [self createWordPressComAccountForUsername:loginFields.username authToken:authToken shouldDisplayMultifactor:loginFields.shouldDisplayMultifactor];
    } needsMultiFactor:^{
        [self.delegate dismissLoginMessage];
        [self.delegate needsMultifactorCode];
    } failure:^(NSError *error) {
        NSDictionary *properties = @{ @"multifactor" : @(loginFields.shouldDisplayMultifactor) };
        [WPAnalytics track:WPAnalyticsStatLoginFailed withProperties:properties];
        [self.delegate dismissLoginMessage];
        [self.delegate displayRemoteError:error];
    }];
}

- (void)signInToSelfHosted:(LoginFields *)loginFields
{
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        [self.wordpressXMLRPCApiService getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
            [self.delegate dismissLoginMessage];
            
            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInToWordpressDotCom:loginFields];
            } else {
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self createSelfHostedAccountAndBlogWithUsername:loginFields.username password:loginFields.password xmlrpc:xmlrpc options:options];
            }
        } failure:^(NSError *error) {
            [WPAnalytics track:WPAnalyticsStatLoginFailed];
            [self.delegate dismissLoginMessage];
            [self.delegate displayRemoteError:error];
        }];
    };
    
    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [WPAnalytics track:WPAnalyticsStatLoginFailedToGuessXMLRPC];
        [self.delegate dismissLoginMessage];
        [self.delegate displayRemoteError:error];
    };
    
    [self.delegate displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
    
    NSString *siteUrl = [NSURL IDNEncodedURL:loginFields.siteUrl];
    [self.wordpressXMLRPCApiService guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)createWordPressComAccountForUsername:(NSString *)username authToken:(NSString *)authToken shouldDisplayMultifactor:(BOOL)shouldDisplayMultifactor
{
    [self.delegate displayLoginMessage:NSLocalizedString(@"Getting account information", nil)];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];

    WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:username authToken:authToken];

    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlogsForAccount:account
                                success:^{
                                    // Dismiss the UI
                                    [self.delegate dismissLoginMessage];
                                    [self.delegate finishedLogin];
                                    
                                    // Hit the Tracker
                                    NSDictionary *properties = @{
                                        @"multifactor" : @(shouldDisplayMultifactor),
                                        @"dotcom_user" : @(YES)
                                    };
                                    
                                    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:properties];
                                    [WPAnalytics refreshMetadata];

                                    // once blogs for the accounts are synced, we want to update account details for it
                                    [accountService updateEmailAndDefaultBlogForWordPressComAccount:account];
                                }
                                failure:^(NSError *error) {
                                    [self.delegate dismissLoginMessage];
                                    [self.delegate displayRemoteError:error];
                                }];
}


- (void)createSelfHostedAccountAndBlogWithUsername:(NSString *)username
                                          password:(NSString *)password
                                            xmlrpc:(NSString *)xmlrpc
                                           options:(NSDictionary *)options
{
    // TODO: This needs to be a separate account service (3/17/2015 sendhilp)
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    WPAccount *account = [accountService createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:username andPassword:password];
    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    if (!url) {
        url = [options stringForKeyPath:@"blog_url.value"];
    }
    Blog *blog = [blogService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!blog) {
        blog = [blogService createBlogWithAccount:account];
        if (url) {
            blog.url = url;
        }
        if (blogName) {
            blog.blogName = [blogName stringByDecodingXMLCharacters];
        }
    }
    blog.xmlrpc = xmlrpc;
    blog.options = options;
    [blog dataSave];
    [blogService syncBlog:blog success:nil failure:nil];

    if ([blog hasJetpack]) {
        if ([blog hasJetpackAndIsConnectedToWPCom]) {
            [self.delegate showJetpackAuthentication];
        } else {
            [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom];
            [self.delegate finishedLogin];
        }
    } else {
        [self.delegate finishedLogin];
    }

    [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSite];
    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:@{ @"dotcom_user" : @(NO) }];
    [WPAnalytics refreshMetadata];
}

- (void)handleGuessXMLRPCURLFailure:(NSError *)error
{
    [self.delegate dismissLoginMessage];
}



@end
