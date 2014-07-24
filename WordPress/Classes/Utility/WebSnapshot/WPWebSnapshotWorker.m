//
//  WPWebSnapshotWorker.m
//  WordPress
//
//  Created by Josh Avant on 7/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

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

- (id)init
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
        
        self.webView = [[UIWebView alloc] initWithFrame:keyWindow.bounds];
        self.webView.userInteractionEnabled = NO;
        self.webView.hidden = NO;
        self.webView.delegate = self;
        UIView *backmostView = keyWindow.subviews.firstObject;
        [keyWindow insertSubview:self.webView belowSubview:backmostView];
        
        self.status = WPWebSnapshotWorkerStatusReady;
        self.numberOfCurrentLoads = 0;
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
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.snapshotRequest.snapshotURL
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10.0f];
    [self.webView loadRequest:request];
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
        self.callback(view, self.snapshotRequest.snapshotURL);
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
