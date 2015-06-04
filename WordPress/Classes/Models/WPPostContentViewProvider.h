#import <Foundation/Foundation.h>

@protocol WPPostContentViewProvider <NSObject>

// Identity accessors
- (NSURL *)authorURL;
- (NSString *)authorNameForDisplay;
- (NSURL *)avatarURLForDisplay; // Some providers use a hardcoded URL or blavatar URL
- (NSString *)gravatarEmailForDisplay;
- (NSString *)blogNameForDisplay;
- (NSURL *)blogURL;
- (NSString *)blogURLForDisplay;
- (NSString *)blavatarForDisplay;

// Content accessors
- (NSString *)titleForDisplay;
- (NSString *)contentForDisplay;
- (NSString *)contentPreviewForDisplay;
- (NSURL *)featuredImageURLForDisplay;

// Meta accessors
- (NSDate *)dateForDisplay;
- (NSString *)dateStringForDisplay;
- (NSString *)status;
- (NSString *)statusForDisplay;
- (BOOL)unreadStatusForDisplay;
- (NSInteger)numberOfComments;
- (NSInteger)numberOfLikes;
- (BOOL)supportsStats;
- (BOOL)isPrivate;
- (BOOL)isMultiAuthorBlog;
- (BOOL)isUploading;

@end
