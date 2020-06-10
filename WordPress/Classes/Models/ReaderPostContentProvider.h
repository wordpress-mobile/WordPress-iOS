#import <Foundation/Foundation.h>
#import "PostContentProvider.h"

typedef NS_ENUM(NSUInteger, SourceAttributionStyle) {
    SourceAttributionStyleNone,
    SourceAttributionStylePost,
    SourceAttributionStyleSite,
};

@protocol ReaderPostContentProvider <PostContentProvider>
- (NSNumber *)siteID;
- (NSURL *)siteIconForDisplayOfSize:(NSInteger)size;
- (SourceAttributionStyle)sourceAttributionStyle;
- (NSString *)sourceAuthorNameForDisplay;
- (NSURL *)sourceAuthorURLForDisplay;
- (NSURL *)sourceAvatarURLForDisplay;
- (NSString *)sourceBlogNameForDisplay;
- (NSURL *)sourceBlogURLForDisplay;

- (NSString *)likeCountForDisplay;
- (NSNumber *)commentCount;
- (NSNumber *)likeCount;
- (BOOL)commentsOpen;
- (BOOL)isFollowing;
- (BOOL)isLikesEnabled;
- (BOOL)isAtomic;
- (BOOL)isPrivate;
- (BOOL)isLiked;
- (BOOL)isExternal;
- (BOOL)isJetpack;
- (BOOL)isWPCom;
- (BOOL)isSavedForLater;
- (NSString *)primaryTag;
- (NSNumber *)readingTime;
- (NSNumber *)wordCount;

- (NSString *)siteURLForDisplay;
- (NSString *)siteHostNameForDisplay;
- (NSString *)crossPostOriginSiteURLForDisplay;
- (BOOL)isCommentCrossPost;

@end
