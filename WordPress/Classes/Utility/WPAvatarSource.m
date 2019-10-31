#import "WPAvatarSource.h"

@import WordPressUI;
@import WordPressShared;



static CGSize BlavatarMaxSize = {60, 60};
static CGSize GravatarMaxSize = {92, 92};
static NSString *const GravatarBaseUrl = @"http://gravatar.com";

@interface WPAvatarSource () <WPAvatarSourceTesting>

@end

@implementation WPAvatarSource {
    NSCache *_gravatarCache;
    NSCache *_blavatarCache;
    dispatch_queue_t _processingQueue;
}

+ (instancetype)sharedSource
{
    static WPAvatarSource *_sharedSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSource = [[WPAvatarSource alloc] init];
    });
    return _sharedSource;
}

- (id)init
{
    self = [super init];
    if (self) {
        _gravatarCache = [[NSCache alloc] init];
        _gravatarCache.name = @"GravatarCache";
        _blavatarCache = [[NSCache alloc] init];
        _blavatarCache.name = @"BlavatarCache";
        _processingQueue = dispatch_queue_create("org.wordpress.gravatar-resizing", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (CGFloat)maxBlavatarSize
{
    return BlavatarMaxSize.width;
}

- (void)setMaxBlavatarSize:(CGFloat)maxBlavatarSize
{
    BlavatarMaxSize = CGSizeMake(maxBlavatarSize, maxBlavatarSize);
}

- (CGFloat)maxGravatarSize
{
    return GravatarMaxSize.width;
}

- (void)setMaxGravatarSize:(CGFloat)maxGravatarSize
{
    GravatarMaxSize = CGSizeMake(maxGravatarSize, maxGravatarSize);
}

- (UIImage *)cachedImageForGravatarEmail:(NSString *)email withSize:(CGSize)size
{
    return [self cachedImageForAvatarHash:[self hashForEmailAddressOrSiteURL:email] ofType:WPAvatarSourceTypeGravatar withSize:size];
}

- (UIImage *)cachedImageForBlavatarAddress:(NSString *)url withSize:(CGSize)size
{
    return [self cachedImageForAvatarHash:[self hashForEmailAddressOrSiteURL:url] ofType:WPAvatarSourceTypeBlavatar withSize:size];
}

- (UIImage *)cachedImageForAvatarHash:(NSString *)hash ofType:(WPAvatarSourceType)type withSize:(CGSize)size
{
    NSCache *cache = [self cacheForType:type];
    UIImage *image = [cache objectForKey:[self cacheKeyForHash:hash size:size]];
    if (image) {
        return image;
    }

    if (self.resizesSynchronously) {
        CGSize maxSize = [self maxSizeForType:type];
        if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
            image = [cache objectForKey:[self cacheKeyForHash:hash size:maxSize]];
            if (image) {
                image = [self resizeImage:image toSize:size];
            }
        }
    }
    return image;
}

- (void)fetchImageForGravatarEmail:(NSString *)email withSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    [self fetchImageForAvatarHash:[self hashForEmailAddressOrSiteURL:email] ofType:WPAvatarSourceTypeGravatar withSize:size success:success];
}

- (void)fetchImageForBlavatarAddress:(NSString *)url withSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    [self fetchImageForAvatarHash:[self hashForEmailAddressOrSiteURL:url] ofType:WPAvatarSourceTypeBlavatar withSize:size success:success];
}

- (void)fetchImageForAvatarHash:(NSString *)hash ofType:(WPAvatarSourceType)type withSize:(CGSize)size success:(void (^)(UIImage *image))success
{
    NSParameterAssert(hash != nil);
    NSParameterAssert(size.width > 0);
    NSParameterAssert(size.height > 0);

    NSURL *url = [self URLWithHash:hash type:type];
    CGSize maxSize = [self maxSizeForType:type];
    [[WPImageSource sharedSource] downloadImageForURL:url
                                          withSuccess:^(UIImage *image) {
                                              [self setCachedImage:image forHash:hash type:type size:maxSize];
                                              [self processImage:image forHash:hash type:type size:size success:success];
                                          } failure:^(NSError *error) {
                                              if (success) {
                                                  success(nil);
                                              }
                                          }];
}

