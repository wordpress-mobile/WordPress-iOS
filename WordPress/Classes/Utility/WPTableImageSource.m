#import <MGImageUtilities/UIImage+ProportionalFill.h>

#import "WPTableImageSource.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "PhotonImageURLHelper.h"
#import "WPAccount.h"
#import "WPImageSource.h"

static const NSInteger WPTableImageSourceMaxPhotonQuality = 100;
static const NSInteger WPTableImageSourceMinPhotonQuality = 1;

@implementation WPTableImageSource {
    dispatch_queue_t _processingQueue;
    NSCache *_imageCache;
    CGSize _maxSize;
    NSDate *_lastInvalidationOfIndexPaths;
}

#pragma mark - Lifecycle Methods

- (id)init
{
    return [self initWithMaxSize:CGSizeZero];
}

- (id)initWithMaxSize:(CGSize)size
{
    self = [super init];
    if (self) {
        _processingQueue = dispatch_queue_create("org.wordpress.table-image-processing", DISPATCH_QUEUE_CONCURRENT);
        _imageCache = [[NSCache alloc] init];
        _maxSize = CGSizeMake(ceil(size.width), ceil(size.height));
        _forceLargerSizeWhenFetching = YES;
        _photonQuality = WPTableImageSourceMaxPhotonQuality;
    }
    return self;
}

- (void)setPhotonQuality:(NSInteger)quality
{
    _photonQuality = MIN(MAX(quality, WPTableImageSourceMinPhotonQuality), WPTableImageSourceMaxPhotonQuality);
}

#pragma mark - Image fetching

- (UIImage *)imageForURL:(NSURL *)url withSize:(CGSize)size
{
    UIImage *image = [self cachedImageForURL:url withSize:size];
    if (image) {
        return image;
    }

    // We don't have an image that size
    if (self.resizesImagesSynchronously) {
        if (!CGSizeEqualToSize(_maxSize, CGSizeZero)) {
            image = [self cachedImageForURL:url withSize:_maxSize];
            if (image) {
                image = [self resizeImage:image toSize:size];
            }
        }
    }
    return image;
}

- (void)fetchImageForURL:(NSURL *)url withSize:(CGSize)size indexPath:(NSIndexPath *)indexPath isPrivate:(BOOL)isPrivate
{
    NSAssert(url!=nil, @"url shouldn't be nil");
    NSAssert(!CGSizeEqualToSize(size, CGSizeZero), @"size shouldn't be zero");

    // Failsafe
    if (url == nil || size.width == 0) {
        return;
    }

    // If the requested size has a 0 height, it means we know the desired width only.
    // Make the request with a 0 height and we'll update later once the image is loaded and
    // we can find its width/height ratio.
    CGSize requestSize;
    if (size.height == 0) {
        requestSize = CGSizeMake(MAX(size.width, _maxSize.width), size.height);
    } else {
        requestSize = CGSizeMake(MAX(size.width, _maxSize.width), MAX(size.height, _maxSize.height));
    }

    NSDictionary *receiver = @{@"size": NSStringFromCGSize(size), @"indexPath": indexPath, @"date": [NSDate date]};
    void (^successBlock)(UIImage *) = ^(UIImage *image) {
        NSDictionary *_receiver = receiver;
        if (size.height == 0) {
            CGFloat ratio = image.size.width / image.size.height;
            CGFloat height = round(size.width / ratio);
            CGSize receiverSize = CGSizeMake(size.width, height);

            NSMutableDictionary *dict = [_receiver mutableCopy];
            [dict setObject:NSStringFromCGSize(receiverSize) forKey:@"size"];
            _receiver = dict;
        }

        // NOTE: Due to memory issues related to animated gifs, just use the
        // first image of a gif until we have a better solution.
        // See: https://github.com/wordpress-mobile/WordPress-iOS/issues/2105
        if ([image.images count] > 0) {
            image = [image.images firstObject];
        }

        [self setCachedImage:image forURL:url withSize:_maxSize];
        [self processImage:image forURL:url receiver:_receiver];
    };

    void (^failureBlock)(NSError *) = ^(NSError *error) {
        DDLogError(@"Failed getting image %@: %@", url, error);
        [self handleImageDownloadFailedForReceiver:receiver error:error];
    };

    if (isPrivate) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        [[WPImageSource sharedSource] downloadImageForURL:url
                                                authToken:[[defaultAccount restApi] authToken]
                                              withSuccess:successBlock
                                                  failure:failureBlock];
    } else {
        url = [PhotonImageURLHelper photonURLWithSize:requestSize
                                          forImageURL:url
                                          forceResize:self.forceLargerSizeWhenFetching
                                         imageQuality:self.photonQuality];
        [[WPImageSource sharedSource] downloadImageForURL:url
                                              withSuccess:successBlock
                                                  failure:failureBlock];
    }
}

