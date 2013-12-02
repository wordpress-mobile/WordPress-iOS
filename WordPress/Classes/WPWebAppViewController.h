/*
 * WPWebAppViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "EGORefreshTableHeaderView.h"
#import "WPWebBridge.h"


@interface WPWebAppViewController : UIViewController <UIWebViewDelegate, EGORefreshTableHeaderDelegate, UIScrollViewDelegate>
{
    EGORefreshTableHeaderView *_refreshHeaderView;
    NSString *hybridAuthToken;
    BOOL shouldEnablePullToRefresh;
    BOOL didTriggerRefresh;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) NSDate *lastWebViewRefreshDate;
@property (nonatomic, strong) WPWebBridge *webBridge;

- (void)setBackgroundColor:(NSDictionary *)colorWithRGBA;
- (void)setNavigationBarColor:(NSDictionary *)colorWithRGBA;
- (void)enableFastScrolling;
- (void)enableAwesomeness;
- (void)loadURL:(NSString *)url;
- (UIScrollView *)scrollView;
- (void)showRefreshingState;
- (void)hideRefreshingState;
- (void)enablePullToRefresh;


@end
