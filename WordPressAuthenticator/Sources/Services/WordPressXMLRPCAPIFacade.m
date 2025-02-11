#import "WordPressXMLRPCAPIFacade.h"
#import <WordPressAuthenticator/WordPressAuthenticator-Swift.h>

@import WordPressKit;

@interface WordPressXMLRPCAPIFacade ()

@property (nonatomic, strong) NSString *userAgent;

@end

NSString *const XMLRPCOriginalErrorKey = @"XMLRPCOriginalErrorKey";

@implementation WordPressXMLRPCAPIFacade

- (instancetype)initWithUserAgent:(NSString *)userAgent
{
    self = [super init];
    if (self) {
        _userAgent = userAgent;
    }

    return self;
}

- (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure
{
    WordPressOrgXMLRPCValidator *validator = [[WordPressOrgXMLRPCValidator alloc] init];
    [validator guessXMLRPCURLForSite:url
                           userAgent:self.userAgent
                             success:success
                             failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure([self errorForGuessXMLRPCApiFailure:error]);
        });
    }];
}

- (NSError *)errorForGuessXMLRPCApiFailure:(NSError *)error
{
    WPAuthenticatorLogError(@"Error on trying to guess XMLRPC site: %@", error);
    NSArray *errorCodes = @[
                            @(NSURLErrorUserCancelledAuthentication),
                            @(NSURLErrorNotConnectedToInternet),
                            @(NSURLErrorNetworkConnectionLost),
                            ];
    if ([error.domain isEqual:NSURLErrorDomain] && [errorCodes containsObject:@(error.code)]) {
        return error;
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to read the WordPress site at that URL. Tap 'Need more help?' to view the FAQ.", nil),
                                   NSLocalizedFailureReasonErrorKey: error.localizedDescription,
                                   XMLRPCOriginalErrorKey: error
                                   };

        NSError *err = [NSError errorWithDomain:WordPressAuthenticator.errorDomain code:NSURLErrorBadURL userInfo:userInfo];
        return err;
    }
}

- (void)getBlogOptionsWithEndpoint:(NSURL *)xmlrpc
                         username:(NSString *)username
                         password:(NSString *)password
                          success:(void (^)(NSDictionary *options))success
                          failure:(void (^)(NSError *error))failure;
{
    
    WordPressOrgXMLRPCApi *api = [[WordPressOrgXMLRPCApi alloc] initWithEndpoint:xmlrpc userAgent:self.userAgent];
    [api checkCredentials:username password:password success:^(id responseObject, NSHTTPURLResponse *httpResponse __unused) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![responseObject isKindOfClass:[NSDictionary class]]) {
                if (failure) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to read the WordPress site at that URL. Tap 'Need more help?' to view the FAQ.", nil)};
                    NSError *error = [NSError errorWithDomain:WordPressOrgXMLRPCApiErrorDomain code:WordPressOrgXMLRPCApiErrorResponseSerializationFailed userInfo:userInfo];
                    failure(error);
                }
                return;
            }
            if (success) {
                success((NSDictionary *)responseObject);
            }
        });

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse __unused) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(error);
            }
        });
    }];
}


@end
