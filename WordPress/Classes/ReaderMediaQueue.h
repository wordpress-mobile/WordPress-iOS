#import <Foundation/Foundation.h>
#import "ReaderMediaView.h"

@class ReaderMediaQueue;

@protocol ReaderMediaQueueDelegate <NSObject>
@optional

/**
 Called when the image for an individual ReaderMediaView has been loaded.
 Its important to note that any success/failure blocks for the ReaderMediaView 
 have not yet been called.
 
 @param mediaQueue The ReaderMediaQueue
 @param media  The ReaderMediaView that was updated.
 */
- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadMedia:(ReaderMediaView *)media;

/**
 Called when the images for a batch of ReaderMediaView's have been loaded.
 
 @param mediaQueue The ReaderMediaQueue
 @param batch  The array of ReaderMediaViews that were loaded in the most recent batch.
 */
- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch;

/**
 Called when the queue has finished loading images. 
 
 @param mediaQueue The ReaderMediaQueue.
 */
- (void)readerMediaQueueDidFinish:(ReaderMediaQueue *)mediaQueue;

@end

@interface ReaderMediaQueue : NSObject

/**
 The delegate for the queue.
 */
@property (nonatomic, weak) id<ReaderMediaQueueDelegate> delegate;

/**
 The max number of downloads to process at a time. Default is 10.
 */
@property (nonatomic) NSInteger batchSize;

- (id)initWithDelegate:(id<ReaderMediaQueueDelegate>)delegate;

/**
 Enqueues a ReaderMediaView and downloads its image.
 Images are downloaded in batches. Enqueued items start downloading immediately if 
 the current number of downloading items is less than the `batchSize`.
 Once all items in a batch have finished downloading, success/failure blocks are called.

 @param mediaView the ReaderMediaView instance for which an image should be downloaded.
 @param url the URL for the image.
 @param size what size you are planning to display the image.
 @param isPrivate if the image is hosted on a private blog. photon will be skipped for private blogs.
 @param success a block to execute when the image is downloaded.
 @param failure a block to call if image download fails.
 */
- (void)enqueueMedia:(ReaderMediaView *)mediaView
             withURL:(NSURL *)url
    placeholderImage:(UIImage *)image
                size:(CGSize)size
           isPrivate:(BOOL)isPrivate
             success:(void (^)(ReaderMediaView *))success
             failure:(void (^)(ReaderMediaView *, NSError *))failure;


/**
 Discards any queued media and calls invalidateIndexPath on the media source. 
 Any downloads already started by WPImageSource continue but callbacks are ignored.
 */
- (void)discardQueuedItems;

@end