- (void)invalidateIndexPaths
{
    _lastInvalidationOfIndexPaths = [NSDate date];
}

#pragma mark - Private methods

- (void)handleImageDownloadFailedForReceiver:(NSDictionary *)receiver error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_lastInvalidationOfIndexPaths
            && [_lastInvalidationOfIndexPaths compare:receiver[@"date"]] == NSOrderedDescending) {
            // This index path has been invalidated, don't call the delegate
            return;
        }

        if (self.delegate && [self.delegate respondsToSelector:@selector(tableImageSource:imageFailedforIndexPath:error:)]) {
            NSIndexPath *indexPath = [receiver objectForKey:@"indexPath"];
            [self.delegate tableImageSource:self imageFailedforIndexPath:indexPath error:error];
        }
    });
}

#pragma mark - Image processing

/**
 Processes a downloaded image

 If necessary, the image is resized to the requested sizes in a background queue.
 */
- (void)processImage:(UIImage *)image forURL:(NSURL *)url receiver:(NSDictionary *)receiver
{
    dispatch_async(_processingQueue, ^{
        CGSize size;
        if ([receiver objectForKey:@"size"]){
            size = CGSizeFromString(receiver[@"size"]);
        } else {
            size = image.size;
        }

        UIImage *resizedImage = [self cachedImageForURL:url withSize:size];

        if (!resizedImage) {
            resizedImage = image;

            if (!CGSizeEqualToSize(resizedImage.size, size)) {
                resizedImage = [self resizeImage:image toSize:size];
            }

            [self setCachedImage:resizedImage forURL:url withSize:size];
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (_lastInvalidationOfIndexPaths
                && [_lastInvalidationOfIndexPaths compare:receiver[@"date"]] == NSOrderedDescending) {
                // This index path has been invalidated, don't call the delegate
                return;
            }

            if (self.delegate && [self.delegate respondsToSelector:@selector(tableImageSource:imageReady:forIndexPath:)]) {
                [self.delegate tableImageSource:self imageReady:resizedImage forIndexPath:receiver[@"indexPath"]];
            }
        });
    });
}

/**
 Wrapper method to resize an image

 It uses a modified version of MGImageUtilities to return opaque images.
 I tried to use UIImage+Resize, but had some problems if it wasn't run on the main thread.

 The wrapper is still here in case we need to switch the resizing mechanism in the future.
 */
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size
{
    return [image imageCroppedToFitSize:size ignoreAlpha:NO];
}

#pragma mark - Cache handling

- (void)setCachedImage:(UIImage *)image forURL:(NSURL *)url withSize:(CGSize)size
{
    // Force rounding and only cache based on width
    size.width = ceilf(size.width);
    size.height = 0;

    [_imageCache setObject:image forKey:[self cacheKeyForURL:url withSize:size]];
}

- (UIImage *)cachedImageForURL:(NSURL *)url withSize:(CGSize)size
{
    size.width = ceilf(size.width);
    size.height = 0;

    return [_imageCache objectForKey:[self cacheKeyForURL:url withSize:size]];
}

- (NSString *)cacheKeyForURL:(NSURL *)url withSize:(CGSize)size
{
    return [NSString stringWithFormat:@"%@|%@", [url absoluteString], NSStringFromCGSize(size)];
}

@end
