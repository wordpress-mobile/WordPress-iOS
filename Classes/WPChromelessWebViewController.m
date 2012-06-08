//
//  WPChromelessWebViewController.m
//
//  Created by Eric Johnson on 5/24/12.
//

#import "WPChromelessWebViewController.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"

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


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGRect frame = self.view.bounds;
    self.webView = [[[WPWebView alloc] initWithFrame:frame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;

    [self.view addSubview:webView];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

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


- (NSURL *)currentURL {
    return [self.webView currentURL];
}


#pragma mark -
#pragma mark WPWebView Delegate Methods

- (BOOL)wpWebView:(WPWebView *)wpWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // If a link to a new URL is clicked we want to open in a new window. 
    // This method is also triggered when loading html from a string so we need to handle that case as well.
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {

        // Check the panelNavigationController's stack to see if the previous item was a chromeless webview controller.
        // If so check to see if its displaying the same url that was just clicked. 
        // If so just pop ourself off the stack.
        UIViewController *detailController = [self.panelNavigationController detailViewController];
        if ([detailController isKindOfClass:[self class]]) {
            WPChromelessWebViewController *controller = (WPChromelessWebViewController *)detailController;
            if([[[controller currentURL] absoluteString] isEqualToString:[[request URL] absoluteString] ]) {
                // if the detail controller is ourself disregard the click so we don't spam a series of the same page.
                if (detailController != self) {
                    [self.panelNavigationController popViewControllerAnimated:YES];
                }
                return NO;
            }
        }       

        // If the url points off-site we want to handle it differently.
        NSString *host = request.URL.host;
        if ([host rangeOfString:@"wordpress.com"].location == NSNotFound) {
            WPWebViewController *controller;
            if (DeviceIsPad()) {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
            }
            else {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
            }
            [controller setUrl:request.URL];
            if (IS_IPAD) {
                [self presentModalViewController:controller animated:YES];
            } else {
                [self.navigationController pushViewController:controller animated:YES];
            }
            return NO;
        }
        
        WPChromelessWebViewController *controller = [[WPChromelessWebViewController alloc] init];
        [controller loadPath:request.URL.absoluteString];        
        if (!DeviceIsPad()) {
            [self.navigationController pushViewController:controller animated:YES];

        } else {
            
            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            [self.panelNavigationController pushViewController:controller animated:YES];

        }

        [controller release];
        return NO;
    }
    
    return YES;
}

@end
