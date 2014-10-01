#import <Foundation/Foundation.h>

@protocol WPContentViewProvider <NSObject>
- (NSString *)titleForDisplay;
- (NSString *)authorForDisplay;
- (NSString *)blogNameForDisplay;
- (NSString *)statusForDisplay;
- (NSString *)contentForDisplay;
- (NSString *)contentPreviewForDisplay;
- (NSURL *)avatarURLForDisplay; // Some providers use a hardcoded URL or blavatar URL
- (NSString *)gravatarEmailForDisplay;
- (NSDate *)dateForDisplay;
@optional
- (BOOL)unreadStatusForDisplay;
- (NSURL *)featuredImageURLForDisplay;
- (NSURL *)authorURL;
@end
