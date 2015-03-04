#import <Foundation/Foundation.h>

@protocol WPPostContentViewProvider <NSObject>

// Identity accessors
- (NSURL *)authorURL;
- (NSString *)authorNameForDisplay;
- (NSURL *)avatarURLForDisplay; // Some providers use a hardcoded URL or blavatar URL
- (NSString *)gravatarEmailForDisplay;
- (NSString *)blogNameForDisplay;
- (NSURL *)blogURL;

// Content accessors
- (NSString *)titleForDisplay;
- (NSString *)contentForDisplay;
- (NSString *)contentPreviewForDisplay;
- (NSURL *)featuredImageURLForDisplay;

// Meta accessors
- (NSDate *)dateForDisplay;
- (NSString *)statusForDisplay;
- (BOOL)unreadStatusForDisplay;
- (NSInteger)commentCount;
- (NSInteger)likeCount;
- (BOOL)hasLiked;
- (BOOL)hasCommented;

@end
