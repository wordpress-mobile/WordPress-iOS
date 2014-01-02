//
//  ReaderMediaQueue.m
//  WordPress
//
//  Created by aerych on 11/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderMediaQueue.h"
#import "WPTableImageSource.h"

// Barebones storage class for items in the queues.
typedef void (^ReaderMediaViewSuccessBlock)(ReaderMediaView *readerMediaView);
typedef void (^ReaderMediaViewFailureBlock)(ReaderMediaView *readerMediaView, NSError *error);

@interface ReaderMediaQueueItem : NSObject

@property (nonatomic, strong) ReaderMediaView *mediaView;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic) CGSize size;
@property (nonatomic) BOOL isPrivate;
@property (nonatomic, copy) ReaderMediaViewSuccessBlock success;
@property (nonatomic, copy) ReaderMediaViewFailureBlock failure;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) BOOL failedToLoad;

@end

@implementation ReaderMediaQueueItem

- (id)initWithMediaView:(ReaderMediaView *)mediaView
                    url:(NSURL *)url
                   size:(CGSize)size
              isPrivate:(BOOL)isPrivate
                success:(void (^)(ReaderMediaView *readerMediaView))success
                failure:(void (^)(ReaderMediaView *readerMediaView, NSError *error))failure {
    self = [super init];
    if (self) {
        _mediaView = mediaView;
        _url = url;
        _isPrivate = isPrivate;
        _size = size;
        _success = success;
        _failure = failure;
    }
    return self;
}

@end


@interface ReaderMediaQueue()<WPTableImageSourceDelegate>

@property (nonatomic) NSInteger counter;
@property (nonatomic, strong) NSMutableArray *holdingQueue;
@property (nonatomic, strong) NSMutableArray *activeQueue;
@property (nonatomic, strong) WPTableImageSource *imageSource;

@end

@implementation ReaderMediaQueue

- (id)init {
    self = [super init];
    if (self) {
        _activeQueue = [NSMutableArray array];
        _holdingQueue = [NSMutableArray array];
        _batchSize = 10;
        _counter = 0;
        _imageSource = [[WPTableImageSource alloc] init];
        _imageSource.delegate = self;
    }
    return self;
}


- (id)initWithDelegate:(id<ReaderMediaQueueDelegate>)delegate {
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}


- (void)setBatchSize:(NSInteger)batchSize {
    _batchSize = MAX(MIN(batchSize, 20), 1);
}


- (void)enqueueMedia:(ReaderMediaView *)mediaView
             withURL:(NSURL *)url
    placeholderImage:(UIImage *)image
                size:(CGSize)size
           isPrivate:(BOOL)isPrivate
             success:(void (^)(ReaderMediaView *))success
             failure:(void (^)(ReaderMediaView *, NSError *))failure {

    mediaView.contentURL = url;
    if (image) {
        [mediaView setPlaceholder:image];
    }

    ReaderMediaQueueItem *item = [[ReaderMediaQueueItem alloc] initWithMediaView:mediaView
                                                                             url:url
                                                                            size:size
                                                                       isPrivate:isPrivate
                                                                         success:success
                                                                         failure:failure];
    if ([self.activeQueue count] < self.batchSize) {
        [self addToActiveQueue:item];
    } else {
        [self addToHoldingQueue:item];
    }
}


- (void)addToActiveQueue:(ReaderMediaQueueItem *)item {
    [self.activeQueue addObject:item];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.activeQueue count]-1 inSection:0];
    [self.imageSource fetchImageForURL:item.url withSize:item.size indexPath:indexPath isPrivate:item.isPrivate];
}


- (void)addToHoldingQueue:(ReaderMediaQueueItem *)item {
    [self.holdingQueue addObject:item];
}

- (void)discardQueuedItems {
    [self.imageSource invalidateIndexPaths];
    [self.holdingQueue removeAllObjects];
    [self.activeQueue removeAllObjects];
}

#pragma mark - WPTableImageSourceDelegate Methods

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageFailedForIndexPath:(NSIndexPath *)indexPath {
    self.counter++;
    ReaderMediaQueueItem *item = [self.activeQueue objectAtIndex:indexPath.row];
    item.failedToLoad = YES;
}

- (void)tableImageSource:(WPTableImageSource *)tableImageSource
              imageReady:(UIImage *)image
            forIndexPath:(NSIndexPath *)indexPath {
    self.counter++;
    
    ReaderMediaQueueItem *item = [self.activeQueue objectAtIndex:indexPath.row];
    item.image = image;
    
    if ([self.delegate respondsToSelector:@selector(readerMediaQueue:didLoadMedia::)]) {
        [self.delegate readerMediaQueue:self didLoadMedia:item.mediaView];
    }
    
    // Did we load everything in the active queue?
    if (self.counter < [self.activeQueue count]) {
        return;
    }
    
    // Batch loaded
    NSMutableArray *mediaArray = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.activeQueue count]; i++) {
        ReaderMediaQueueItem *item = [self.activeQueue objectAtIndex:i];
        if (item.failedToLoad) {
            if (item.failure) {
                item.failure(item.mediaView, nil); //TODO: return the actual error as well?
            }
        } else {
            [item.mediaView setImage:item.image];
            if (item.success) {
                item.success(item.mediaView);
            }
        }
        // clear blocks because paranoid
        item.success = nil;
        item.failure = nil;

        [mediaArray addObject:item.mediaView];
    }

    if ([self.delegate respondsToSelector:@selector(readerMediaQueue:didLoadBatch:)]) {
        [self.delegate readerMediaQueue:self didLoadBatch:mediaArray];
    }
    
    // Reset for the next batch.
    self.counter = 0;
    [self.activeQueue removeAllObjects];
    
    // Are there more to load?
    if ([self.holdingQueue count] == 0) {
        if ([self.delegate respondsToSelector:@selector(readerMediaQueueDidFinish:)]) {
            [self.delegate readerMediaQueueDidFinish:self];
        }
        return;
    }
    
    NSInteger num = MIN(self.batchSize, [self.holdingQueue count]);
    for (NSInteger i = 0; i < num; i++) {
        [self addToActiveQueue:[self.holdingQueue objectAtIndex:0]];
        [self.holdingQueue removeObjectAtIndex:0];
    }
}

@end
