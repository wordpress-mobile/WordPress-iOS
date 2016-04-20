#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"
#import "Blog.h"

NS_ASSUME_NONNULL_BEGIN

@class WPAccount;

@interface BlogService : LocalCoreDataService

- (instancetype) init __attribute__((unavailable("must use initWithManagedObjectContext")));

/**
 Returns the blog that matches with a given blogID
 */
- (nullable Blog *)blogByBlogId:(NSNumber *)blogID;

/**
 Stores the blog's URL in NSUserDefaults, for later retrieval
 */
- (void)flagBlogAsLastUsed:(Blog *)blog;

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

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

- (void)syncPostTypesForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

/**
 *  Sync blog settings from the server
 *
 *  @param blog    the blog from where to read the information from
 *  @param success a block that is invoked when the sync is sucessfull
 *  @param failure a block that in invoked when the sync fails.
 */
- (void)syncSettingsForBlog:(Blog *)blog
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

/**
 *  Update blog settings to server
 *
 *  @param blog    the blog to update
 *  @param success a block that is invoked when the update is sucessfull
 *  @param failure a block that in invoked when the update fails.
 */
- (void)updateSettingsForBlog:(Blog *)blog
                     success:(nullable void (^)())success
                     failure:(nullable void (^)(NSError *error))failure;


/**
 *  Update the password for the blog.
 *
 *  @discussion This is only valid for self-hosted sites that don't use jetpack.
 *
 *  @param password the new password to use for the blog
 *  @param blog to change the password.
 */
- (void)updatePassword:(NSString *)password forBlog:(Blog *)blog;

- (void)migrateJetpackBlogsToXMLRPCWithCompletion:(void (^)())success;

/**
 Syncs an blog "meta data" including post formats, blog options, and categories. 
 Also checks if the blog is multi-author.
 Used for instances where the entire blog should be refreshed or initially downloaded.
 */
- (void)syncBlog:(Blog *)blog completionHandler:(void (^)())completionHandler;

- (BOOL)hasVisibleWPComAccounts;

- (BOOL)hasAnyJetpackBlogs;

- (NSInteger)blogCountForAllAccounts;

- (NSInteger)blogCountSelfHosted;

- (NSInteger)blogCountForWPComAccounts;

- (NSInteger)blogCountVisibleForWPComAccounts;

- (NSInteger)blogCountVisibleForAllAccounts;

- (NSArray *)blogsForAllAccounts;

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

@end

NS_ASSUME_NONNULL_END
