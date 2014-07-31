#import "WPWebSnapshotter.h"
#import "WPWebSnapshotWorker.h"
#import "WPWebSnapshotRequest.h"

static const NSUInteger kWPWebSnapshotterURLCacheMemoryCapacity = 20*1000*1000;
static const NSUInteger kWPWebSnapshotterURLCacheDiskCapacity = 100*1000*1000;
static NSString* const WPWebSnapshotterURLCacheDiskPath = @"Media";

static const NSUInteger kWPWebSnapshotterCacheTotalCostLimit = 20*1000*1000;

@interface WPWebSnapshotter ()

@property (nonatomic, readwrite) WPWebSnapshotWorker *worker;
@property (nonatomic) NSMutableArray *requestQueue;
@property (nonatomic) NSCache *cache;

@end

@implementation WPWebSnapshotter

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:kWPWebSnapshotterURLCacheMemoryCapacity
                                                          diskCapacity:kWPWebSnapshotterURLCacheDiskCapacity
                                                              diskPath:WPWebSnapshotterURLCacheDiskPath];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = cache;
        configuration.timeoutIntervalForRequest = 10.0f;
        configuration.timeoutIntervalForResource = 45.0f;
        
        _worker = [[WPWebSnapshotWorker alloc] init];
        _requestQueue = [NSMutableArray array];
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = kWPWebSnapshotterCacheTotalCostLimit;
    }
    return self;
}

- (void)captureSnapshotOfURLRequest:(NSURLRequest *)urlRequest
                       snapshotSize:(CGSize)snapshotSize
                  completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    [self captureSnapshotOfURLRequest:urlRequest
                         snapshotSize:snapshotSize
           didFinishLoadingJavascript:nil
                    completionHandler:completionHandler];
}

- (void)captureSnapshotOfURLRequest:(NSURLRequest *)urlRequest
                       snapshotSize:(CGSize)snapshotSize
         didFinishLoadingJavascript:(NSString *)javascript
                  completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    WPWebSnapshotRequest *request = [WPWebSnapshotRequest snapshotRequestWithURLRequest:urlRequest
                                                                           snapshotSize:snapshotSize
                                                                    didFinishJavascript:javascript
                                                                      completionHandler:completionHandler];
    
    UIView *cachedView = [self cachedSnapshotForRequest:request];
    if (cachedView) {
        WPWebSnapshotterSnapshotCompletionHandler callback = [completionHandler copy];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            callback(cachedView);
        });
    } else {
        [self enqueueSnapshotRequest:request completionHandler:completionHandler];
        [self popSnapshotRequest:NO];
    }
}

#pragma mark - Private

- (UIView *)cachedSnapshotForRequest:(WPWebSnapshotRequest *)request
{
    UIView *cachedView = [self.cache objectForKey:request];
    if (cachedView) {
        CALayer *layer = cachedView.layer;
        while (layer.sublayers.count > 0) {
            layer = layer.sublayers.firstObject;
        }
        UIView *copyView = [[UIView alloc] initWithFrame:cachedView.frame];
        copyView.contentMode = UIViewContentModeScaleToFill;
        copyView.contentScaleFactor = cachedView.contentScaleFactor;
        copyView.layer.contents = layer.contents;
        copyView.layer.contentsRect = layer.contentsRect;
        copyView.layer.contentsScale = layer.contentsScale;
        copyView.layer.rasterizationScale = layer.rasterizationScale;
        
        UIView *containerView = [[UIView alloc] initWithFrame:cachedView.frame];
        containerView.contentMode = UIViewContentModeCenter;
        containerView.contentScaleFactor = 1.0f;
        [containerView addSubview:copyView];
        return containerView;
    } else {
        return nil;
    }
}

- (void)enqueueSnapshotRequest:(WPWebSnapshotRequest *)request completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    @synchronized(_requestQueue) {
        [self.requestQueue addObject:request];
    }
}

- (void)popSnapshotRequest:(BOOL)force
{
    if (!force && self.worker.status != WPWebSnapshotWorkerStatusReady) {
        // Ignore pop. Snapshot worker not available right now.
        return;
    }
    
    WPWebSnapshotRequest *request = nil;
    @synchronized(_requestQueue) {
        if (self.requestQueue.count > 0) {
            request = self.requestQueue.firstObject;
            [self.requestQueue removeObjectAtIndex:0];
        }
    }
    if (!request) {
        // Ignore pop. No snapshot request queued.
        return;
    }
    
    UIView *cachedView = [self cachedSnapshotForRequest:request];
    if (cachedView) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            request.callback(cachedView);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self popSnapshotRequest:YES];
            });
        });
    } else {
        [self.worker startSnapshotWithRequest:request completionHandler:^(UIView *view, WPWebSnapshotRequest *returnedRequest) {
            [self storeSnapshotView:view forRequest:returnedRequest];
            request.callback(view);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self popSnapshotRequest:YES];
            });
        }];
    }
}

- (void)storeSnapshotView:(UIView *)view forRequest:(WPWebSnapshotRequest *)request
{
    [self.cache setObject:view forKey:request cost:(view.bounds.size.width * view.bounds.size.height * 8)];
}

@end
