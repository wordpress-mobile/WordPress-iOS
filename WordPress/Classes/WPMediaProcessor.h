#import <Foundation/Foundation.h>
#import "Media.h"

@class ALAsset;

@interface WPMediaProcessor : NSObject

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata;

@end
