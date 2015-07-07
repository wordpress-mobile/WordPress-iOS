#import <Foundation/Foundation.h>
#import "WPContentViewProvider.h"

typedef NS_ENUM(NSUInteger, SourceAttributionType) {
    SourceAttributionTypeNone,
    SourceAttributionTypeEditorPick,
    SourceAttributionTypeSitePick,
};

@protocol ReaderPostContentProvider <WPContentViewProvider>
- (SourceAttributionType)sourceAttributionType;
- (NSString *)sourceAuthorNameForDisplay;
- (NSURL *)sourceAuthorURLForDisplay;
- (NSURL *)sourceAvatarURLForDisplay;
- (NSString *)sourceBlogNameForDisplay;
- (NSURL *)sourceBlogURLForDisplay;
@end
