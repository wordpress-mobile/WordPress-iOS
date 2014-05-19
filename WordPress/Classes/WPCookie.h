#import <Foundation/Foundation.h>

@interface WPCookie : NSObject

/**
 Checks if there is a WordPress authentication cookie for the given URL
 
 This helper looks in NSHTTPCookieStorage for a "wordpress_logged_in" cookie for the given URL

 @param url the URL to check for cookies
 @return YES if there is a cookie for that URL, NO otherwise
 */
+ (BOOL)hasCookieForURL:(NSURL *)url;

/**
 Checks if there is a WordPress authentication cookie for the given URL and username

 This helper looks in NSHTTPCookieStorage for a "wordpress_logged_in" cookie for the given URL. Also check the contents of the cookie to make sure it's for the right user

 @param url the URL to check for cookies
 @param username the WordPress username to check for
 @return YES if there is a cookie for that URL and username, NO otherwise
 */
+ (BOOL)hasCookieForURL:(NSURL *)url andUsername:(NSString *)username;

@end
