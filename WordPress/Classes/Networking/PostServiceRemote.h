#import <Foundation/Foundation.h>

@class Blog, RemotePost;

@protocol PostServiceRemote <NSObject>

/**
 *  @brief      Requests the post with the specified ID.
 *
 *  @param      postID      The ID of the post to get.  Cannot be nil.
 *  @param      blog        The blog to get the post from.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(RemotePost *post))success
              failure:(void (^)(NSError *))failure;

/**
 *  @brief      Requests the posts of the specified type.
 *
 *  @param      postType    The type of the posts to get.  Cannot be nil.
 *  @param      blog        The blog to get the posts from.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               success:(void (^)(NSArray *posts))success
               failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Requests the posts of the specified type using the specified options.
 *
 *  @param      postType    The type of the posts to get.  Cannot be nil.
 *  @param      blog        The blog to get the posts from.  Cannot be nil.
 *  @param      options     The options to use for the request.  Can be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               options:(NSDictionary *)options
               success:(void (^)(NSArray *posts))success
               failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Creates a post remotely for the specified blog.
 *
 *  @param      post        The post to create remotely.  Cannot be nil.
 *  @param      blog        The blog to create the post in.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)createPost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates a blog's post.
 *
 *  @param      post        The post to update.  Cannot be nil.
 *  @param      blog        The blog that owns the post to update.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updatePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Deletes a post.
 *
 *  @param      post        The post to delete.  Cannot be nil.
 *  @param      blog        The blog that owns the post to delete.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)deletePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Trashes a post.
 *
 *  @param      post        The post to trash.  Cannot be nil.
 *  @param      blog        The blog that owns the post to trash.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)trashPost:(RemotePost *)post
          forBlog:(Blog *)blog
          success:(void (^)(RemotePost *))success
          failure:(void (^)(NSError *))failure;

/**
 *  @brief      Restores a post.
 *
 *  @param      post        The post to restore.  Cannot be nil.
 *  @param      blog        The blog that owns the post to restore.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)restorePost:(RemotePost *)post
            forBlog:(Blog *)blog
            success:(void (^)(RemotePost *))success
            failure:(void (^)(NSError *error))failure;

@end