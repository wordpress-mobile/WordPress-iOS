#import <Foundation/Foundation.h>

/**
 Helper class for creating a photon URL from the passed image URL.
 */
@interface PhotonImageURLHelper : NSObject

/**
 Create a "photonized" URL from the passed image URL and size.
 The source image is resized and the URL is constructed with a
 default 80% quality as a speed/size optimization.

 @param size The desired size of the photon image. 
 @param url The URL to the source image.
 @return A URL to the photon service with the source image as its subject.
 */
+ (NSURL *)photonURLWithSize:(CGSize)size forImageURL:(NSURL *)url;

@end
