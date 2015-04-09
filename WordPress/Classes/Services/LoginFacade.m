#import "LoginFacade.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "NSURL+IDN.h"
#import "WordPressComOAuthClientFacade.h"
#import "WordPressXMLRPCApiFacade.h"


@interface LoginFacade () {
    id<LoginFacadeDelegate> _delegate;
    id<WordPressComOAuthClientFacade> _wordpressComOAuthClientFacade;
    id<WordPressXMLRPCApiFacade> _wordpressXMLRPCApiFacade;
}

@end


@implementation LoginFacade

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
    _wordpressComOAuthClientFacade = [WordPressComOAuthClientFacade new];
    _wordpressXMLRPCApiFacade = [WordPressXMLRPCApiFacade new];
}

- (id<LoginFacadeDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<LoginFacadeDelegate>)delegate
{
    _delegate = delegate;
}

- (id<WordPressComOAuthClientFacade>)wordpressComOAuthClientFacade
{
    return _wordpressComOAuthClientFacade;
}

- (void)setWordpressComOAuthClientFacade:(id<WordPressComOAuthClientFacade>)wordpressComOAuthClientService
{
    _wordpressComOAuthClientFacade = wordpressComOAuthClientService;
}

- (id<WordPressXMLRPCApiFacade>)wordpressXMLRPCApiFacade
{
    return _wordpressXMLRPCApiFacade;
}

- (void)setWordpressXMLRPCApiFacade:(id<WordPressXMLRPCApiFacade>)wordpressXMLRPCApiService
{
    _wordpressXMLRPCApiFacade = wordpressXMLRPCApiService;
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

- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields
{
    [self.wordpressComOAuthClientFacade requestOneTimeCodeWithUsername:loginFields.username password:loginFields.password success:^{
        [WPAnalytics track:WPAnalyticsStatTwoFactorSentSMS];
    } failure:^(NSError *error) {
        DDLogError(@"Failed to request one time code");
    }];
}

- (void)signInToWordpressDotCom:(LoginFields *)loginFields
{
    [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    [self.wordpressComOAuthClientFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:^(NSString *authToken) {
        [self.delegate finishedLoginWithUsername:loginFields.username authToken:authToken shouldDisplayMultifactor:loginFields.shouldDisplayMultifactor];
    } needsMultiFactor:^{
        [self.delegate needsMultifactorCode];
    } failure:^(NSError *error) {
        NSDictionary *properties = @{ @"multifactor" : @(loginFields.shouldDisplayMultifactor) };
        [WPAnalytics track:WPAnalyticsStatLoginFailed withProperties:properties];
        [self.delegate displayRemoteError:error];
    }];
}

- (void)signInToSelfHosted:(LoginFields *)loginFields
{
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        [self.wordpressXMLRPCApiFacade getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInToWordpressDotCom:loginFields];
            } else {
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self.delegate finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:xmlrpc options:options];
            }
        } failure:^(NSError *error) {
            [WPAnalytics track:WPAnalyticsStatLoginFailed];
            [self.delegate displayRemoteError:error];
        }];
    };
    
    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [WPAnalytics track:WPAnalyticsStatLoginFailedToGuessXMLRPC];
        [self.delegate displayRemoteError:error];
    };
    
    [self.delegate displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
    
    NSString *siteUrl = [NSURL IDNEncodedURL:loginFields.siteUrl];
    [self.wordpressXMLRPCApiFacade guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

@end
