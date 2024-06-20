#import <Foundation/Foundation.h>
#import <WordPressKit/PostServiceRemote.h>
#import <WordPressKit/SiteServiceRemoteWordPressComREST.h>
#import <WordPressKit/RemoteMedia.h>

@class RemoteUser;
@class RemoteLikeUser;

@interface PostServiceRemoteREST : SiteServiceRemoteWordPressComREST <PostServiceRemote>

/**
 *  @brief      Create a post remotely for the specified blog with a single piece of
 *              media.
 *
 *  @discussion This purpose of this method is to give app extensions the ability to create a post
 *              with media in a single network operation.
 *
 *  @param  post            The post to create remotely.  Cannot be nil.
 *  @param  media           The post to create remotely.  Can be nil.
 *  @param  requestEnqueued The block that will be executed when the network request is queued.  Can be nil.
 *  @param  success         The block that will be executed on success.  Can be nil.
 *  @param  failure         The block that will be executed on failure.  Can be nil.
 */
- (void)createPost:(RemotePost * _Nonnull)post
         withMedia:(RemoteMedia * _Nullable)media
   requestEnqueued:(void (^ _Nullable)(NSNumber * _Nonnull taskID))requestEnqueued
           success:(void (^ _Nullable)(RemotePost * _Nullable))success
           failure:(void (^ _Nullable)(NSError * _Nullable))failure;

/**
 *  @brief      Saves a post.
 *
 *
 *  @discussion Drafts and auto-drafts are just overwritten by autosave for the same
                user if the post is not locked.
 *              Non drafts or other users drafts are not overwritten.
 *  @param      post        The post to save.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)autoSave:(RemotePost * _Nonnull)post
         success:(void (^ _Nullable)(RemotePost * _Nullable post, NSString * _Nullable previewURL))success
         failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 *  @brief      Get autosave revision of a post.
 *
 *
 *  @discussion retrieve the latest autosave revision of a post
 
 *  @param      post        The post to save.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getAutoSaveForPost:(RemotePost * _Nonnull)post
                   success:(void (^ _Nullable)(RemotePost * _Nullable))success
                   failure:(void (^ _Nullable)(NSError * _Nullable error))failure;

/**
 *  @brief      Requests a list of users that liked the post with the specified ID.
 *
 *  @discussion Due to the API limitation, up to 90 users will be returned from the
 *              endpoint.
 *
 *  @param      postID          The ID for the post. Cannot be nil.
 *  @param      count           Number of records to retrieve. Cannot be nil. If 0, will default to endpoint max.
 *  @param      before          Filter results to Likes before this date/time string. Can be nil.
 *  @param      excludeUserIDs  Array of user IDs to exclude from response. Can be nil.
 *  @param      success         The block that will be executed on success. Can be nil.
 *  @param      failure         The block that will be executed on failure. Can be nil.
 */
- (void)getLikesForPostID:(NSNumber * _Nonnull)postID
                    count:(NSNumber * _Nonnull)count
                   before:(NSString * _Nullable)before
           excludeUserIDs:(NSArray<NSNumber *> * _Nullable)excludeUserIDs
                  success:(void (^ _Nullable)(NSArray<RemoteLikeUser *> * _Nonnull users, NSNumber * _Nonnull found))success
                  failure:(void (^ _Nullable)(NSError * _Nullable))failure;

/// Returns a remote post with the given data.
+ (nonnull RemotePost *)remotePostFromJSONDictionary:(nonnull NSDictionary *)jsonPost;

@end
