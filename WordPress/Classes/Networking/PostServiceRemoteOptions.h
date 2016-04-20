#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PostServiceResultsOrder) {
    /**
     (default) Request results in descending order. For dates, that means newest to oldest.
     */
    PostServiceResultsOrderDescending = 0,
    /**
     Request results in ascending order. For dates, that means oldest to newest.
     */
    PostServiceResultsOrderAscending
};

typedef NS_ENUM(NSUInteger, PostServiceResultsOrdering) {
    /**
     (default) Order the results by the created time of each post.
     */
    PostServiceResultsOrderingByDate = 0,
    /**
     Order the results by the modified time of each post.
     */
    PostServiceResultsOrderingByModified,
    /**
     Order the results lexicographically by the title of each post.
     */
    PostServiceResultsOrderingByTitle,
    /**
     Order the results by the number of comments for each pot.
     */
    PostServiceResultsOrderingByCommentCount,
    /**
     Order the results by the postID of each post.
     */
    PostServiceResultsOrderingByPostID
};

@protocol PostServiceRemoteOptions <NSObject>

/**
 List of PostStatuses for which to query
 */
- (NSArray <NSString *> *)statuses;

/**
 The number of posts to return. Limit: 100.
 */
- (NSNumber *)number;

/**
 0-indexed offset for paging requests.
 */
- (NSNumber *)offset;

/**
 The order direction of the results.
 */
- (PostServiceResultsOrder)order;

/**
 The ordering value used when ordering results.
 */
- (PostServiceResultsOrdering)orderBy;

/**
 Specify posts only by the given authorID.
 @attention Not supported in XML-RPC.
 */
- (NSNumber *)authorID;

/**
 A search query used when requesting posts.
 @attention Not supported in XML-RPC.
 */
- (NSString *)search;

@end