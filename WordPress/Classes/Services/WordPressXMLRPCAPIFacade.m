#import "WordPressXMLRPCAPIFacade.h"
#import <WPXMLRPC/WPXMLRPC.h>
#import <WordPressApi/WordPressXMLRPCApi.h>


@interface WordPressXMLRPCAPIFacade ()

@property (nonatomic, strong) WordPressXMLRPCApi *xmlRPCApi;

@end


@implementation WordPressXMLRPCAPIFacade

- (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure
{
    [WordPressXMLRPCApi guessXMLRPCURLForSite:url success:success failure:^(NSError *error) {
        failure([self errorForGuessXMLRPCApiFailure:error]);
    }];
}

- (NSError *)errorForGuessXMLRPCApiFailure:(NSError *)error
{
    DDLogError(@"Error on trying to guess XMLRPC site: %@", error);
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        return error;
    } else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
        return error;
    } else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil)};
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
    
    WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlrpc username:username password:password];
    return [api getBlogOptionsWithSuccess:success failure:failure];
}


@end
