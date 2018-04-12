#import "LoginFacade.h"
#import "NSURL+IDN.h"
#import "WordPressComOAuthClientFacade.h"
#import "WordPressXMLRPCAPIFacade.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "WordPress-Swift.h"



NSString *const WordPressOrgMinimumVersion = @"4.0";


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
    
    if (loginFields.meta.userIsDotCom || loginFields.siteAddress.isWordPressComPath) {
        [self signInToWordpressDotCom:loginFields];
    } else {
        [self signInToSelfHosted:loginFields];
    }
}

- (void)requestOneTimeCodeWithLoginFields:(LoginFields *)loginFields
{
    [self.wordpressComOAuthClientFacade requestOneTimeCodeWithUsername:loginFields.username password:loginFields.password success:^{
        [self track:WPAnalyticsStatTwoFactorSentSMS];
    } failure:^(NSError *error) {
        DDLogError(@"Failed to request one time code");
    }];
}

- (void)requestSocial2FACodeWithLoginFields:(LoginFields *)loginFields
{
    [self.wordpressComOAuthClientFacade requestSocial2FACodeWithUserID:loginFields.nonceUserID
                                                                nonce:loginFields.nonceInfo.nonceSMS
                                                                 success:^(NSString *newNonce) {
                                                                     if (newNonce) {
                                                                         loginFields.nonceInfo.nonceSMS = newNonce;
                                                                     }
                                                                     [WPAnalytics track:WPAnalyticsStatTwoFactorSentSMS];
                                                                 } failure:^(NSError *error, NSString *newNonce) {
                                                                     if (newNonce) {
                                                                         loginFields.nonceInfo.nonceSMS = newNonce;
                                                                     }
                                                                     DDLogError(@"Failed to request one time code");
                                                                 }];
}

- (void)loginToWordPressDotComWithGoogleIDToken:(NSString *)googleIDToken
{
    if ([self.delegate respondsToSelector:@selector(displayLoginMessage:)]) {
        [self.delegate displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    }

    [self.wordpressComOAuthClientFacade authenticateWithGoogleIDToken:googleIDToken success:^(NSString *authToken) {
        if ([self.delegate respondsToSelector:@selector(finishedLoginWithGoogleIDToken:authToken:)]) {
            [self.delegate finishedLoginWithGoogleIDToken:googleIDToken authToken:authToken];
        }
    } needsMultiFactor:^(NSInteger userID, SocialLogin2FANonceInfo *nonceInfo){
        if ([self.delegate respondsToSelector:@selector(needsMultifactorCodeForUserID:andNonceInfo:)]) {
            [self.delegate needsMultifactorCodeForUserID:userID andNonceInfo:nonceInfo];
        }
    } existingUserNeedsConnection: ^(NSString *email) {
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

    [self.wordpressComOAuthClientFacade authenticateSocialLoginUser:userID
                                                           authType:authType
                                                        twoStepCode:twoStepCode
                                                       twoStepNonce:twoStepNonce
                                                            success:^(NSString *authToken) {
                                                                if ([self.delegate respondsToSelector:@selector(finishedLoginWithNonceAuthToken:)]) {
                                                                    [self.delegate finishedLoginWithNonceAuthToken:authToken];
                                                                }
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
        if ([self.delegate respondsToSelector:@selector(finishedLoginWithUsername:authToken:requiredMultifactorCode:)]) {
            [self.delegate finishedLoginWithUsername:loginFields.username authToken:authToken requiredMultifactorCode:loginFields.meta.requiredMultifactor];
        }
    } needsMultiFactor:^{
        if ([self.delegate respondsToSelector:@selector(needsMultifactorCode)]) {
            [self.delegate needsMultifactorCode];
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
        loginFields.meta.xmlrpcURL = xmlRPCURL;
        [self loginToSelfHosted:loginFields];
    };

    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [self track:WPAnalyticsStatLoginFailedToGuessXMLRPC error:error];
        [self track:WPAnalyticsStatLoginFailed error:error];
        [self.delegate displayRemoteError:error];
    };

    [self.delegate displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];

    NSString *siteUrl = [NSURL IDNEncodedURL:loginFields.siteAddress];
    [self.wordpressXMLRPCAPIFacade guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)loginToSelfHosted:(LoginFields *)loginFields
{
    NSURL *xmlRPCURL = loginFields.meta.xmlrpcURL;
    [self.wordpressXMLRPCAPIFacade getBlogOptionsWithEndpoint:xmlRPCURL username:loginFields.username password:loginFields.password success:^(id options) {
        if ([options objectForKey:@"wordpress.com"] != nil) {
            [self signInToWordpressDotCom:loginFields];
        } else {
            NSString *versionString = options[@"software_version"][@"value"];
            CGFloat version = [versionString floatValue];
            if (version > 0 && version < [WordPressOrgMinimumVersion floatValue]) {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"WordPress version too old. The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", nil), [xmlRPCURL host], versionString, WordPressOrgMinimumVersion];
                NSError *versionError = [NSError errorWithDomain:WordPressAuthenticator.errorDomain
                                                            code:WordPressAuthenticator.invalidVersionErrorCode
                                                        userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
                [self track:WPAnalyticsStatLoginFailed error:versionError];
                [self.delegate displayRemoteError:versionError];
                return;
            }
            NSString *xmlrpc = [xmlRPCURL absoluteString];
            [self.delegate finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:xmlrpc options:options];
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
