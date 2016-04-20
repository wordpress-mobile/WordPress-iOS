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


/**
 Create a "photonized" URL from the passed arguments.

 @param size The desired size of the photon image. If height is set to zero the
        returned image will have a height proportional to the requested width.
 @param url The URL to the source image.
 @param forceResize By default Photon does not upscale beyond a certain percentage. 
        Setting this to YES forces the returned image to match the specified size.
 @param quality An integer value 1 - 100. Passed values are constrained to this range.

 @return A URL to the photon service with the source image as its subject.
 */
+ (NSURL *)photonURLWithSize:(CGSize)size
                 forImageURL:(NSURL *)url
                 forceResize:(BOOL)forceResize
                imageQuality:(NSUInteger)quality;

@end
