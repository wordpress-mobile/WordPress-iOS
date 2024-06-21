#import <Foundation/Foundation.h>
#import <WordPressKit/RemoteComment.h>


// Used to determine which 'status' parameter to use when fetching Comments.
typedef enum {
    CommentStatusFilterAll = 0,
    CommentStatusFilterUnapproved,
    CommentStatusFilterApproved,
    CommentStatusFilterTrash,
    CommentStatusFilterSpam,
} CommentStatusFilter;


@protocol CommentServiceRemote <NSObject>

/**
 Loads all of the comments associated with a blog
 */
- (void)getCommentsWithMaximumCount:(NSInteger)maximumComments
                            success:(void (^)(NSArray *comments))success
                            failure:(void (^)(NSError *error))failure;



/**
 Loads all of the comments associated with a blog
 */
- (void)getCommentsWithMaximumCount:(NSInteger)maximumComments
                            options:(NSDictionary *)options
                            success:(void (^)(NSArray *posts))success
                            failure:(void (^)(NSError *error))failure;


/**
 Loads the specified comment associated with a blog
 */
- (void)getCommentWithID:(NSNumber *)commentID
                 success:(void (^)(RemoteComment *comment))success
                 failure:(void (^)(NSError * error))failure;

/**
 Publishes a new comment
 */
- (void)createComment:(RemoteComment *)comment
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure;
/**
 Updates the content of an existing comment
 */
- (void)updateComment:(RemoteComment *)commen
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure;

/**
 Updates the status of an existing comment
 */
- (void)moderateComment:(RemoteComment *)comment
                success:(void (^)(RemoteComment *comment))success
                failure:(void (^)(NSError *error))failure;

/**
 Trashes a comment
 */
- (void)trashComment:(RemoteComment *)comment
             success:(void (^)(void))success
             failure:(void (^)(NSError *error))failure;

@end
