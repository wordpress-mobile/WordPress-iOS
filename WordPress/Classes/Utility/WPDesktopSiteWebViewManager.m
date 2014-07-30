//
//  WPLivePreviewWorkaroundWebViewManager.m
//  WordPress
//
//  Created by Josh Avant on 7/30/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPDesktopSiteWebViewManager.h"

@implementation WPDesktopSiteWebViewManager

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // This is a workaround for the current issue of the theme preview page not setting the correct
    // cookie/domain, when passed 'ak_action=reject_mobile'.
    //
    // Once this issue is fixed, the client should allow the server to set the cookie (i.e. remove
    // this logic and pass ak_action=reject_mobile in the request parameters).
    
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:@"akm_mobile" forKey:NSHTTPCookieName];
    [cookieProperties setObject:@"false" forKey:NSHTTPCookieValue];
    [cookieProperties setObject:[[request URL] host] forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    
    BOOL shouldStartLoad = YES;
    
    if ([[self superclass] instancesRespondToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldStartLoad = [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return shouldStartLoad;
}

@end
