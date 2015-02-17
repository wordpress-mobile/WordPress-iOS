#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"

@class ReaderTopic;

extern NSString * const ReaderPostStoredCommentIDKey;
extern NSString * const ReaderPostStoredCommentTextKey;

@interface ReaderPost : BasePost

@property (nonatomic, strong) NSString *authorDisplayName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSString *blogDescription;
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
@property (nonatomic) BOOL isSiteBlocked;

- (BOOL)isPrivate;
- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment;
- (NSDictionary *)getStoredComment;
- (NSString *)authorString;
- (NSString *)avatar;
- (UIImage *)cachedAvatarWithSize:(CGSize)size;
- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;
- (BOOL)contentIncludesFeaturedImage;

@end
