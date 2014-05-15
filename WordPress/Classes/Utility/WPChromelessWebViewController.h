#import <UIKit/UIKit.h>
#import "WPWebView.h"

@interface WPChromelessWebViewController : UIViewController <WPWebViewDelegate> {
    WPWebView *webView;
}

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong, readonly) WPWebView *webView;
- (void)loadPath:(NSString *)aPath;
- (NSURL *)currentURL;

@end
