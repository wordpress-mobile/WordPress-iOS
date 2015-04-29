#import <Foundation/Foundation.h>

@interface PhotonImageURLHelper : NSObject
+ (NSURL *)photonURLWithSize:(CGSize)size forImageURL:(NSURL *)url;
@end
