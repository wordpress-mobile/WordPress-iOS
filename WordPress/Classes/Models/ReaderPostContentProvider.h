#import <Foundation/Foundation.h>
#import "WPContentViewProvider.h"

typedef NS_ENUM(NSUInteger, SourceAttributionStyle) {
    SourceAttributionStyleNone,
    SourceAttributionStylePost,
    SourceAttributionStyleSite,
};

@protocol ReaderPostContentProvider <WPContentViewProvider>
- (SourceAttributionStyle)sourceAttributionStyle;
- (NSString *)sourceAuthorNameForDisplay;
- (NSURL *)sourceAuthorURLForDisplay;
- (NSURL *)sourceAvatarURLForDisplay;
- (NSString *)sourceBlogNameForDisplay;
- (NSURL *)sourceBlogURLForDisplay;

- (NSNumber *)commentCount;
- (NSNumber *)likeCount;
- (BOOL)commentsOpen;
- (BOOL)isLikesEnabled;
- (BOOL)isPrivate;
- (BOOL)isLiked;

@end
