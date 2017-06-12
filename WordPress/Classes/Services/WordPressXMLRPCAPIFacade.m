#import "WordPressXMLRPCAPIFacade.h"
#import <wpxmlrpc/WPXMLRPC.h>
#import "WordPress-Swift.h"


@interface WordPressXMLRPCAPIFacade ()


@end


@implementation WordPressXMLRPCAPIFacade

- (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure
{
    WordPressOrgXMLRPCValidator *validator = [[WordPressOrgXMLRPCValidator alloc] init];
    [validator guessXMLRPCURLForSite:url
                           userAgent:WPUserAgent.wordPressUserAgent
                             success:success
                             failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure([self errorForGuessXMLRPCApiFailure:error]);
        });
    }];
}

- (NSError *)errorForGuessXMLRPCApiFailure:(NSError *)error
{
    DDLogError(@"Error on trying to guess XMLRPC site: %@", error);
    NSArray *errorCodes = @[
                            @(NSURLErrorUserCancelledAuthentication),
                            @(NSURLErrorNotConnectedToInternet),
                            @(NSURLErrorNetworkConnectionLost),
                            ];
    if ([error.domain isEqual:NSURLErrorDomain] && [errorCodes containsObject:@(error.code)]) {
        return error;
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to read the WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil),
                                   NSLocalizedFailureReasonErrorKey: error.localizedDescription
                                   };
        NSError *err = [NSError errorWithDomain:WordPressAppErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        return err;
    }
}

- (void)getBlogOptionsWithEndpoint:(NSURL *)xmlrpc
                         username:(NSString *)username
                         password:(NSString *)password
                          success:(void (^)(id options))success
                          failure:(void (^)(NSError *error))failure;
{
    
    WordPressOrgXMLRPCApi *api = [[WordPressOrgXMLRPCApi alloc] initWithEndpoint:xmlrpc userAgent:[WPUserAgent wordPressUserAgent]];
    [api checkCredentials:username password:password success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                success(responseObject);
            }
        });

    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failure) {
                failure(error);
            }
        });
    }];
}


@end
