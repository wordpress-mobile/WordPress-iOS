#import <Foundation/Foundation.h>

@protocol PostContentProvider <NSObject>
- (nullable NSString *)titleForDisplay;
- (nullable NSString *)authorForDisplay;
- (nullable NSString *)contentForDisplay;
- (nullable NSString *)contentPreviewForDisplay;
- (nullable NSURL *)avatarURLForDisplay; // Some providers use a hardcoded URL or blavatar URL
- (nullable NSString *)gravatarEmailForDisplay;
- (nullable NSDate *)dateForDisplay;
@optional
- (nullable NSString *)blogNameForDisplay;
- (nullable NSURL *)featuredImageURLForDisplay;
- (nullable NSURL *)authorURL;
- (nullable NSArray <NSString *> *)tagsForDisplay;
@end
