#import <Foundation/Foundation.h>
#import "CommentServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface CommentServiceRemoteREST : NSObject <CommentServiceRemote, ServiceRemoteREST>

/**
 Update a comment with a commentID + siteID
 */
- (void)updateCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    content:(NSString *)content
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

/**
 Moderate a comment with a commentID + siteID
 */
- (void)moderateCommentWithID:(NSNumber *)commentID
                       siteID:(NSNumber *)siteID
                       status:(NSString *)status
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

/**
 Trashes a comment with a commentID + siteID
 */
- (void)trashCommentWithID:(NSNumber *)commentID
                    siteID:(NSNumber *)siteID
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

/**
 Like a comment with a commentID + siteID
 */
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;


/**
 Unlike a comment with a commentID + siteID
 */
- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

@end
