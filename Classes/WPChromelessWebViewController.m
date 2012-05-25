//
//  WPChromelessWebViewController.m
//
//  Created by Eric Johnson on 5/24/12.
//

#import "WPChromelessWebViewController.h"

@interface WPChromelessWebViewController ()
@property (nonatomic, retain) WPWebView *webView;
@end

@implementation WPChromelessWebViewController

@synthesize webView;

#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    if(path) {
        [path release]; path = nil;
    }
    [webView release];
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect frame = self.view.frame;
    self.webView = [[[WPWebView alloc] initWithFrame:frame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth & UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    [self.view addSubview:webView];
    
    if (path) {
        [webView loadPath:path];
        [path release]; path = nil;        
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    webView.delegate = nil;
    self.webView = nil;
}


#pragma mark -
#pragma mark Instance Methods

- (void)loadPath:(NSString *)aPath {
    if ([self isViewLoaded]) {
        [webView loadPath:aPath];
    } else {
        if (path) {
            [path release];
            path = nil;
        }
        path = [aPath retain];
    }
}


#pragma mark -
#pragma mark WPWebView Delegate Methods

- (BOOL)wpWebView:(WPWebView *)wpWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // If a link to a new URL is clicked we want to open in a new window. 
    // This method is also triggered when loading html from a string so we need to handle that case as well.
    // TODO: Differentiate between ajaxy requests for the curret page and actual page changes.
//    if ([[request.URL absoluteString] isEqualToString:@"about:blank"]) {
//        return YES;
//    }
//    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        WPChromelessWebViewController *controller = [[WPChromelessWebViewController alloc] init];
        [controller loadPath:request.URL.absoluteString];
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
        return NO;
    }
    
    return YES;
}

@end
