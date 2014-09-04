#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"
#import "ReaderTopic.h"
#import "WordPressComApi.h"

extern NSString * const ReaderPostStoredCommentIDKey;
extern NSString * const ReaderPostStoredCommentTextKey;

@interface ReaderPost : BasePost

@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) NSString *authorDisplayName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSString *blogURL;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic) BOOL commentsOpen;
@property (nonatomic, strong) NSDate *dateCommentsSynced;
@property (nonatomic, strong) NSString *featuredImage;
@property (nonatomic, strong) NSString *globalID;
@property (nonatomic) BOOL isBlogPrivate;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isLiked;
@property (nonatomic) BOOL isReblogged;
@property (nonatomic) BOOL isWPCom;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSDate *sortDate;
@property (nonatomic, strong) NSString *storedComment; // Formatted as commentID,string
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSMutableSet *comments;
@property (nonatomic, readonly, strong) NSURL *featuredImageURL;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic, strong) ReaderTopic *topic;
@property (nonatomic) BOOL isLikesEnabled;
@property (nonatomic) BOOL isSharingEnabled;

- (BOOL)isFollowable;

- (BOOL)isPrivate;

- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment;

- (NSDictionary *)getStoredComment;

- (NSString *)authorString;

- (NSString *)avatar;

- (UIImage *)cachedAvatarWithSize:(CGSize)size;

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;

- (NSString *)featuredImageForWidth:(NSUInteger)width height:(NSUInteger)height;

@end


@interface ReaderPost (WordPressComApi)

/**
 Gets the list of comments for the specified post, on the specified site.
 
 @param postID The ID of the post for the comments to retrieve.
 @param siteID The ID (as a string) or host name of the site.
 @param params A dictionary of modifiers to limit or modify the result set. Possible values include number, offset, page, order, order_by, before, after.
 Check the documentation for the desired endpoint for a full list. ( http://developer.wordpress.com/docs/api/1/ )
 @param success a block called if the REST API call is successful.
 @param failure a block called if there is any error. `error` can be any underlying network error
 */
+ (void)getCommentsForPost:(NSUInteger)postID
				  fromSite:(NSString *)siteID
			withParameters:(NSDictionary*)params
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure;

@end
