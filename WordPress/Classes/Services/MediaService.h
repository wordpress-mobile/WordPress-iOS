#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LocalCoreDataService.h"

@class Media;

@interface MediaService : NSObject <LocalCoreDataService>
- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion;
@end
