//
//  WPWebAppViewController.h
//  WordPress
//
//  Created by Beau Collins on 1/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "WPWebBridge.h"


@interface WPWebAppViewController : UIViewController <UIWebViewDelegate, EGORefreshTableHeaderDelegate, UIScrollViewDelegate>
{
    EGORefreshTableHeaderView *_refreshHeaderView;
    NSString *hybridAuthToken;

}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, retain) NSDate *lastWebViewRefreshDate;
@property (nonatomic, retain) WPWebBridge *webBridge;

- (void)setBackgroundColor:(NSDictionary *)colorWithRGBA;
- (void)setNavigationBarColor:(NSDictionary *)colorWithRGBA;
- (void)enableFastScrolling;
- (void)enableAwesomeness;
- (void)loadURL:(NSString *)url;
- (UIScrollView *)scrollView;
- (void)showRefreshingState;

@end
