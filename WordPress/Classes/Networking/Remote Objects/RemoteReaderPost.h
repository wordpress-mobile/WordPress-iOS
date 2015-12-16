#import <Foundation/Foundation.h>

@class RemoteSourcePostAttribution;
@class RemoteReaderCrossPostMeta;

@interface RemoteReaderPost : NSObject

// Reader Post Model
@property (nonatomic, strong) NSString *authorAvatarURL;
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
@property (nonatomic) BOOL isBlogPrivate;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isLiked;
@property (nonatomic) BOOL isReblogged;
@property (nonatomic) BOOL isWPCom;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *sortDate;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic) BOOL isLikesEnabled;
@property (nonatomic) BOOL isSharingEnabled;
@property (nonatomic, strong) RemoteSourcePostAttribution *sourceAttribution;
@property (nonatomic, strong) RemoteReaderCrossPostMeta *crossPostMeta;

@property (nonatomic, strong) NSString *primaryTag;
@property (nonatomic, strong) NSString *primaryTagSlug;
@property (nonatomic, strong) NSString *secondaryTag;
@property (nonatomic, strong) NSString *secondaryTagSlug;
@property (nonatomic) BOOL isExternal;
@property (nonatomic) BOOL isJetpack;
@property (nonatomic) NSNumber *wordCount;
@property (nonatomic) NSNumber *readingTime;

// Base Post Model
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *date_created_gmt;
@property (nonatomic, strong) NSString *permalink;
@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, strong) NSString *postTitle;
@property (nonatomic, strong) NSString *status;


@end
