#import <Foundation/Foundation.h>

@class Media;
@interface WPMediaPersister : NSObject

+ (void)saveMedia:(Media *)imageMedia withImage:(UIImage *)image metadata:(NSDictionary *)metadata featured:(BOOL)isFeatured;

@end
