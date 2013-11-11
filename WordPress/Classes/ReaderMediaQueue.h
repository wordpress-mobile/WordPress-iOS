//
//  ReaderMediaQueue.h
//  WordPress
//
//  Created by aerych on 11/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReaderMediaView.h"

@class ReaderMediaQueue;

@protocol ReaderMediaQueueDelegate <NSObject>
@optional
- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadMedia:(ReaderMediaView *)media;
- (void)readerMediaQueue:(ReaderMediaQueue *)mediaQueue didLoadBatch:(NSArray *)batch;
- (void)readerMediaQueueDidFinish:(ReaderMediaQueue *)mediaQueue;

@end

@interface ReaderMediaQueue : NSObject

@property (nonatomic, weak) id<ReaderMediaQueueDelegate> delegate;
@property (nonatomic) NSInteger batchSize;

- (id)initWithDelegate:(id<ReaderMediaQueueDelegate>)delegate;

- (void)enqueueMedia:(ReaderMediaView *)mediaView
             withURL:(NSURL *)url
    placeholderImage:(UIImage *)image
                size:(CGSize)size
           isPrivate:(BOOL)isPrivate
             success:(void (^)(ReaderMediaView *))success
             failure:(void (^)(ReaderMediaView *, NSError *))failure;

- (void)abort;

@end
