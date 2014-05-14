#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPAvatarSourceType) {
    WPAvatarSourceTypeUnknown,
    WPAvatarSourceTypeGravatar,
    WPAvatarSourceTypeBlavatar
};

/**
 WPAvatarSource takes care of downloading and caching gravatars and blavatars.
 
 A specific avatar is only downloaded once at max size, then resized.

 Since it uses WPImageSource, it also prevents two downloads for the same URL.
 */
@interface WPAvatarSource : NSObject

/**
 The maximum size you expect to display gravatars
 
 Defaults to 92
 */
@property (nonatomic, assign) CGFloat maxGravatarSize;

/**
 The maximum size you expect to display blavatars

 Defaults to 60
 */
@property (nonatomic, assign) CGFloat maxBlavatarSize;

/**
 If YES, the avatar source will resize avatars on the fly if it has a larger version available.
 Otherwise, you'll need to call one of the fetch methods and avatars will be resized on a background queue.
 
 @see fetchImageForGravatarEmail:withSize:
 @see fetchImageForBlavatarAddress:withSize:
 @see fetchImageForAvatarHash:ofType:withSize:
 */
@property (nonatomic, assign) BOOL resizesSynchronously;

/**
 Returns the shared source object.

 @return the shared source object.
 */
+ (instancetype)sharedSource;

/**
 Returns a gravatar if there's a valid cached copy.

 If resizesSynchronously is set to YES and there is a cached gravatar with a bigger size, it will be resized and returned.
 Otherwise it will return `nil`. You are expected to call fetchImageForGravatarEmail:withSize:success: if you need a gravatar that's not in the cache.

 @param email the email for the gravatar.
 @param size what size you are planning to display the gravatar.
 @return the gravatar if a cached version was found, or `nil` otherwise.

 @see fetchImageForGravatarEmail:withSize:success:
 @see parseURL:forAvatarHash:
 */
- (UIImage *)cachedImageForGravatarEmail:(NSString *)email withSize:(CGSize)size;

/**
 Returns a blavatar if there's a valid cached copy.

 If resizesSynchronously is set to YES and there is a cached blavatar with a bigger size, it will be resized and returned.
 Otherwise it will return `nil`. You are expected to call fetchImageForBlavatarAddress:withSize:success: if you need a blavatar that's not in the cache.

 @param url the address for the blavatar.
 @param size what size you are planning to display the blavatar.
 @return the blavatar if a cached version was found, or `nil` otherwise.

 @see fetchImageForBlavatarAddress:withSize:success:
 @see parseURL:forAvatarHash:
 */
- (UIImage *)cachedImageForBlavatarAddress:(NSString *)url withSize:(CGSize)size;

/**
 Returns an avatar if there's a valid cached copy.

 If resizesSynchronously is set to YES and there is a cached avatar with a bigger size, it will be resized and returned.
 Otherwise it will return `nil`. You are expected to call fetchImageForAvatarHash:ofType:withSize:success: if you need an avatar that's not in the cache.
 
 This is a generic method for both gravatars and blavatars. In the case of gravatars you need to pass a md5 hash of the email address and, for blavatars, a md5 hash of the hostname.

 @param hash a MD5 hash of the email or host.
 @param type the type of the hash. It only accepts `WPAvatarSourceTypeGravatar` and `WPAvatarSourceTypeBlavatar`.
 @param size what size you are planning to display the avatar.
 @return the avatar if a cached version was found, or `nil` otherwise.

 @see fetchImageForAvatarHash:ofType:withSize:success:
 @see parseURL:forAvatarHash:
 */
- (UIImage *)cachedImageForAvatarHash:(NSString *)hash ofType:(WPAvatarSourceType)type withSize:(CGSize)size;

/**
 Downloads a gravatar.

 @param email the email for the gravatar.
 @param size what size you are planning to display the gravatar.
 @param success a block to call when the gravatar is downloaded and resized.
 */
- (void)fetchImageForGravatarEmail:(NSString *)email withSize:(CGSize)size success:(void (^)(UIImage *image))success;

/**
 Downloads a blavatar.

 @param url the address for the blavatar.
 @param size what size you are planning to display the blavatar.
 @param success a block to call when the blavatar is downloaded and resized.
 */
- (void)fetchImageForBlavatarAddress:(NSString *)url withSize:(CGSize)size success:(void (^)(UIImage *image))success;

/**
 Downloads an avatar.

 See cachedImageForAvatarHash:ofType:withSize for an explanation of hash and type.

 @param hash the hash for the avatar.
 @param size what size you are planning to display the avatar.
 @param success a block to call when the avatar is downloaded and resized.
 @see cachedImageForAvatarHash:ofType:withSize
 @see parseURL:forAvatarHash:
 */
- (void)fetchImageForAvatarHash:(NSString *)hash ofType:(WPAvatarSourceType)type withSize:(CGSize)size success:(void (^)(UIImage *image))success;

/**
 Parses an existing gravatar URL and returns if it's for a gravatar or blavatar.
 
 @warning If result type is `WPAvatarSourceTypeUnknown`, the contents of `avatarHash` are undefined.

 @param url the URL to parse.
 @param avatarHash upon return contains the parsed hash if detected type is not unknown. It's safe to pass NULL if you are not interested in the hash
 @return the type of avatar URL.
 */
- (WPAvatarSourceType)parseURL:(NSURL *)url forAvatarHash:(NSString **)avatarHash;

@end
