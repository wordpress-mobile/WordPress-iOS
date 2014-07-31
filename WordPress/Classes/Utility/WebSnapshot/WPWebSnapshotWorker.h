#import <Foundation/Foundation.h>
@class WPWebSnapshotRequest;

typedef NS_ENUM(NSUInteger, WPWebSnapshotWorkerStatus) {
    WPWebSnapshotWorkerStatusUnknown = 0,
    WPWebSnapshotWorkerStatusReady,
    WPWebSnapshotWorkerStatusExecuting
};

typedef void (^WPWebSnapshotWorkerCompletionHandler)(UIView *view, WPWebSnapshotRequest *request);

@interface WPWebSnapshotWorker : NSObject

@property (nonatomic, readonly) WPWebSnapshotWorkerStatus status;

// optional: allows external customization of the webview used to capture screenshots
@property (nonatomic, weak) id<UIWebViewDelegate> webViewCustomizationDelegate;

- (void)startSnapshotWithRequest:(WPWebSnapshotRequest *)snapshotRequest completionHandler:(WPWebSnapshotWorkerCompletionHandler)completionHandler;

@end
