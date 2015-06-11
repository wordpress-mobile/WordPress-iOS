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

// Meta accessors
- (NSDate *)dateForDisplay;
- (NSString *)dateStringForDisplay;
- (NSString *)status;
- (NSString *)statusForDisplay;
- (BOOL)unreadStatusForDisplay;
- (BOOL)supportsStats;
- (BOOL)isPrivate;
- (BOOL)isMultiAuthorBlog;
- (BOOL)isUploading;
- (BOOL)hasRevision;
- (id<WPPostContentViewProvider>)revision;

@optional
- (NSURL *)featuredImageURLForDisplay;
- (NSInteger)numberOfComments;
- (NSInteger)numberOfLikes;

@end
