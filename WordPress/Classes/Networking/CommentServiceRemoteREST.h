#import <Foundation/Foundation.h>
#import "CommentServiceRemote.h"
#import "ServiceRemoteREST.h"

@interface CommentServiceRemoteREST : NSObject <CommentServiceRemote, ServiceRemoteREST>

/**
 Moderate a comment with a given ID
 */
- (void)moderateCommentWithID:(NSNumber *)commentID
                       siteID:(NSNumber *)siteID
                       status:(NSString *)status
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

/**
 Trashes a comment with a given ID
 */
- (void)trashCommentWithID:(NSNumber *)commentID
                    siteID:(NSNumber *)siteID
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure;

/**
 Like a comment with a given ID
 */
- (void)likeCommentWithID:(NSNumber *)commentID
                   siteID:(NSNumber *)siteID
                  success:(void (^)())success
                  failure:(void (^)(NSError *error))failure;


/**
 Unlike a comment with a given ID
 */
- (void)unlikeCommentWithID:(NSNumber *)commentID
                     siteID:(NSNumber *)siteID
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

@end
