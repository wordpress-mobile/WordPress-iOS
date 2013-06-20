//
//  WPTableImageSource.m
//  WordPress
//
//  Created by Jorge Bernal on 6/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableImageSource.h"

#import <MGImageUtilities/UIImage+ProportionalFill.h>
#import "UIImage+Resize.h"

@implementation WPTableImageSource {
    NSOperationQueue *_downloadingQueue;
    dispatch_queue_t _processingQueue;
    NSCache *_imageCache;

    // Stores arrays of cells that have requested this image
    // If a second fetch comes when we have one in progress for the same URL
    // it won't trigger a second download, but it'll call the delegate for both requests
    NSMutableDictionary *_urlDownloadRequests;

    // We also keep the URLs we are downloading in a set since it's much faster to check than a dictionary or array
    NSMutableSet *_urlDownloadsInProgress;

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
        _downloadingQueue = [[NSOperationQueue alloc] init];
        _processingQueue = dispatch_queue_create("org.wordpress.table-image-processing", DISPATCH_QUEUE_CONCURRENT);
        _imageCache = [[NSCache alloc] init];
        _urlDownloadsInProgress = [[NSMutableSet alloc] init];
        _urlDownloadRequests = [[NSMutableDictionary alloc] init];
        _maxSize = CGSizeMake(ceil(size.width), ceil(size.height));
    }
    return self;
}

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

- (void)fetchImageForURL:(NSURL *)url withSize:(CGSize)size indexPath:(NSIndexPath *)indexPath
{
    NSAssert(url!=nil, @"url shouldn't be nil");
    NSAssert(!CGSizeEqualToSize(size, CGSizeZero), @"size shouldn't be zero");

    // Failsafe
    if (url == nil || size.width == 0 || size.height == 0) {
        return;
    }

    NSDictionary *receiver = @{@"size": NSStringFromCGSize(size), @"indexPath": indexPath, @"time": [NSDate date]};
    if ([_urlDownloadsInProgress containsObject:url]) {
        // There is already a download for that URL
        NSArray *receivers = [_urlDownloadRequests objectForKey:url];
        if (receivers) {
            NSArray *receiversForThisIndexPath = [receivers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                return [[evaluatedObject objectForKey:@"indexPath"] isEqual:indexPath];
            }]];
            if ([receiversForThisIndexPath count] == 0) {
                receivers = [receivers arrayByAddingObject:receiver];
            }
        } else {
            receivers = @[receiver];
        }
        [_urlDownloadRequests setObject:receivers forKey:url];
    } else {
        NSArray *receivers = @[receiver];
        [_urlDownloadsInProgress addObject:url];
        [_urlDownloadRequests setObject:receivers forKey:url];

        CGSize requestSize = CGSizeMake(MAX(size.width, _maxSize.width), MAX(size.height, _maxSize.height));

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURLRequest *request = [NSURLRequest requestWithURL:[self photonURLForURL:url withSize:requestSize]];
            AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                                      imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                          [self processImage:image forURL:url];
                                                                                      } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                          WPFLog(@"Failed getting image %@: %@", url, error);
                                                                                      }];
            [_downloadingQueue addOperation:operation];
        });
    }
}

- (void)invalidateIndexPaths
{
    _lastInvalidationOfIndexPaths = [NSDate date];
}

#pragma mark - Private methods

/**
 Processes a downloaded image
 
 If necessary, the image is resized to the requested sizes in a background queue.
 */
- (void)processImage:(UIImage *)image forURL:(NSURL *)url
{
    __block NSArray *receivers;
    receivers = [_urlDownloadRequests objectForKey:url];
    [_urlDownloadsInProgress removeObject:url];
    [_urlDownloadRequests removeObjectForKey:url];

    if (receivers) {
        NSArray *uniqueSizes = [receivers valueForKeyPath:@"@distinctUnionOfObjects.size"];
        for (NSString *sizeString in uniqueSizes) {
            dispatch_async(_processingQueue, ^{
                CGSize size = CGSizeFromString(sizeString);

                UIImage *resizedImage = image;
                if (!CGSizeEqualToSize(resizedImage.size, size)) {
                    resizedImage = [self resizeImage:image toSize:size];
                }

                [self setCachedImage:resizedImage forURL:url withSize:size];

                NSArray *receiversForThisSize = [receivers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                        return [[evaluatedObject objectForKey:@"size"] isEqual:sizeString];
                    }]];

                if (self.delegate && [self.delegate respondsToSelector:@selector(tableImageSource:imageReady:forIndexPath:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        for (NSDictionary *receiver in receiversForThisSize) {
                            if (_lastInvalidationOfIndexPaths
                                && [_lastInvalidationOfIndexPaths compare:receiver[@"date"]] == NSOrderedAscending) {
                                // This index path has been invalidated, don't call the delegate
                                continue;
                            }

                            [self.delegate tableImageSource:self imageReady:resizedImage forIndexPath:receiver[@"indexPath"]];
                        }
                    });
                }
            });
        }
    }
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
    [_imageCache setObject:image forKey:[self cacheKeyForURL:url withSize:size]];
}

- (UIImage *)cachedImageForURL:(NSURL *)url withSize:(CGSize)size
{
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
    // If the URL doesn't have a http prefix, add it
    if (![url scheme]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
    }

    NSString *urlString = [url absoluteString];
    CGFloat scale = [[UIScreen mainScreen] scale];
    NSUInteger width = scale * size.width;
    NSUInteger height = scale * size.height;

    // For some reason, Photon rejects resizing mshots
    if ([urlString rangeOfString:@"/mshots/"].location != NSNotFound) {
        urlString = [urlString stringByAppendingFormat:@"?w=%i&h=%i", width, height];
        return [NSURL URLWithString:urlString];
    }

    // Strip original resizing parameters, or we might get an image too small
    NSRange imgpressRange = [urlString rangeOfString:@"?w="];
    if (imgpressRange.location != NSNotFound) {
        urlString = [urlString substringToIndex:imgpressRange.location];
    }

    return [NSURL URLWithString:[NSString stringWithFormat:@"https://i0.wp.com/%@?resize=%i,%i", urlString, width, height]];
}

@end
