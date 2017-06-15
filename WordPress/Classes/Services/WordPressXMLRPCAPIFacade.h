#import <Foundation/Foundation.h>

@protocol WordPressXMLRPCAPIFacade

extern NSString *const XMLRPCOriginalErrorUserInfoKey;

- (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure;

- (void)getBlogOptionsWithEndpoint:(NSURL *)xmlrpc
                         username:(NSString *)username
                         password:(NSString *)password
                          success:(void (^)(id options))success
                          failure:(void (^)(NSError *error))failure;

@end

@interface WordPressXMLRPCAPIFacade : NSObject<WordPressXMLRPCAPIFacade>

@end
