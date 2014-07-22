#import <MGImageUtilities/UIImage+ProportionalFill.h>

#import "WPTableImageSource.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "WPImageSource.h"

static NSUInteger const WPTableImageSourceBatchSize = 10;

@interface WPTableImageSource()
@property (nonatomic, strong) NSMutableArray *pendingDownloads;
@property (nonatomic, strong) NSMutableArray *currentDownloads;
@property (nonatomic) NSUInteger downloadCounter;
@end

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
        _currentDownloads = [NSMutableArray array];
        _pendingDownloads = [NSMutableArray array];
    }
    return self;
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

    NSDictionary *queueItem = @{@"url":url, @"size":NSStringFromCGSize(size), @"indexPath":indexPath, @"isPrivate":@(isPrivate)};

    if ([self.currentDownloads count] < WPTableImageSourceBatchSize) {
        [self requestImage:queueItem];
    } else {
        [self enqueueImageDownload:queueItem];
    }
}

- (void)invalidateIndexPaths
{
    _lastInvalidationOfIndexPaths = [NSDate date];
    self.downloadCounter = 0;
    [self.pendingDownloads removeAllObjects];
    [self.currentDownloads removeAllObjects];
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

        self.downloadCounter++;
        [self updateCurrentDownloads];
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

            self.downloadCounter++;
            [self updateCurrentDownloads];
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


#pragma mark - Photon URL Construction

- (BOOL)isURLPhotonURL:(NSURL *)url
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"i\\d+\\.wp\\.com" options:NSRegularExpressionCaseInsensitive error:&error];
    });
    NSString *host = [url host];
    if ([host length] > 0) { // relative URLs may not have a host
        NSInteger count = [regex numberOfMatchesInString:host options:NSMatchingCompleted range:NSMakeRange(0, [host length])];
        if (count > 0) {
            return YES;
        }
    }
    return NO;
}

/**
 Returns a Photon URL to resize the image at the given `url` to the specified `size`.
*/
- (NSURL *)photonURLForURL:(NSURL *)url withSize:(CGSize)size
{
    // Photon will fail if the URL doesn't end in one of the accepted extensions
    NSArray *acceptedImageTypes = @[@"gif", @"jpg", @"jpeg", @"png"];
    if ([acceptedImageTypes indexOfObject:url.pathExtension] == NSNotFound) {
        if (![url scheme]) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
        }
        return url;
    }

    CGFloat scale = [[UIScreen mainScreen] scale];
    NSUInteger width = scale * size.width;
    NSUInteger height = scale * size.height;
    NSString *urlString = [url absoluteString];

    // If the URL is already a Photon URL reject its photon params, and substitute our own.
    if ([self isURLPhotonURL:url]) {
        NSRange range = [urlString rangeOfString:@"?" options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            BOOL useSSL = ([urlString rangeOfString:@"ssl=1"].location != NSNotFound);
            urlString = [urlString substringToIndex:range.location];
            NSString *queryString = [self photonQueryStringWithWidth:width height:height usingSSL:useSSL];
            urlString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
            return [NSURL URLWithString:urlString];
        }
        // Saftey net. Don't photon photon!
        return url;
    }

    // Compose the URL
    NSRange range = [urlString rangeOfString:@"://"];
    if (range.location != NSNotFound && range.location < 6) {
        urlString = [urlString substringFromIndex:(range.location + range.length)];
    }

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

    BOOL useSSL = [[url scheme] isEqualToString:@"https"];
    NSString *queryString = [self photonQueryStringWithWidth:width height:height usingSSL:useSSL];
    NSString *photonURLString = [NSString stringWithFormat:@"https://i0.wp.com/%@?%@", urlString, queryString];
    return [NSURL URLWithString:photonURLString];
}

/**
 Constructs a Photon query string from the  supplied parameters.
 */
- (NSString *)photonQueryStringWithWidth:(NSUInteger)width height:(NSUInteger)height usingSSL:(BOOL)useSSL
{
    NSString *queryString;
    if (height == 0) {
        queryString = [NSString stringWithFormat:@"w=%i", width];
    } else {
        NSString *method = self.forceLargerSizeWhenFetching ? @"resize" : @"fit";
        queryString = [NSString stringWithFormat:@"%@=%i,%i", method, width, height];
    }

    if (useSSL) {
        queryString = [NSString stringWithFormat:@"%@&ssl=1", queryString];
    }

    return queryString;
}


#pragma mark - Download queue wrangling

/**
 Adds a requested image to the pending queue.
 */
- (void)enqueueImageDownload:(NSDictionary *)queueItem
{
    [self.pendingDownloads addObject:queueItem];
}

/**
    Downloads the image specified.
 */
- (void)requestImage:(NSDictionary *)queueItem
{
    [self.currentDownloads addObject:queueItem];

    NSURL *url = [queueItem objectForKey:@"url"];
    CGSize size = CGSizeFromString([queueItem stringForKey:@"size"]);
    NSIndexPath *indexPath = [queueItem objectForKey:@"indexPath"];
    BOOL isPrivate = [[queueItem numberForKey:@"isPrivate"] boolValue];

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

        [self setCachedImage:image forURL:url withSize:_maxSize];
        [self processImage:image forURL:url receiver:_receiver];
    };

    void (^failureBlock)(NSError *) = ^(NSError *error) {
        DDLogError(@"Failed getting image %@: %@", url, error);
        self.downloadCounter++;
        [self handleImageDownloadFailedForReceiver:receiver error:error];
    };

    url = [self photonURLForURL:url withSize:requestSize];

    if (isPrivate) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
        [[WPImageSource sharedSource] downloadImageForURL:url
                                                authToken:[[defaultAccount restApi] authToken]
                                              withSuccess:successBlock
                                                  failure:failureBlock];
    } else {
        [[WPImageSource sharedSource] downloadImageForURL:url
                                              withSuccess:successBlock
                                                  failure:failureBlock];
    }
}

/**
 Checks the progress of the current batch of downloads. 
 Starts the next batch when the current batch completes. 
 Notifies the delegate when a batch completes, and when the queue is emptied.
 */
- (void)updateCurrentDownloads
{
    // Did we load everything in the active queue?
    if (self.downloadCounter < [self.currentDownloads count]) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(tableImageSource:didLoadImagesAtIndexPaths:)]) {
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSDictionary *queueItem in self.currentDownloads) {
            NSIndexPath *indexPath = [queueItem objectForKey:@"indexPath"];
            [indexPaths addObject:indexPath];
        }
        [self.delegate tableImageSource:self didLoadImagesAtIndexPaths:indexPaths];
    }

    // Reset for the next batch.
    self.downloadCounter = 0;
    [self.currentDownloads removeAllObjects];

    // Bail if nothing else to do
    if ([self.pendingDownloads count] == 0) {
        if ([self.delegate respondsToSelector:@selector(tableImageSourceFinishedLoadingImages:)]) {
            [self.delegate tableImageSourceFinishedLoadingImages:self];
        }
        return;
    }

    // Load the next batch
    NSInteger num = MIN(WPTableImageSourceBatchSize, [self.pendingDownloads count]);
    for (NSInteger i = 0; i < num; i++) {
        NSDictionary *queueItem = [self.pendingDownloads firstObject];
        if (!queueItem) { // just in case the count is off for some reason.
            break;
        }
        [self.pendingDownloads removeObject:queueItem];
        [self requestImage:queueItem];
    }
}

@end
