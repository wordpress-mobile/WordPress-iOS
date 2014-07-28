#import <Foundation/Foundation.h>

@interface VideoThumbnailServiceRemote : NSObject

- (void)getThumbnailForVideoAtURL:(NSURL *)url
                          success:(void (^)(NSURL *thumbnailURL, NSString *title))success
                          failure:(void (^)(NSError *error))failure;

@end
