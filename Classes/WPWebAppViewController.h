//
//  WPWebAppViewController.h
//  WordPress
//
//  Created by Beau Collins on 1/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"


@interface WPWebAppViewController : UIViewController <UIWebViewDelegate, EGORefreshTableHeaderDelegate, UIScrollViewDelegate>
{
    EGORefreshTableHeaderView *_refreshHeaderView;
    NSString *hybridAuthToken;

}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, retain) NSDate *lastWebViewRefreshDate;

- (void)executeBatchFromRequest:(NSURLRequest *)request;
- (void)setTitle:(NSString *)title;
- (void)setBackgroundColor:(NSDictionary *)colorWithRGBA;
- (void)setNavigationBarColor:(NSDictionary *)colorWithRGBA;
- (void)enableFastScrolling;
- (void)enableAwesomeness;
- (UIScrollView *)scrollView;
- (NSMutableURLRequest *)authorizeHybridRequest:(NSMutableURLRequest *)request;
+ (NSURL *)authorizeHybridURL:(NSURL *) url;
- (BOOL)requestIsValidHybridRequest:(NSURLRequest *)request;
+ (BOOL)isValidHybridURL:(NSURL *)url;
- (NSString *)hybridAuthToken;
+ (NSString *)hybridAuthToken;

@end
