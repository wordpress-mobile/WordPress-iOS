#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WordPressBaseApi.h"

extern NSString *const WordPressXMLRPCApiErrorDomain;

typedef NS_ENUM(NSInteger, WordPressXMLRPCApiError) {
    WordPressXMLRPCApiEmptyURL, // The URL provided was nil, empty or just whitespaces
    WordPressXMLRPCApiInvalidURL, // The URL provided was an invalid URL
    WordPressXMLRPCApiInvalidScheme, // The URL provided was an invalid scheme, only HTTP and HTTPS supported
    WordPressXMLRPCApiNotWordPressError, // That's a XML-RPC endpoint but doesn't look like WordPress
    WordPressXMLRPCApiMobilePluginRedirectedError, // There's some "mobile" plugin redirecting everything to their site
    WordPressXMLRPCApiInvalid, // Doesn't look to be valid XMLRPC Endpoint.
};

/**
 WordPress API for iOS 
*/
@interface WordPressXMLRPCApi : NSObject <WordPressBaseApi>

///-----------------------------------------
/// @name Accessing WordPress API properties
///-----------------------------------------

@property (readonly, nonatomic, retain) NSURL *xmlrpc;
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;


///-------------------------------------------------------
/// @name Creating and Initializing a WordPress API Client
///-------------------------------------------------------

/**
 Creates and initializes a `WordPressAPI` client using password authentication.
 
 @param xmlrpc The XML-RPC endpoint URL, e.g.: https://en.blog.wordpress.com/xmlrpc.php
 @param username The user name
 @param password The password
 */
+ (WordPressXMLRPCApi *)apiWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password;

/**
 Initializes a `WordPressAPI` client using password authentication.
 
 @param xmlrpc The XML-RPC endpoint URL, e.g.: https://en.blog.wordpress.com/xmlrpc.php
 @param username The user name
 @param password The password
 */
- (id)initWithXMLRPCEndpoint:(NSURL *)xmlrpc username:(NSString *)username password:(NSString *)password;

///-------------------
/// @name Authenticate
///-------------------

/**
 Performs a XML-RPC test call just to verify that the credentials are correct.
 
 @param success A block object to execute when the credentials are valid. This block has no return value.
 @param failure A block object to execute when the credentials can't be verified. This block has no return value and takes one argument: a NSError object with details on the error.
 */
- (void)authenticateWithSuccess:(void (^)())success
                        failure:(void (^)(NSError *error))failure;

/**
 Authenticates and returns a list of the blogs which the user can access

 @param success A block object to execute when the login is successful. This block has no return value and takes one argument: an array with the blogs list.
 @param failure A block object to execute when the login failed. This block has no return value and takes one argument: a NSError object with details on the error.
 */
- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;

/**
 Authenticates and returns a dictionary of the blog's options.

 @param success A block object to execute when the login is successful. This block has no return value and takes one argument: a dictionary with the blog options.
 @param failure A block object to execute when the login failed. This block has no return value and takes one argument: a NSError object with details on the error.
 */
- (void)getBlogOptionsWithSuccess:(void (^)(id options))success failure:(void (^)(NSError *error))failure;

///--------------
/// @name Helpers
///--------------

/**
 Given a site URL, tries to guess the URL for the XML-RPC endpoint
 
 When asked for a site URL, sometimes users type the XML-RPC url, or the xmlrpc.php has been moved/renamed. This method would try a few methods to find the proper XML-RPC endpoint:
 
 * Try to load the given URL adding `/xmlrpc.php` at the end. This is the most common use case for proper site URLs
 * If that fails, try a test XML-RPC request given URL, maybe it was the XML-RPC URL already
 * If that fails, fetch the given URL and search for an `EditURI` link pointing to the XML-RPC endpoint
 
 For additional URL typo fixing, see [NSURL-Guess](https://github.com/koke/NSURL-Guess)
 
 @param url what the user entered as the URL, e.g.: myblog.com
 @param success A block object to execute when the method finds a suitable XML-RPC endpoint on the site provided. This block has no return value and takes two arguments: the original site URL, and the found XML-RPC endpoint URL.
 @param failure A block object to execute when the method doesn't find a suitable XML-RPC endpoint on the site. This block has no return value and takes one argument: a NSError object with details on the error.
 */
+ (void)guessXMLRPCURLForSite:(NSString *)url
                      success:(void (^)(NSURL *xmlrpcURL))success
                      failure:(void (^)(NSError *error))failure;


@end
