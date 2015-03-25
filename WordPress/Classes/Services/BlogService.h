#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog;
@class WPAccount;

@interface BlogService : NSObject<LocalCoreDataService>

/**
 Returns the blog that matches with a given blogID
 */
- (Blog *)blogByBlogId:(NSNumber *)blogID;

/**
 Stores the blog's URL in NSUserDefaults, for later retrieval
 */
- (void)flagBlogAsLastUsed:(Blog *)blog;

/**
 Returns the blog currently flagged as the one last used, or the first blog in
 an alphanumerically sorted list, if no blog is currently flagged as last used.
 */
- (Blog *)lastUsedOrFirstBlog;

/**
 Returns the wpcom blog currently flagged as the one last used, or the first wpcom
 blog in an alphanumerically sorted list, if no wpcom blog is currently flagged as 
 last used.
 */
- (Blog *)lastUsedOrFirstWPcomBlog;

/**
 Returns the blog currently flaged as the one last used.
 */
- (Blog *)lastUsedBlog;

/**
 Returns the first blog in an alphanumerically sorted list.
 */
- (Blog *)firstBlog;

/**
 Returns the first WPCom blog in an alphanumerically sorted list.
 */
- (Blog *)firstWPComBlog;

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)())success
                        failure:(void (^)(NSError *error))failure;

/*! Syncs an entire blog include posts, pages, comments, options, post formats, media library, and categories.
 *  Used for instances where the entire blog should be refreshed or initially downloaded.
 *
 *  \param success Completion block called if the operation was a success
 *  \param failure Completion block called if the operation was a failure
 */
- (void)syncBlog:(Blog *)blog
         success:(void (^)())success
         failure:(void (^)(NSError *error))failure;

- (void)checkVideoPressEnabledForBlog:(Blog *)blog
                              success:(void (^)(BOOL enabled))success
                              failure:(void (^)(NSError *error))failure;

- (BOOL)hasVisibleWPComAccounts;

- (NSInteger)blogCountForAllAccounts;

- (NSInteger)blogCountSelfHosted;

- (NSInteger)blogCountVisibleForWPComAccounts;

- (NSInteger)blogCountVisibleForAllAccounts;

- (NSArray *)blogsForAllAccounts;

/*! Determine timezone for blog from blog options.  If no timezone information is stored on
 *  the device, then assume GMT+0 is the default.
 *  
 *  \param blog     The blog/site to determine the timezone for.
 */
- (NSTimeZone *)timeZoneForBlog:(Blog *)blog;

///--------------------
/// @name Blog creation
///--------------------

/**
 Searches for a `Blog` object for this account with the given XML-RPC endpoint

 @param xmlrpc the XML-RPC endpoint URL as a string
 @param account the account the blog belongs to
 @return the blog if one was found, otherwise it returns nil
 */
- (Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc
                   inAccount:(WPAccount *)account;

/**
 Creates a blank `Blog` object for this account

 @param account the account the blog belongs to
 @return the newly created blog
 */
- (Blog *)createBlogWithAccount:(WPAccount *)account;

@end
