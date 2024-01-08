#import "Media.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Media (Extensions)

- (void)videoAssetWithCompletionHandler:(void (^ _Nonnull)(AVAsset * _Nullable asset, NSError * _Nullable error))completionHandler;

- (CGSize)pixelSize;
- (NSTimeInterval)duration;

/**
 Note: Redefine the filename property of Media to keep Swift happy.
 Otherwise, currently, Swift will only see the protocol method of filename() available,
 and not the (getter, setter) properity itself on Media.
 --Brent May/2017
 */
@property (nonatomic, strong, nullable) NSString *filename;

@end
