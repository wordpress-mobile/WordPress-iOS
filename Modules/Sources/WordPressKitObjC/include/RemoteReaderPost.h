#import <Foundation/Foundation.h>

@class RemoteSourcePostAttribution;
@class RemoteReaderCrossPostMeta;

NS_ASSUME_NONNULL_BEGIN

@interface RemoteReaderPost : NSObject

// Reader Post Model
@property (nonatomic, strong, nullable) NSString *authorAvatarURL;
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
@property (nonatomic, strong, nullable) NSString *autoSuggestedFeaturedImage;
@property (nonatomic, strong, nullable) NSString *suitableImageFromPostContent;
@property (nonatomic, strong, nullable) NSNumber *feedID;
@property (nonatomic, strong, nullable) NSNumber *feedItemID;
@property (nonatomic, strong, nullable) NSString *globalID;
@property (nonatomic, strong, nullable) NSNumber *organizationID;
@property (nonatomic) BOOL isBlogAtomic;
@property (nonatomic) BOOL isBlogPrivate;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isLiked;
@property (nonatomic) BOOL isReblogged;
@property (nonatomic) BOOL isWPCom;
@property (nonatomic) BOOL isSeen;
@property (nonatomic) BOOL isSeenSupported;
@property (nonatomic, strong, nullable) NSNumber *likeCount;
@property (nonatomic, strong, nullable) NSNumber *score;
@property (nonatomic, strong, nullable) NSNumber *siteID;
@property (nonatomic, strong, nullable) NSDate *sortDate;
@property (nonatomic, strong, nullable) NSNumber *sortRank;
@property (nonatomic, strong, nullable) NSString *summary;
@property (nonatomic, strong, nullable) NSString *tags;
@property (nonatomic) BOOL isLikesEnabled;
@property (nonatomic) BOOL isSharingEnabled;
@property (nonatomic) BOOL useExcerpt;
@property (nonatomic, strong, nullable) RemoteSourcePostAttribution *sourceAttribution;
@property (nonatomic, strong, nullable) RemoteReaderCrossPostMeta *crossPostMeta;

@property (nonatomic, strong, nullable) NSString *primaryTag;
@property (nonatomic, strong, nullable) NSString *primaryTagSlug;
@property (nonatomic, strong, nullable) NSString *secondaryTag;
@property (nonatomic, strong, nullable) NSString *secondaryTagSlug;
@property (nonatomic) BOOL isExternal;
@property (nonatomic) BOOL isJetpack;
@property (nonatomic, nullable) NSNumber *wordCount;
@property (nonatomic, nullable) NSNumber *readingTime;
@property (nonatomic, strong, nullable) NSString *railcar;

@property (nonatomic) BOOL canSubscribeComments;
@property (nonatomic) BOOL isSubscribedComments;
@property (nonatomic) BOOL receivesCommentNotifications;

// Base Post Model
@property (nonatomic, strong, nullable) NSNumber *authorID;
@property (nonatomic, strong, nullable) NSString *author;
@property (nonatomic, strong, nullable) NSString *content;
@property (nonatomic, strong, nullable) NSString *date_created_gmt;
@property (nonatomic, strong, nullable) NSString *permalink;
@property (nonatomic, strong, nullable) NSNumber *postID;
@property (nonatomic, strong, nullable) NSString *postTitle;
@property (nonatomic, strong, nullable) NSString *status;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
