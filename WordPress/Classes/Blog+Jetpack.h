//
//  Blog+Jetpack.h
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

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

///--------------------------------------
///@name Information about Jetpack support
///---------------------------------------

/**
 Returns a Boolean value indicating whether the blog has Jetpack installed
 
 @return YES if the receiver blog has Jetpack installed or NO if it does not.
*/
- (BOOL)hasJetpack;

/**
 Returns the jetpack version installed in the blog
 
 @return the jetpack version installed in the blog
 */
- (NSString *)jetpackVersion;

/**
 Returns the WordPress.com blog ID assigned to the blog
 
 @returns the WordPress.com blog ID assigned to the blog
 */
- (NSNumber *)jetpackBlogID;

///----------------------------------
///@name Managing Jetpack credentials
///----------------------------------

/**
 Returns the WordPress.com username associated with the blog
 
 @returns the WordPress.com username associated with the blog
 */
- (NSString *)jetpackUsername;

/**
 Returns the WordPress.com password associated with the blog

 @returns the WordPress.com password associated with the blog
 */
- (NSString *)jetpackPassword;

/**
 Checks if the provided WordPress.com username and password are valid and associated to the blog
 
 On success, the username and password are stored as the blog's Jetpack credentials. Any previous credentials get replaced

 @param username the WordPress.com username to validate
 @param username the WordPress.com password to validate
 @param success a block called if the username and password are valid and associated to this blog
 @param failure a block called if there is any error. `error` can be any of BlogJetpackErrorCode or the underlying network errors
 */
- (void)validateJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Removes the stored Jetpack credentials for this blog
 
 For now, the password is not removed from the keychain, since that same password could be used by other Jetpack or WordPress.com blog.
 This might change in a future version, when we have a more centralized account system
 */
- (void)removeJetpackCredentials;
@end
