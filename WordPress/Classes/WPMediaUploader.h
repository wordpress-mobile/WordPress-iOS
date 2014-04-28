#import <Foundation/Foundation.h>

@class Media;
@interface WPMediaUploader : NSObject

+ (void)uploadMedia:(Media *)media;

@end
