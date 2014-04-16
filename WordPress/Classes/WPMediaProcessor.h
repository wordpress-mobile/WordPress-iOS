#import <Foundation/Foundation.h>

@class Media;

@interface WPMediaProcessor : NSObject

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata;

@end
