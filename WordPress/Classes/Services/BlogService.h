#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"
#import "Blog.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WordPressMinimumVersion;
extern NSString *const WPBlogUpdatedNotification;

@class WPAccount;
@class SiteInfo;

@interface BlogService : LocalCoreDataService

+ (instancetype)serviceWithMainContext;

- (instancetype) init __attribute__((unavailable("must use initWithManagedObjectContext")));

/**
 Returns the blog that matches with a given blogID
 */
- (nullable Blog *)blogByBlogId:(NSNumber *)blogID;

/**
 Returns the blog that matches with a given blogID and account.username
 */
- (nullable Blog *)blogByBlogId:(NSNumber *)blogID andUsername:(NSString *)username;

/**
 Returns the blog that matches with a given hostname
 */
- (nullable Blog *)blogByHostname:(NSString *)hostname;

/**
 Returns the blog currently flagged as the one last used, or the primary blog,
 or the first blog in an alphanumerically sorted list, whichever is found first.
 */
- (nullable Blog *)lastUsedOrFirstBlog;

/**
 Returns the blog currently flagged as the one last used, or the primary blog,
 or the first blog in an alphanumerically sorted list that supports the given
 feature, whichever is found first.
 */
- (nullable Blog *)lastUsedOrFirstBlogThatSupports:(BlogFeature)feature;

/**
 Returns the blog currently flaged as the one last used.
 */
- (nullable Blog *)lastUsedBlog;

/**
 Returns the first blog in an alphanumerically sorted list.
 */
- (nullable Blog *)firstBlog;

/**
 Returns the default WPCom blog.
 */
- (nullable Blog *)primaryBlog;


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

/**
 *  Update the password for the blog.
 *
 *  @discussion This is only valid for self-hosted sites that don't use jetpack.
 *
 *  @param password the new password to use for the blog
 *  @param blog to change the password.
 */
- (void)updatePassword:(NSString *)password forBlog:(Blog *)blog;

- (BOOL)hasVisibleWPComAccounts;

- (BOOL)hasAnyJetpackBlogs;

- (NSInteger)blogCountForAllAccounts;

- (NSInteger)blogCountSelfHosted;

- (NSInteger)blogCountForWPComAccounts;

- (NSInteger)blogCountVisibleForWPComAccounts;

- (NSInteger)blogCountVisibleForAllAccounts;

- (NSArray<Blog *> *)blogsForAllAccounts;

- (NSArray *)blogsWithNoAccount;

- (NSArray *)blogsWithPredicate:(NSPredicate *)predicate;

/**
 Returns every stored blog, arranged in a Dictionary by blogId.
 */
- (NSDictionary *)blogsForAllAccountsById;

/*! Determine timezone for blog from blog options.  If no timezone information is stored on
 *  the device, then assume GMT+0 is the default.
 *  
 *  \param blog     The blog/site to determine the timezone for.
 */
- (NSTimeZone *)timeZoneForBlog:(Blog *)blog;

- (void)removeBlog:(Blog *)blog;

///--------------------
/// @name Blog creation
///--------------------

/**
 Searches for a `Blog` object for this account with the given XML-RPC endpoint

 @warn If more than one blog is found, they'll be considered duplicates and be
 deleted leaving only one of them.

 @param xmlrpc the XML-RPC endpoint URL as a string
 @param account the account the blog belongs to
 @return the blog if one was found, otherwise it returns nil
 */
- (nullable Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc
                            inAccount:(WPAccount *)account;

/**
 Searches for a `Blog` object for this account with the given username

 @param xmlrpc the XML-RPC endpoint URL as a string
 @param username the blog's username
 @return the blog if one was found, otherwise it returns nil
 */
- (nullable Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc
                          andUsername:(NSString *)username;

/**
 Creates a blank `Blog` object for this account

 @param account the account the blog belongs to
 @return the newly created blog
 */
- (Blog *)createBlogWithAccount:(WPAccount *)account;

/**
 Creates a blank `Blog` object with no account

 @return the newly created blog
 */
- (Blog *)createBlog;

@end

NS_ASSUME_NONNULL_END
