#import "LoginFacade.h"
#import "LoginFields.h"
#import "NSString+Helpers.h"
#import "NSURL+IDN.h"
#import "WordPressComOAuthClientFacade.h"
#import "WordPressXMLRPCAPIFacade.h"
#import "WPError.h"
#import "BlogService.h"
#import "WPAppAnalytics.h"

@implementation LoginFacade

@synthesize delegate;
@synthesize wordpressComOAuthClientFacade = _wordpressComOAuthClientFacade;
@synthesize wordpressXMLRPCAPIFacade = _wordpressXMLRPCAPIFacade;

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
    _wordpressXMLRPCAPIFacade = [WordPressXMLRPCAPIFacade new];
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
    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    }

    [self.wordpressComOAuthClientFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:^(NSString *authToken) {
        if ([self.delegate respondsToSelector:@selector(finishedLoginWithUsername:authToken:requiredMultifactorCode:)]) {
            [self.delegate finishedLoginWithUsername:loginFields.username authToken:authToken requiredMultifactorCode:loginFields.shouldDisplayMultifactor];
        }
    } needsMultiFactor:^{
        if ([self.delegate respondsToSelector:@selector(needsMultifactorCode)]) {
            [self.delegate needsMultifactorCode];
        }
    } failure:^(NSError *error) {
        NSDictionary *properties = @{ @"multifactor" : @(loginFields.shouldDisplayMultifactor) };
        [WPAnalytics track:WPAnalyticsStatLoginFailed withProperties:properties];
        [WPAppAnalytics track:WPAnalyticsStatLoginFailed error:error];
        if ([self.delegate respondsToSelector:@selector(displayRemoteError:)]) {
            [self.delegate displayRemoteError:error];
        }
    }];
}

- (void)signInToSelfHosted:(LoginFields *)loginFields
{
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        [self.wordpressXMLRPCAPIFacade getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInToWordpressDotCom:loginFields];
            } else {
                NSString *versionString = options[@"software_version"][@"value"];
                CGFloat version = [versionString floatValue];
                if (version < [WordPressMinimumVersion floatValue]) {
                    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"WordPress version too old. The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", nil), [xmlRPCURL host], versionString, WordPressMinimumVersion];
                    NSError *versionError = [NSError errorWithDomain:WordPressAppErrorDomain
                                        code:WordPressAppErrorCodeInvalidVersion
                                    userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                    [WPAppAnalytics track:WPAnalyticsStatLoginFailed error:versionError];
                    [self.delegate displayRemoteError:versionError];
                    return;
                }
                NSString *xmlrpc = [xmlRPCURL absoluteString];
                [self.delegate finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:xmlrpc options:options];
            }
        } failure:^(NSError *error) {
            [WPAppAnalytics track:WPAnalyticsStatLoginFailed error:error];
            [self.delegate displayRemoteError:error];
        }];
    };
    
    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){        
        [WPAppAnalytics track:WPAnalyticsStatLoginFailedToGuessXMLRPC error:error];
        [self.delegate displayRemoteError:error];
    };
    
    [self.delegate displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
    
    NSString *siteUrl = [NSURL IDNEncodedURL:loginFields.siteUrl];
    [self.wordpressXMLRPCAPIFacade guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

@end
