#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"
#import "ReaderPostContentProvider.h"

@class ReaderAbstractTopic;
@class ReaderCrossPostMeta;
@class SourcePostAttribution;
@class Comment;
@class RemoteReaderPost;
@class ReaderCard;

extern NSString * const ReaderPostStoredCommentIDKey;
extern NSString * const ReaderPostStoredCommentTextKey;

@interface ReaderPost : BasePost <ReaderPostContentProvider>

@property (nonatomic, strong) NSString *authorDisplayName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *siteIconURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSString *blogDescription;
@property (nonatomic, strong) NSString *blogURL;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic) BOOL commentsOpen;
@property (nonatomic, strong) NSString *featuredImage;
@property (nonatomic, strong) NSNumber *feedID;
@property (nonatomic, strong) NSNumber *feedItemID;
@property (nonatomic, strong) NSString *globalID;
@property (nonatomic) BOOL isBlogAtomic;
@property (nonatomic) BOOL isBlogPrivate;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isLiked;
@property (nonatomic) BOOL isReblogged;
@property (nonatomic) BOOL isWPCom;
@property (nonatomic) BOOL isSavedForLater;
@property (nonatomic) BOOL isSeen;
@property (nonatomic) BOOL isSeenSupported;
@property (nonatomic, strong) NSNumber *organizationID;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *score;
@property (nonatomic, strong) NSNumber *siteID;
// Normalizes sorting between offset or sortDate depending on the flavor of post.
// Note that this can store a negative value.
@property (nonatomic, strong) NSNumber *sortRank;
// Normalizes the date to sort by depending on the flavor of post.
@property (nonatomic, strong) NSDate *sortDate;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSSet *comments;
@property (nonatomic, readonly, strong) NSURL *featuredImageURL;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic, strong) ReaderAbstractTopic *topic;
@property (nonatomic, strong) NSSet<ReaderCard *> *card;
@property (nonatomic) BOOL isLikesEnabled;
@property (nonatomic) BOOL isSharingEnabled;
@property (nonatomic) BOOL isSiteBlocked;
@property (nonatomic, strong) SourcePostAttribution *sourceAttribution;
@property (nonatomic) BOOL isSubscribedComments;
@property (nonatomic) BOOL canSubscribeComments;
@property (nonatomic) BOOL receivesCommentNotifications;

@property (nonatomic, strong) NSString *primaryTag;
@property (nonatomic, strong) NSString *primaryTagSlug;
@property (nonatomic) BOOL isExternal;
@property (nonatomic) BOOL isJetpack;
@property (nonatomic) NSNumber *wordCount;
@property (nonatomic) NSNumber *readingTime;
@property (nonatomic, strong) ReaderCrossPostMeta *crossPostMeta;
@property (nonatomic, strong) NSString *railcar;

// Used for tracking when a post is rendered (displayed), and bumping the train tracks rendered event.
@property (nonatomic) BOOL rendered;

// When true indicates a post should not be deleted/cleaned-up as its currently being used.
@property (nonatomic) BOOL inUse;

+ (instancetype)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic context:(NSManagedObjectContext *) managedObjectContext;

- (BOOL)isCrossPost;
- (BOOL)isPrivate;
- (BOOL)isP2Type;
- (NSString *)authorString;
- (NSString *)avatar;
- (UIImage *)cachedAvatarWithSize:(CGSize)size;
- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success;
- (BOOL)contentIncludesFeaturedImage;
- (BOOL)isSourceAttributionWPCom;
- (NSDictionary *)railcarDictionary;

@end

@interface ReaderPost (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

