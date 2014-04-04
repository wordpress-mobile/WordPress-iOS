#import <Foundation/Foundation.h>

/**
 WPImageSource Error Codes
 */
typedef NS_ENUM(NSUInteger, WPImageSourceError) {
    WPImageSourceErrorUnknown,
    WPImageSourceErrorNilImage
};

extern NSString * const WPImageSourceErrorDomain;

/**
 WPImageSource takes care of downloading images.
 
 It's a simple wrapper over AFImageRequestOperation that prevents duplicate requests. When a image URL is requested, it checks if there is a download in progress for that same URL.
 In that case, it doesn't start a new download but adds the sender to the list of objects to notify.
 
 Otherwise, a download is started.
 */
@interface WPImageSource : NSObject

/**
 Returns the shared source object.
 
 @return the shared source object.
 */
+ (instancetype)sharedSource;

/**
 Schedules a download for the given url, if there isn't one in progress.
 
 Note that the success or failure block will be called whether the call initiated a network request or reused an existing one.

 @param url the URL to download.
 @param success the block to execute if the download was successful.
 @param failure the block to execute if the download failed.
 */
- (void)downloadImageForURL:(NSURL *)url
                withSuccess:(void (^)(UIImage *image))success
                    failure:(void (^)(NSError *error))failure;

/**
 Schedules an authenticated download for the given URL, if there isn't one in progress.
 
 Assumes HTTPS should be used for the protocol.
 
 @param url the URL to download
 @param authToken the authentication token (Bearer) to use (generally assumes this is used for WP.com)
 @param success the block to execute if the download was successful
 @param failure the block to execute if the download failed
 */

- (void)downloadImageForURL:(NSURL *)url
                  authToken:(NSString *)authToken
                withSuccess:(void (^)(UIImage *))success
                    failure:(void (^)(NSError *))failure;

@end
