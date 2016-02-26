#import <Foundation/Foundation.h>
#import "PostServiceRemoteOptions.h"

@class RemotePost;

@protocol PostServiceRemote <NSObject>

/**
 *  @brief      Requests the post with the specified ID.
 *
 *  @param      postID      The ID of the post to get.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostWithID:(NSNumber *)postID
              success:(void (^)(RemotePost *post))success
              failure:(void (^)(NSError *))failure;

/**
 *  @brief      Requests the posts of the specified type.
 *
 *  @param      postType    The type of the posts to get.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostsOfType:(NSString *)postType
               success:(void (^)(NSArray <RemotePost *> *remotePosts))success
               failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Requests the posts of the specified type using the specified options.
 *
 *  @param      postType    The type of the posts to get.  Cannot be nil.
 *  @param      options     The options to use for the request.  Can be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostsOfType:(NSString *)postType
               options:(NSDictionary *)options
               success:(void (^)(NSArray <RemotePost *> *remotePosts))success
               failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Creates a post remotely for the specified blog.
 *
 *  @param      post        The post to create remotely.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)createPost:(RemotePost *)post
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates a blog's post.
 *
 *  @param      post        The post to update.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updatePost:(RemotePost *)post
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Deletes a post.
 *
 *  @param      post        The post to delete.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)deletePost:(RemotePost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Trashes a post.
 *
 *  @param      post        The post to trash.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)trashPost:(RemotePost *)post
          success:(void (^)(RemotePost *))success
          failure:(void (^)(NSError *))failure;

/**
 *  @brief      Restores a post.
 *
 *  @param      post        The post to restore.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)restorePost:(RemotePost *)post
            success:(void (^)(RemotePost *))success
            failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Returns a dictionary set with option parameters of the PostServiceRemoteOptions protocol.
 *
 *  @param      options  The object with set remote options.  Cannot be nil.
 */
- (NSDictionary *)dictionaryWithRemoteOptions:(id <PostServiceRemoteOptions>)options;

@end