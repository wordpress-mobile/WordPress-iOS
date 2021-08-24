#import <Foundation/Foundation.h>

@protocol PostContentProvider <NSObject>
- (NSString *)titleForDisplay;
- (NSString *)authorForDisplay;
- (NSString *)contentForDisplay;
- (NSString *)contentPreviewForDisplay;
- (NSURL *)avatarURLForDisplay; // Some providers use a hardcoded URL or blavatar URL
- (NSString *)gravatarEmailForDisplay;
- (NSDate *)dateForDisplay;
@optional
- (NSString *)blogNameForDisplay;
- (NSString *)statusForDisplay;
- (BOOL)unreadStatusForDisplay;
- (NSURL *)featuredImageURLForDisplay;
- (NSURL *)authorURL;
- (NSString *)slugForDisplay;
- (NSArray <NSString *> *)tagsForDisplay;
@end
