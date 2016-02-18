#import "PostServiceRemoteOptions.h"

/**
 @class PostServiceSyncOptions
 @brief An object of options and paramters for specific filtering and syncing of posts.
 See each remote API parameters for specifics regarding default values and limits.
 WP.com/REST Jetpack: https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/posts/
 XML-RPC: https://codex.wordpress.org/XML-RPC_WordPress_API/Posts
 */
@interface PostServiceSyncOptions : NSObject <PostServiceRemoteOptions>

/**
 When set to true previously synced AbstractPosts matching statuses and authorID will be purged while updating.
 */
@property (nonatomic, assign) BOOL purgesLocalSync;

/*
 Properties fulfilling PostServiceRemoteOptions protocol.
 */
@property (nonatomic, strong) NSArray <NSString *> *statuses;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSNumber *offset;
@property (nonatomic, assign) PostServiceResultsOrder order;
@property (nonatomic, assign) PostServiceResultsOrdering orderBy;
@property (nonatomic, strong) NSNumber *authorID;
@property (nonatomic, copy) NSString *search;

@end
