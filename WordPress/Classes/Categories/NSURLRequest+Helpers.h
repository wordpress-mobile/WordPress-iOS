#import <Foundation/Foundation.h>

@interface NSURLRequest (Helpers)

+ (NSURLRequest *)requestWithURL:(NSURL *)url userAgent:(NSString *)userAgent;

+ (NSURLRequest *)requestForAuthenticationWithURL:(NSURL *)loginUrl
                                      redirectURL:(NSURL *)redirectURL
                                         username:(NSString *)username
                                         password:(NSString *)password
                                      bearerToken:(NSString *)bearerToken
                                        userAgent:(NSString *)userAgent;

@end
