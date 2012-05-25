//
//  WPChromelessWebViewController.h
//
//  Created by Eric Johnson on 5/24/12.
//

#import <UIKit/UIKit.h>
#import "WPWebView.h"

@interface WPChromelessWebViewController : UIViewController <WPWebViewDelegate> {
    NSString *path;
    WPWebView *webView;
}

@property (nonatomic, retain, readonly) WPWebView *webView;

- (void)loadPath:(NSString *)aPath;

@end