- (WPAvatarSourceType)parseURL:(NSURL *)url forAvatarHash:(NSString **)avatarHash
{
    WPAvatarSourceType sourceType = WPAvatarSourceTypeUnknown;

    NSArray *components = [url pathComponents];
    if ([components count] > 2) {
        NSString *type = components[1];
        NSString *hash = components[2];
        if ([hash length] == 32) {
            // Looks like a valid hash
            if ([type isEqualToString:@"avatar"]) {
                if (avatarHash) *avatarHash = hash;
                sourceType = WPAvatarSourceTypeGravatar;
            } else if ([type isEqualToString:@"blavatar"]) {
                if (avatarHash) *avatarHash = hash;
                sourceType = WPAvatarSourceTypeBlavatar;
            }
        }
    }

    return sourceType;
}

#pragma mark - Private methods

- (void)processImage:(UIImage *)image
             forHash:(NSString *)hash
                type:(WPAvatarSourceType)type
                size:(CGSize)size success:(void (^)(UIImage *image))success
{
    dispatch_async(_processingQueue, ^{
        // This method might be called many consecutive times for the same size
        // Check the cache before resizing twice
        UIImage *resizedImage = [self cachedImageForAvatarHash:hash ofType:type withSize:size];
        if (!resizedImage) {
            resizedImage = image;

            // Check if we received an image the size we want
            // It should only happen when size == maxSize
            if (!CGSizeEqualToSize(resizedImage.size, size)) {
                resizedImage = [self resizeImage:image toSize:size];
            }

            [self setCachedImage:resizedImage forHash:hash type:type size:size];
        }

        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(resizedImage);
            });
        }
   });
}

#pragma mark - Caching methods

- (NSCache *)cacheForType:(WPAvatarSourceType)type
{
    NSCache *cache;

    if (type == WPAvatarSourceTypeGravatar) {
        cache = _gravatarCache;
    } else if (type == WPAvatarSourceTypeBlavatar) {
        cache = _blavatarCache;
    }

    return cache;
}

- (NSString *)cacheKeyForHash:(NSString *)hash size:(CGSize)size
{
    return [NSString stringWithFormat:@"%@|%@", hash, NSStringFromCGSize(size)];
}

- (void)setCachedImage:(UIImage *)image forHash:(NSString *)hash type:(WPAvatarSourceType)type size:(CGSize)size
{
    NSCache *cache = [self cacheForType:type];
    NSString *cacheKey = [self cacheKeyForHash:hash size:size];
    [cache setObject:image forKey:cacheKey];
}

#pragma mark - Size helpers

- (CGSize)maxSizeForType:(WPAvatarSourceType)type
{
    CGSize size = CGSizeZero;

    if (type == WPAvatarSourceTypeGravatar) {
        size = GravatarMaxSize;
    } else if (type == WPAvatarSourceTypeBlavatar) {
        size = BlavatarMaxSize;
    }

    return size;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size
{
    return [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:size interpolationQuality:kCGInterpolationHigh];
}

- (NSURL *)URLWithHash:(NSString *)hash type:(WPAvatarSourceType)type
{
    CGSize size = [self maxSizeForType:type];
    NSString *url = GravatarBaseUrl;

    if (type == WPAvatarSourceTypeGravatar) {
        url = [url stringByAppendingString:@"/avatar/"];
    } else if (type == WPAvatarSourceTypeBlavatar) {
        url = [url stringByAppendingString:@"/blavatar/"];
    }

    url = [url stringByAppendingFormat:@"%@?s=%d&d=identicon", hash, (int)(size.width * [[UIScreen mainScreen] scale])];
    return [NSURL URLWithString:url];
}

- (NSString *)hashForEmailAddressOrSiteURL:(NSString *)stringToHash
{
    NSString *sanitizedString = [[stringToHash lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [sanitizedString md5Hash];
}

#pragma mark - WPAvatarSourceTesting

- (void)purgeCaches
{
    [_gravatarCache removeAllObjects];
    [_blavatarCache removeAllObjects];
}

@end
