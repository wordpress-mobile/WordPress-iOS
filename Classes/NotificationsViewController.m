//
//  NotificationsViewController.m
//  WordPress
//
//

#import "NotificationsViewController.h"

@interface NotificationsViewController ()

@end

@implementation NotificationsViewController


- (void)loadView {
    self.path = kNotificationsURL;
    [super loadView];
}

- (void)webViewDidFinishLoad:(WPWebView *)wpWebView {
    [self.webView stringByEvaluatingJavaScriptFromString:@"var s = document.createElement('style'); s.type = 'text/css'; s.textContent = '#wpadminbar { display: none; } html[lang] { margin-top:0 !important }#notifications { margin-top: 0; } #wpnd-notes-content, #notifications #wpnd-notes-panel #wpnd-summary-col { padding-top:0; }'; document.head.appendChild(s);"];
}

@end
