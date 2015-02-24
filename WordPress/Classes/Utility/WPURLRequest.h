#import <Foundation/Foundation.h>

@interface WPURLRequest : NSURLRequest


/**
 Returns a NSURLRequest targetting the specified URL, with it's User-Agent field set up.
 
 @param url The endpoint URL
 @param userAgent The User Agent that should be used. Can be nil.
 @return a `NSURLRequest` instance for the specified URL, with a given UserAgent set.
 */

+ (NSURLRequest *)requestWithURL:(NSURL *)url userAgent:(NSString *)userAgent;


/**
 Returns a NSURLRequest to authenticate the user against a `wp-login.php` endpoint.
 
 @param loginUrl The authentication endpoint URL.
 @param redirectURL The URL that should be redirected to, once authentication is complete.
 @param username The user's username.
 @param password The user's password.
 @param bearerToken The OAuth token (if available). Can be nil.
 @param userAgent The User Agent that should be used. Can be nil.
 @return a `NSURLRequest` with a URL containing the authentication credentials, as provided.
 */
+ (NSURLRequest *)requestForAuthenticationWithURL:(NSURL *)loginUrl
                                      redirectURL:(NSURL *)redirectURL
                                         username:(NSString *)username
                                         password:(NSString *)password
                                      bearerToken:(NSString *)bearerToken
                                        userAgent:(NSString *)userAgent;

@end
