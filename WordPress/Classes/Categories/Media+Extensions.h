#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@import WordPressData;

@interface Media (Extensions)

- (void)videoAssetWithCompletionHandler:(void (^ _Nonnull)(AVAsset * _Nullable asset, NSError * _Nullable error))completionHandler;

- (CGSize)pixelSize;
- (NSTimeInterval)duration;

@end
