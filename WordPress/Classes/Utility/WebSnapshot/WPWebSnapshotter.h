#import <Foundation/Foundation.h>
@class  WPWebSnapshotWorker;

typedef void (^WPWebSnapshotterSnapshotCompletionHandler)(UIView *view);

// Captures snapshots of URLs to UIViews. Captured views are cached within instances of this class.

@interface WPWebSnapshotter : NSObject

// The worker object used to render screenshots from a UIWebView instance
@property (nonatomic, readonly) WPWebSnapshotWorker *worker;

// snapshotSize's component values must not exceed the size of their corresponding axes within the
// key window
- (void)captureSnapshotOfURLRequest:(NSURLRequest *)urlRequest
                       snapshotSize:(CGSize)snapshotSize
                  completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

// javascript is an optional parameter of a javascript string to be evaluated on the underlying
// UIWebView, once it has finished loading the URL request
- (void)captureSnapshotOfURLRequest:(NSURLRequest *)urlRequest
                       snapshotSize:(CGSize)snapshotSize
         didFinishLoadingJavascript:(NSString *)javascript
                  completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

@end
