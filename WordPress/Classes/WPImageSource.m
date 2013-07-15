//
//  WPImageSource.m
//  WordPress
//
//  Created by Jorge Bernal on 6/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPImageSource.h"

@implementation WPImageSource {
    NSOperationQueue *_downloadingQueue;
    NSMutableSet *_urlDownloadsInProgress;
    NSMutableDictionary *_successBlocks;
    NSMutableDictionary *_failureBlocks;
}

+ (instancetype)sharedSource
{
    static WPImageSource *_sharedSource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSource = [[WPImageSource alloc] init];
    });
    return _sharedSource;
}

- (void)dealloc
{
    [_downloadingQueue cancelAllOperations];
}

- (id)init
{
    self = [super init];
    if (self) {
        _downloadingQueue = [[NSOperationQueue alloc] init];
        _urlDownloadsInProgress = [[NSMutableSet alloc] init];
        _successBlocks = [[NSMutableDictionary alloc] init];
        _failureBlocks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)downloadImageForURL:(NSURL *)url withSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(url != nil);

    [self addCallbackForURL:url withSuccess:success failure:failure];

    if (![_urlDownloadsInProgress containsObject:url]) {
        [_urlDownloadsInProgress addObject:url];
        [self startDownloadForURL:url];
    }
}

#pragma mark - Downloader

- (void)startDownloadForURL:(NSURL *)url
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
        AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                                  imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                      [self downloadedImage:image forURL:url];
                                                                                  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                      [self downloadFailedWithError:error forURL:url];
                                                                                  }];
        [_downloadingQueue addOperation:operation];
    });
}

- (void)downloadedImage:(UIImage *)image forURL:(NSURL *)url
{
    NSArray *successBlocks = [_successBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^success)(UIImage *) in successBlocks) {
            success(image);
        }
    });
}

- (void)downloadFailedWithError:(NSError *)error forURL:(NSURL *)url
{
    NSArray *failureBlocks = [_failureBlocks objectForKey:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeCallbacksForURL:url];
        for (void (^failure)(NSError *) in failureBlocks) {
            failure(error);
        }
    });
}

#pragma mark - Callback storage

- (void)addCallbackForURL:(NSURL *)url withSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *))failure
{
    if (success) {
        NSArray *successBlocks = [_successBlocks objectForKey:url];
        if (!successBlocks) {
            successBlocks = @[[success copy]];
        } else {
            successBlocks = [successBlocks arrayByAddingObject:[success copy]];
        }
        [_successBlocks setObject:successBlocks forKey:url];
    }

    if (failure) {
        NSArray *failureBlocks = [_failureBlocks objectForKey:url];
        if (!failureBlocks) {
            failureBlocks = @[[failure copy]];
        } else {
            failureBlocks = [failureBlocks arrayByAddingObject:[failure copy]];
        }
        [_failureBlocks setObject:failureBlocks forKey:url];
    }
}

- (void)removeCallbacksForURL:(NSURL *)url
{
    [_successBlocks removeObjectForKey:url];
    [_failureBlocks removeObjectForKey:url];
    [_urlDownloadsInProgress removeObject:url];
}

@end
