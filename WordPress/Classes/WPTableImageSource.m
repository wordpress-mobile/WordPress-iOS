#import <MGImageUtilities/UIImage+ProportionalFill.h>

#import "WPTableImageSource.h"
#import "WPImageSource.h"

@implementation WPTableImageSource {
    dispatch_queue_t _processingQueue;
    NSCache *_imageCache;
    CGSize _maxSize;
    NSDate *_lastInvalidationOfIndexPaths;
}

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
    }
    return self;
}

- (UIImage *)imageForURL:(NSURL *)url withSize:(CGSize)size
{
    // Force rounding and only cache based on width
    size.width = ceilf(size.width);
    size.height = 0;
    
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
        CGSize receiverSize = size;
        if (size.height == 0) {
            CGFloat ratio = image.size.width / image.size.height;
            CGFloat height = round(size.width / ratio);
            receiverSize = CGSizeMake(size.width, height);
            
            NSMutableDictionary *dict = [_receiver mutableCopy];
            [dict setObject:NSStringFromCGSize(receiverSize) forKey:@"size"];
            _receiver = dict;
        }
        
        [self setCachedImage:image forURL:url withSize:_maxSize];
        [self processImage:image forURL:url receiver:_receiver];
    };
    
    void (^failureBlock)(NSError *) = ^(NSError *error) {
        DDLogError(@"Failed getting image %@: %@", url, error);
        [self handleImageDownloadFailedForReceiver:receiver error:error];
    };
    
    if (!isPrivate) {
        url = [self photonURLForURL:url withSize:requestSize];
    }
    
    [[WPImageSource sharedSource] downloadImageForURL:url
                                          withSuccess:successBlock
                                              failure:failureBlock];
}

- (void)invalidateIndexPaths
{
    _lastInvalidationOfIndexPaths = [NSDate date];
}

#pragma mark - Private methods

- (void)handleImageDownloadFailedForReceiver:(NSDictionary *)receiver error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableImageSource:imageFailedforIndexPath:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_lastInvalidationOfIndexPaths
                && [_lastInvalidationOfIndexPaths compare:receiver[@"date"]] == NSOrderedDescending) {
                // This index path has been invalidated, don't call the delegate
                return;
            }
            NSIndexPath *indexPath = [receiver objectForKey:@"indexPath"];
            [self.delegate tableImageSource:self imageFailedforIndexPath:indexPath error:error];
        });
    }
}

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
        }
        if (!CGSizeEqualToSize(resizedImage.size, size)) {
            resizedImage = [self resizeImage:image toSize:size];
        }

        [self setCachedImage:resizedImage forURL:url withSize:size];

        if (self.delegate && [self.delegate respondsToSelector:@selector(tableImageSource:imageReady:forIndexPath:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (_lastInvalidationOfIndexPaths
                    && [_lastInvalidationOfIndexPaths compare:receiver[@"date"]] == NSOrderedDescending) {
                    // This index path has been invalidated, don't call the delegate
                    return;
                }

                [self.delegate tableImageSource:self imageReady:resizedImage forIndexPath:receiver[@"indexPath"]];
            });
        }
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
    return [image imageCroppedToFitSize:size ignoreAlpha:YES];
}

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

/**
 Returns a Photon URL to resize the image at the given `url` to the specified `size`.
 */
- (NSURL *)photonURLForURL:(NSURL *)url withSize:(CGSize)size
{
    NSString *urlString = [url absoluteString];
    if ([urlString hasPrefix:@"http"]) {
        NSRange range = [urlString rangeOfString:@"http://"];
        if (range.location == 0) {
            urlString = [urlString substringFromIndex:range.length];
        } else {
            range = [urlString rangeOfString:@"https://"];
            if (range.location == 0) {
                // Photon doesn't support https
                return url;
            }
        }
    }
    // Photon will fail if the URL doesn't end in one of the accepted extensions
    NSArray *acceptedImageTypes = @[@"gif", @"jpg", @"jpeg", @"png"];
    if ([acceptedImageTypes indexOfObject:url.pathExtension] == NSNotFound) {
        if (![url scheme]) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
        }
        return url;
    }
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSUInteger width = scale * size.width;
    NSUInteger height = scale * size.height;

    // For some reason, Photon rejects resizing mshots
    if ([urlString rangeOfString:@"/mshots/"].location != NSNotFound) {
        if (height == 0) {
            urlString = [urlString stringByAppendingFormat:@"?w=%i", width];
        } else {
            urlString = [urlString stringByAppendingFormat:@"?w=%i&h=%i", width, height];
        }
        return [NSURL URLWithString:urlString];
    }

    // Strip original resizing parameters, or we might get an image too small
    NSRange imgpressRange = [urlString rangeOfString:@"?w="];
    if (imgpressRange.location != NSNotFound) {
        urlString = [urlString substringToIndex:imgpressRange.location];
    }
    
    if (height == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://i0.wp.com/%@?w=%i", urlString, width]];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://i0.wp.com/%@?resize=%i,%i", urlString, width, height]];
    }
    
    return url;
}

@end
