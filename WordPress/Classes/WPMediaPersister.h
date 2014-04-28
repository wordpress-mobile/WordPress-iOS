#import <Foundation/Foundation.h>

@class Media;
@interface WPMediaPersister : NSObject

+ (void)saveMedia:(Media *)imageMedia withImage:(UIImage *)image andMetadata:(NSDictionary *)metadata;

@end
