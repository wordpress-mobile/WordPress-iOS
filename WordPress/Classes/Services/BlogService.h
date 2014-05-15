#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog;
@class Note;
@class WPAccount;

@interface BlogService : NSObject <LocalCoreDataService>


/**
 Returns the blog that matches with a given blogID
 */
- (Blog *)blogByBlogId:(NSNumber *)blogID;

/**
 Attempt to get the right blog that matches a given Blog Name
 */
- (Blog *)blogByBlogName:(NSString *)blogName;

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
 Returns the blog currently flaged as the one last used.
 */
- (Blog *)lastUsedBlog;

/**
 Returns the first blog in an alphanumerically sorted list.
 */
- (Blog *)firstBlog;

/*! Sync only blog posts, categories, options and post formats.
 *  Used for instances where comments and pages aren't necessarily needed to be updated.
 *
 *  \param success Completion block called if the operation was a success
 *  \param failure Completion block called if the operation was a failure
 */
- (void)syncPostsAndMetadataForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;

/*! Sync only blog posts (no metadata lists)
 *  Used for instances where comments and pages aren't necessarily needed to be updated.
 *
 *  \param success  Completion block called if the operation was a success
 *  \param failure  Completion block called if the operation was a failure
 *  \param more     If posts already exist then sync an additional batch
 */
- (void)syncPostsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;

- (void)syncPagesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;
- (void)syncCategoriesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncOptionsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncCommentsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncMediaLibraryForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncPostFormatsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;

/*! Syncs an entire blog include posts, pages, comments, options, post formats and categories.
 *  Used for instances where the entire blog should be refreshed or initially downloaded.
 *
 *  \param success Completion block called if the operation was a success
 *  \param failure Completion block called if the operation was a failure
 */
- (void)syncBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)checkVideoPressEnabledForBlog:(Blog *)blog success:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure;

- (NSInteger)blogCountForAllAccounts;

- (NSInteger)blogCountSelfHosted;

- (NSInteger)blogCountVisibleForAllAccounts;

- (NSArray *)blogsForAllAccounts;


@end
