#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <WordPressData/BasePost.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SourceAttributionStyle) {
    SourceAttributionStyleNone,
    SourceAttributionStylePost,
    SourceAttributionStyleSite,
};

@class ReaderAbstractTopic;
@class ReaderCrossPostMeta;
@class SourcePostAttribution;
@class Comment;
@class RemoteReaderPost;
@class ReaderCard;

extern NSString * const ReaderPostStoredCommentIDKey;
extern NSString * const ReaderPostStoredCommentTextKey;

@interface ReaderPost : BasePost

@property (nonatomic, strong, nullable) NSString *authorDisplayName;
@property (nonatomic, strong, nullable) NSString *authorEmail;
@property (nonatomic, strong, nullable) NSString *authorURL;
@property (nonatomic, strong, nullable) NSString *siteIconURL;
@property (nonatomic, strong, nullable) NSString *blogName;
@property (nonatomic, strong, nullable) NSString *blogDescription;
@property (nonatomic, strong, nullable) NSString *blogURL;
@property (nonatomic, strong, nullable) NSNumber *commentCount;
@property (nonatomic) BOOL commentsOpen;
@property (nonatomic, strong, nullable) NSString *featuredImage;
@property (nonatomic, strong, nullable) NSNumber *feedID;
@property (nonatomic, strong, nullable) NSNumber *feedItemID;
@property (nonatomic, strong, nullable) NSString *globalID;
@property (nonatomic) BOOL isBlogAtomic;
@property (nonatomic) BOOL isBlogPrivate;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isLiked;
@property (nonatomic) BOOL isReblogged;
@property (nonatomic) BOOL isWPCom;
@property (nonatomic) BOOL isSavedForLater;
@property (nonatomic) BOOL isSeen;
@property (nonatomic) BOOL isSeenSupported;
@property (nonatomic) NSNumber *organizationID;
@property (nonatomic, strong, nullable) NSNumber *likeCount;
@property (nonatomic, strong, nullable) NSNumber *score;
@property (nonatomic, strong, nullable) NSNumber *siteID;
// Normalizes sorting between offset or sortDate depending on the flavor of post.
// Note that this can store a negative value.
@property (nonatomic) NSNumber *sortRank;
// Normalizes the date to sort by depending on the flavor of post.
@property (nonatomic, strong, nullable) NSDate *sortDate;
@property (nonatomic, strong, nullable) NSString *summary;
@property (nonatomic, strong, nullable) NSSet *comments;
@property (nonatomic, strong, nullable) NSString *tags;
@property (nonatomic, strong, nullable) ReaderAbstractTopic *topic;
@property (nonatomic, strong, nullable) NSSet<ReaderCard *> *card;
@property (nonatomic) BOOL isLikesEnabled;
@property (nonatomic) BOOL isSharingEnabled;
@property (nonatomic) BOOL isSiteBlocked;
@property (nonatomic, strong, nullable) SourcePostAttribution *sourceAttribution;
@property (nonatomic) BOOL isSubscribedComments;
@property (nonatomic) BOOL canSubscribeComments;
@property (nonatomic) BOOL receivesCommentNotifications;

@property (nonatomic, strong, nullable) NSString *primaryTag;
@property (nonatomic, strong, nullable) NSString *primaryTagSlug;
@property (nonatomic) BOOL isExternal;
@property (nonatomic) BOOL isJetpack;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *readingTime;
@property (nonatomic, strong, nullable) ReaderCrossPostMeta *crossPostMeta;
@property (nonatomic, strong, nullable) NSString *railcar;

// Used for tracking when a post is rendered (displayed), and bumping the train tracks rendered event.
@property (nonatomic) BOOL rendered;

// When true indicates a post should not be deleted/cleaned-up as its currently being used.
@property (nonatomic) BOOL inUse;

+ (instancetype)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(nullable ReaderAbstractTopic *)topic context:(NSManagedObjectContext *) managedObjectContext;

- (BOOL)contentIncludesFeaturedImage;
- (nullable NSDictionary *)railcarDictionary;

@end

@interface ReaderPost (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
