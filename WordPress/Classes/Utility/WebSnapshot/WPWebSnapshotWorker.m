#import "WPWebSnapshotWorker.h"
#import "WPWebSnapshotRequest.h"

@interface WPWebSnapshotWorker () <UIWebViewDelegate>

@property (nonatomic) UIWebView *webView;
@property (nonatomic) WPWebSnapshotRequest *snapshotRequest;
@property (nonatomic, copy) WPWebSnapshotWorkerCompletionHandler callback;
@property (nonatomic, readwrite) WPWebSnapshotWorkerStatus status;
@property (nonatomic) NSInteger numberOfCurrentLoads;

@end

@implementation WPWebSnapshotWorker

- (instancetype)init
{
    if (self = [super init]) {
        UIApplication *application = [UIApplication sharedApplication];
        if (!application) {
            return nil;
        }
        
        UIWindow *keyWindow = application.keyWindow;
        if (!keyWindow) {
            return nil;
        }
        
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.userInteractionEnabled = NO;
        _webView.hidden = NO;
        _webView.scalesPageToFit = YES;
        _webView.delegate = self;
        UIView *backmostView = keyWindow.subviews.firstObject;
        [keyWindow insertSubview:self.webView belowSubview:backmostView];
        
        _status = WPWebSnapshotWorkerStatusReady;
        _numberOfCurrentLoads = 0;
    }
    return self;
}

- (void)startSnapshotWithRequest:(WPWebSnapshotRequest *)snapshotRequest completionHandler:(WPWebSnapshotWorkerCompletionHandler)completionHandler
{
    if (self.status != WPWebSnapshotWorkerStatusReady) {
        return;
    }
    
    self.snapshotRequest = snapshotRequest;
    self.callback = completionHandler;
    
    self.webView.frame = CGRectMake(0, 0, snapshotRequest.snapshotSize.width, snapshotRequest.snapshotSize.height);
    [self.webView loadRequest:self.snapshotRequest.urlRequest];
    
    self.status = WPWebSnapshotWorkerStatusExecuting;
}

- (void)finishRenderingIfPossible
{
    if (self.numberOfCurrentLoads > 0) {
        return;
    }
    
    if (self.callback) {
        CGRect rect = self.webView.bounds;
        UIView *view = [self.webView resizableSnapshotViewFromRect:rect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
        self.callback(view, self.snapshotRequest);
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.numberOfCurrentLoads = 0;
    self.snapshotRequest = nil;
    self.callback = nil;
    self.status = WPWebSnapshotWorkerStatusReady;
}

- (void)didFinishWebViewRequest
{
    self.numberOfCurrentLoads -= 1;
    
    [self performSelector:@selector(finishRenderingIfPossible) withObject:nil afterDelay:0.05 inModes:@[NSRunLoopCommonModes]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldStartLoad = YES;
    
    if ([self.webViewCustomizationDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldStartLoad = [self.webViewCustomizationDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return shouldStartLoad;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.numberOfCurrentLoads += 1;
    
    if ([self.webViewCustomizationDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.webViewCustomizationDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.snapshotRequest.didFinishJavascript.length > 0) {
        [webView stringByEvaluatingJavaScriptFromString:self.snapshotRequest.didFinishJavascript];
    }
    
    [self didFinishWebViewRequest];
    
    if ([self.webViewCustomizationDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.webViewCustomizationDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self didFinishWebViewRequest];
    
    if ([self.webViewCustomizationDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.webViewCustomizationDelegate webView:webView didFailLoadWithError:error];
    }
}

@end
