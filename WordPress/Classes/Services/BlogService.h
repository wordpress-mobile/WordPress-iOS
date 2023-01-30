#import <Foundation/Foundation.h>
#import "CoreDataService.h"
#import "Blog.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WordPressMinimumVersion;
extern NSString *const WPBlogUpdatedNotification;

@class WPAccount;
@class SiteInfo;

@interface BlogService : CoreDataService

/**
 *  Sync all available blogs for an acccount
 *
 *  @param account the account for the associated blogs.
 *  @param success a block that is invoked when the sync is successful.
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

/**
 *  Sync the blog and its top-level details such as the 'options' data and any jetpack configuration.
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful.
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncBlog:(Blog *)blog
         success:(void (^)(void))success
         failure:(void (^)(NSError *error))failure;

/**
 *  Sync the blog and all available metadata or configuration. Such as top-level details, postTypes, postFormats, categories, multi-author and jetpack configuration.
 *
 *  @note Used for instances where the entire blog should be refreshed or initially downloaded.
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful.
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncBlogAndAllMetadata:(Blog *)blog
             completionHandler:(void (^)(void))completionHandler;

/**
 *  Sync the available postTypes configured for the blog.
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful.
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncPostTypesForBlog:(Blog *)blog
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure;

/**
 *  Sync the available postFormats configured for the blog.
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful.
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure;

/**
 *  Sync blog settings from the server
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncSettingsForBlog:(Blog *)blog
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

/**
 *  Sync authors from the server
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is successful
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncAuthorsForBlog:(Blog *)blog
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure;

/**
 *  Update blog settings to the server
 *
 *  @param blog    the blog to update
 *  @param success a block that is invoked when the update is successful
 *  @param failure a block that in invoked when the update fails.
 */
- (void)updateSettingsForBlog:(Blog *)blog
                      success:(nullable void (^)(void))success
                      failure:(nullable void (^)(NSError *error))failure;

/**
 * Associate synced blogs to the specified Jetpack account.
 *
 *  @param account the account
 *  @param success a block that is invoked when the update is successful
 *  @param failure a block that in invoked when the update fails.
 */
- (void)associateSyncedBlogsToJetpackAccount:(WPAccount *)account
                                     success:(void (^)(void))success
                                     failure:(void (^)(NSError *error))failure;

- (BOOL)hasAnyJetpackBlogs;

- (void)removeBlog:(Blog *)blog;

@end

NS_ASSUME_NONNULL_END
