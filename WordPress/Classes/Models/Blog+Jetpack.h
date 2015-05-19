#import "Blog.h"

/**
 * Error returned as the domain to NSError from Blog+Jetpack.
 */
extern NSString * const BlogJetpackErrorDomain;

/**
 * Possible NSError codes for BlogJetpackErrorDomain.
 */
typedef NS_ENUM(NSInteger, BlogJetpackErrorCode) {
    // Blog is hosted in wordpress.com
    BlogJetpackErrorCodeInvalidBlog,
    // Username or password invalid
    BlogJetpackErrorCodeInvalidCredentials,
    // The user doesn't have access to that specific blog
    BlogJetpackErrorCodeNoRecordForBlog,
};

/**
 Jetpack additions to Blog
 
 @warning *Important:* you are not expected to call any of this methods for WordPress.com hosted blogs. If the `isWPcom` method returns YES for the receiver `Blog`, it will throw an exception.
 The minimum Jetpack version required is 1.8.2. Some of the methods might return incorrect values for older versions.
 */
@interface Blog (Jetpack)

/**
 Checks if the provided WordPress.com username and password are valid and associated to the blog
 
 On success, the username and password are stored as the blog's Jetpack credentials. Any previous credentials get replaced

 @param username the WordPress.com username to validate
 @param username the WordPress.com password to validate
 @param multifactorCode the Multifactor One-Time code associated to the account. Can be nil
 @param success a block called if the username and password are valid and associated to this blog
 @param failure a block called if there is any error. `error` can be any of BlogJetpackErrorCode or the underlying network errors
 */
- (void)validateJetpackUsername:(NSString *)username
                       password:(NSString *)password
                multifactorCode:(NSString *)multifactorCode
                        success:(void (^)())success
                        failure:(void (^)(NSError *error))failure;

@end
