#import "LoginFacade.h"
#import "WordPressXMLRPCAPIFacade.h"
#import <WordPressAuthenticator/WordPressAuthenticator-Swift.h>
@import NSURL_IDN;
@import WordPressKit;

@implementation LoginFacade

@synthesize delegate;
@synthesize wordpressComOAuthClientFacade = _wordpressComOAuthClientFacade;
@synthesize wordpressXMLRPCAPIFacade = _wordpressXMLRPCAPIFacade;

- (instancetype)initWithDotcomClientID:(NSString *)dotcomClientID dotcomSecret:(NSString *)dotcomSecret userAgent:(NSString *)userAgent
{
    self = [super init];
    if (self) {
        _wordpressComOAuthClientFacade = [[WordPressComOAuthClientFacade alloc] initWithClient:dotcomClientID secret:dotcomSecret];
        _wordpressXMLRPCAPIFacade = [[WordPressXMLRPCAPIFacade alloc] initWithUserAgent:userAgent];
    }
    return self;
}

- (void)signInWithLoginFields:(LoginFields *)loginFields
{
    NSAssert(self.delegate != nil, @"Must set delegate to use service");
    
    if (loginFields.userIsDotCom || loginFields.siteAddress.isWordPressComPath) {
        [self signInToWordpressDotCom:loginFields];
    } else {
        [self signInToSelfHosted:loginFields];
    }
}

- (void)loginToWordPressDotComWithSocialIDToken:(NSString *)token
                                        service:(NSString *)service
{
    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    }

    [self.wordpressComOAuthClientFacade authenticateWithSocialIDToken:token
                                                              service:service
                                                              success:^(NSString *authToken) {
        if ([service isEqualToString:@"google"] && [self.delegate respondsToSelector:@selector(finishedLoginWithGoogleIDToken:authToken:)]) {
            // Apple is handled in AppleAuthenticator
            [self.delegate finishedLoginWithGoogleIDToken:token authToken:authToken];
        }
        [self trackSuccess];
    } needsMultifactor:^(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo){
        if ([self.delegate respondsToSelector:@selector(needsMultifactorCodeForUserID:andNonceInfo:)]) {
            [self.delegate needsMultifactorCodeForUserID:userID andNonceInfo:nonceInfo];
        }
    } existingUserNeedsConnection: ^(NSString *email) {
        // Apple is handled in AppleAuthenticator
        if ([self.delegate respondsToSelector:@selector(existingUserNeedsConnection:)]) {
            [self.delegate existingUserNeedsConnection: email];
        }
    } failure:^(NSError *error) {
        [self track:WPAnalyticsStatLoginFailed error:error];
        [self track:WPAnalyticsStatLoginSocialFailure error:error];
        if ([self.delegate respondsToSelector:@selector(displayRemoteError:)]) {
            [self.delegate displayRemoteError:error];
        }
    }];
}

- (void)loginToWordPressDotComWithUser:(NSInteger)userID
                              authType:(NSString *)authType
                           twoStepCode:(NSString *)twoStepCode
                          twoStepNonce:(NSString *)twoStepNonce
{
    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    }

    [self.wordpressComOAuthClientFacade authenticateWithSocialLoginUser:userID
                                                               authType:authType
                                                            twoStepCode:twoStepCode
                                                           twoStepNonce:twoStepNonce
                                                                success:^(NSString *authToken) {
                                                                    if ([self.delegate respondsToSelector:@selector(finishedLoginWithNonceAuthToken:)]) {
                                                                        [self.delegate finishedLoginWithNonceAuthToken:authToken];
                                                                    }
                                                                    [self trackSuccess];
                                                                } failure:^(NSError *error) {
                                                                    [self track:WPAnalyticsStatLoginFailed error:error];
                                                                    if ([self.delegate respondsToSelector:@selector(displayRemoteError:)]) {
                                                                        [self.delegate displayRemoteError:error];
                                                                    }
                                                                }];
}

- (void)signInToWordpressDotCom:(LoginFields *)loginFields
{
    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    }

    [self.wordpressComOAuthClientFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:^(NSString *authToken) {
        if ([self.delegate respondsToSelector:@selector(finishedLoginWithAuthToken:requiredMultifactorCode:)]) {
            [self.delegate finishedLoginWithAuthToken:authToken requiredMultifactorCode:loginFields.requiredMultifactor];
        }
        [self trackSuccess];
    } needsMultifactor:^(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo) {
        if (nonceInfo == nil && [self.delegate respondsToSelector:@selector(needsMultifactorCode)]) {
            [self.delegate needsMultifactorCode];
        } else if (nonceInfo != nil && [self.delegate respondsToSelector:@selector(needsMultifactorCodeForUserID:andNonceInfo:)]) {
            [self.delegate needsMultifactorCodeForUserID:userID andNonceInfo:nonceInfo];
        }
    } failure:^(NSError *error) {
        [self track:WPAnalyticsStatLoginFailed error:error];
        if ([self.delegate respondsToSelector:@selector(displayRemoteError:)]) {
            [self.delegate displayRemoteError:error];
        }
    }];
}

- (void)signInToSelfHosted:(LoginFields *)loginFields
{
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        loginFields.xmlrpcURL = xmlRPCURL;
        [self loginToSelfHosted:loginFields];
    };

    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [self track:WPAnalyticsStatLoginFailedToGuessXMLRPC error:error];
        [self track:WPAnalyticsStatLoginFailed error:error];
        [self.delegate displayRemoteError:error];
    };

    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
    }

    NSString *siteUrl = [NSURL IDNEncodedURL: loginFields.siteAddress];
    [self.wordpressXMLRPCAPIFacade guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)loginToSelfHosted:(LoginFields *)loginFields
{
    NSURL *xmlRPCURL = loginFields.xmlrpcURL;
    [self.wordpressXMLRPCAPIFacade getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
        if ([options objectForKey:@"wordpress.com"] != nil) {
            [self signInToWordpressDotCom:loginFields];
        } else {
            NSString *versionString = options[@"software_version"][@"value"];
            NSString *minimumSupported = [WordPressOrgXMLRPCApi minimumSupportedVersion];
            CGFloat version = [versionString floatValue];

            if (version > 0 && version < [minimumSupported floatValue]) {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"WordPress version too old. The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", nil), [xmlRPCURL host], versionString, minimumSupported];
                NSError *versionError = [NSError errorWithDomain:WordPressAuthenticator.errorDomain
                                                            code:WordPressAuthenticator.invalidVersionErrorCode
                                                        userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                [self track:WPAnalyticsStatLoginFailed error:versionError];
                [self.delegate displayRemoteError:versionError];
                return;
            }
            NSString *xmlrpc = [xmlRPCURL absoluteString];
            [self.delegate finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:xmlrpc options:options];
            [self trackSuccess];
        }
    } failure:^(NSError *error) {
        [self track:WPAnalyticsStatLoginFailed error:error];
        [self.delegate displayRemoteError:error];
    }];
}

- (void)track:(WPAnalyticsStat)stat
{
    [WordPressAuthenticator track:stat];
}

- (void)track:(WPAnalyticsStat)stat error:(NSError *)error
{
    [WordPressAuthenticator track:stat error:error];
}

@end
