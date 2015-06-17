#import <Foundation/Foundation.h>

@class WPAccount;
@class Blog;

/**
 *  This protocol is for a class that will allow us to synchronize the details for a blog.
 */
@protocol BlogSyncFacade

/**
 *  This synchronizes a WordPress.com blog.
 *
 *  @param account a WordPress.com account.
 *  @param success a block that's called when this is successful.
 *  @param failure a block that's called when this fails.
 */
- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

/**
 *  This synchronizes a self hosted blog. This method will create a `Blog` object if a match isn't found.
 *
 *  @param username     username for the self hosted blog.
 *  @param password     password for the self hosted blog.
 *  @param xmlrpc       xmlrpc url for the self hosted blog.
 *  @param options      options dictionary for the self hosted blog.
 *  @param finishedSync a block that's called when this is done.
 */
- (void)syncBlogWithUsername:(NSString *)username
                    password:(NSString *)password
                      xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options
                finishedSync:(void(^)())finishedSync;

@end

/**
 *  This class allows us to synchronize the details for a blog.
 */
@interface BlogSyncFacade : NSObject<BlogSyncFacade>

@end
