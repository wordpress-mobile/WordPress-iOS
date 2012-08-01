//
//  WPWebAppViewController.m
//  WordPress
//
//  Created by Beau Collins on 1/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPWebAppViewController.h"
#import "WordPressAppDelegate.h"


@implementation WPWebAppViewController

@synthesize webView, loading, lastWebViewRefreshDate, webBridge;

#pragma mark - View lifecycle

- (void)dealloc {
    WPFLogMethod();

    self.webView = nil;
    self.lastWebViewRefreshDate = nil;
    self.webBridge.delegate = nil;
    self.webBridge = nil;
    [_refreshHeaderView release]; _refreshHeaderView = nil;
    
    [super dealloc];
    
}


- (void)didReceiveMemoryWarning {
    WPFLogMethod();
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad {
    WPFLogMethod();
    [super viewDidLoad];
    
    if (!self.webBridge) {
        self.webBridge = [WPWebBridge bridge];
        self.webBridge.delegate = self;
    }
    
    if (shouldEnablePullToRefresh) {
        [self enablePullToRefresh];
    }
}


- (void)viewDidUnload {
    WPFLogMethod();
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    
    [_refreshHeaderView release]; _refreshHeaderView = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


// Find the Webview's UIScrollView backwards compatible
- (UIScrollView *)scrollView {
    
    UIScrollView *scrollView = nil;
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
        scrollView = self.webView.scrollView;
    } else {
        for (UIView* subView in self.webView.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView*)subView;
                return scrollView;
            }
        }
    }
    
    return scrollView;
    
}

#pragma mark - Hybrid Helper Methods

- (void)loadURL:(NSString *)url
{
    
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSDictionary *cookieHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookies cookiesForURL:request.URL]];
    [request setValue:appDelegate.applicationUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[cookieHeader valueForKey:@"Cookie"] forHTTPHeaderField:@"Cookie"];
    [self.webView loadRequest:[self.webBridge authorizeHybridRequest:request]];

}

// Just a Hello World for testing integration
- (void)enableAwesomeness
{
    [FileLogger log:@"Awesomeness Enabled"];
}

- (void)hideWebViewBackgrounds
{
    for (UIView *view in self.scrollView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.alpha = 0.0;
            view.hidden = YES;
        }
    }   
}

- (void)setBackgroundColor:(NSDictionary *)colorWithRedGreenBlueAlpha
{
    NSNumber *alpha = [colorWithRedGreenBlueAlpha objectForKey:@"alpha"];
    NSNumber *red = [colorWithRedGreenBlueAlpha objectForKey:@"red"];
    NSNumber *green = [colorWithRedGreenBlueAlpha objectForKey:@"green"];
    NSNumber *blue = [colorWithRedGreenBlueAlpha objectForKey:@"blue"];
    
    self.webView.backgroundColor = [UIColor colorWithRed:[red floatValue]
                                                   green:[green floatValue]
                                                    blue:[blue floatValue]
                                                   alpha:[alpha floatValue]];
    [self hideWebViewBackgrounds];
}

- (void)setNavigationBarColor:(NSDictionary *)colorWithRedGreenBlueAlpha
{
    NSNumber *alpha = [colorWithRedGreenBlueAlpha objectForKey:@"alpha"];
    NSNumber *red = [colorWithRedGreenBlueAlpha objectForKey:@"red"];
    NSNumber *green = [colorWithRedGreenBlueAlpha objectForKey:@"green"];
    NSNumber *blue = [colorWithRedGreenBlueAlpha objectForKey:@"blue"];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:[red floatValue]
                                                                        green:[green floatValue]
                                                                         blue:[blue floatValue]
                                                                        alpha:[alpha floatValue]];

}

- (void)enableFastScrolling {
    self.scrollView.decelerationRate = 0.994;        
    
}

- (void)enablePullToRefresh
{
    if (_refreshHeaderView == nil) {
        shouldEnablePullToRefresh = YES;
        self.scrollView.delegate = self;
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.scrollView.bounds.size.height, self.scrollView.frame.size.width, self.scrollView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.scrollView addSubview:_refreshHeaderView];
	}
    self.lastWebViewRefreshDate = [NSDate date];
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];

}


- (void)pullToRefreshComplete
{
    self.lastWebViewRefreshDate = [NSDate date];
    [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView * )_refreshHeaderView.superview];

}


#pragma mark - UIWebViewDelegate


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    if ([self.webBridge handlesRequest:request]) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self.webView stringByEvaluatingJavaScriptFromString:@"WPApp.pullToRefresh();"];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return self.loading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
	return self.lastWebViewRefreshDate;
    
}

// provide a way for web apps to show the native pull to refresh loading indicator
- (void)showRefreshingState {
    CGPoint offset = self.scrollView.contentOffset;
    offset.y = - 65.0f;
    [self.scrollView setContentOffset:offset];
    [_refreshHeaderView egoRefreshScrollViewDidEndDragging:self.scrollView];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


@end
