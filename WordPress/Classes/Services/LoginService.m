#import "LoginService.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "NSURL+IDN.h"
#import "WordPressComOAuthClientService.h"
#import "WordPressXMLRPCApiService.h"


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

- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields
{
    [self.wordpressComOAuthClientService requestOneTimeCodeWithUsername:loginFields.username password:loginFields.password success:^{
        [WPAnalytics track:WPAnalyticsStatTwoFactorSentSMS];
    } failure:^(NSError *error) {
        DDLogError(@"Failed to request one time code");
    }];
}

- (void)signInToWordpressDotCom:(LoginFields *)loginFields
{
    [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    [self.wordpressComOAuthClientService authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:^(NSString *authToken) {
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
        [self.wordpressXMLRPCApiService getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
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
    [self.wordpressXMLRPCApiService guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

@end
