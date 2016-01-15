#import <Foundation/Foundation.h>
#import "RemoteComment.h"

@protocol CommentServiceRemote <NSObject>


/**
 Loads all of the comments associated with a blog
 */
- (void)getCommentsForBlogID:(NSNumber *)blogID
                     success:(void (^)(NSArray *comments))success
                     failure:(void (^)(NSError *error))failure;



/**
 Loads all of the comments associated with a blog
 */
- (void)getCommentsForBlogID:(NSNumber *)blogID
                     options:(NSDictionary *)options
                     success:(void (^)(NSArray *posts))success
                     failure:(void (^)(NSError *error))failure;

/**
 Publishes a new comment
 */
- (void)createComment:(RemoteComment *)comment
            forBlogID:(NSNumber *)blogID
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure;
/**
 Updates the content of an existing comment
 */
- (void)updateComment:(RemoteComment *)commen
            forBlogID:(NSNumber *)blogID
              success:(void (^)(RemoteComment *comment))success
              failure:(void (^)(NSError *error))failure;

/**
 Updates the status of an existing comment
 */
- (void)moderateComment:(RemoteComment *)comment
              forBlogID:(NSNumber *)blogID
                success:(void (^)(RemoteComment *comment))success
                failure:(void (^)(NSError *error))failure;

/**
 Trashes a comment
 */
- (void)trashComment:(RemoteComment *)comment
           forBlogID:(NSNumber *)blogID
             success:(void (^)())success
             failure:(void (^)(NSError *error))failure;


@end
