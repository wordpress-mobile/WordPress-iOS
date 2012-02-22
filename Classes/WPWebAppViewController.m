//
//  WPWebAppViewController.m
//  WordPress
//
//  Created by Beau Collins on 1/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "WPWebAppViewController.h"
#import "JSONKit.h"

@implementation WPWebAppViewController

@synthesize webView, loading, lastWebViewRefreshDate;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}
*/


- (void)didReceiveMemoryWarning
{
    WPFLogMethod();
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*
- (void)loadView
{
    self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.frame] autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    }

}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    WPFLogMethod();
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    WPFLogMethod();
    [_refreshHeaderView release]; _refreshHeaderView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    WPFLogMethod();
    self.view = nil;
    self.webView = nil;
    self.lastWebViewRefreshDate = nil;
    [super dealloc];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Find the Webview's UIScrollView backwards compatible
- (UIScrollView *)scrollView {
    
    UIScrollView *scrollView;
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
        scrollView = self.webView.scrollView;
    } else {
        for (UIView* subView in self.webView.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView*)subView;
            }
        }
    }
    
    return scrollView;
    
}

/*
Adds a token to the querystring of the request and to a request header
 so the HTML portion can authenticate when requesting to call native methods
*/
- (NSURLRequest *)authorizeHybridRequest:(NSMutableURLRequest *)request {
    if( [[self class] isValidHybridURL:request.URL] ){
        // add the token
        request.URL = [[self class] authorizeHybridURL:request.URL];
        [request addValue:self.hybridAuthToken forHTTPHeaderField:@"X-WP-HYBRID-AUTH-TOKEN"];
    }
    return request;  
}

+ (NSURL *)authorizeHybridURL:(NSURL *)url
{
    NSString *absoluteURL = [url absoluteString];
    NSString *newURL;
    if ( [absoluteURL rangeOfString:@"?"].location == NSNotFound ){
        // append the query with ?
        newURL = [absoluteURL stringByAppendingFormat:@"?wpcom-hybrid-auth-token=%@", self.hybridAuthToken];
    }else {
        // append the query with &
        newURL = [absoluteURL stringByAppendingFormat:@"&wpcom-hybrid-auth-token=%@", self.hybridAuthToken];
        
    }
    return [NSURL URLWithString:newURL];

}

+ (BOOL) isValidHybridURL:(NSURL *)url {
    return [url.host isEqualToString:kAuthorizedHybridHost];
}

- (BOOL)requestIsValidHybridRequest:(NSURLRequest *)request {
    
    return [request.URL.host isEqualToString:kAuthorizedHybridHost];
    
}

- (NSString *)hybridAuthToken
{
    return [[self class] hybridAuthToken];
}

+ (NSString *)hybridAuthToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults stringForKey:kHybridTokenSetting];
    if (token == nil)
    {
        
        NSString *concat = [NSString stringWithFormat:@"%@--%d", [[UIDevice currentDevice] uniqueIdentifier], arc4random()];
        const char *concat_str = [concat UTF8String];
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5(concat_str, strlen(concat_str), result);
        NSMutableString *hash = [NSMutableString string];
        for (int i = 0; i < 16; i++)
            [hash appendFormat:@"%02X", result[i]];
        token = [hash lowercaseString];
        [FileLogger log:@"Generating new hybrid token: %@", token];
        [defaults setValue:token forKey:kHybridTokenSetting];
        [defaults synchronize];
        
    }
    return token;
}

#pragma mark - Hybrid Bridge
/*
    
 Workhorse for the JavaScript to Obj-C bridge
 The payload QS variable is JSON that is url encoded.
 
 This decodes and parses the JSON into a Obj-C object and
 uses the properties to create an NSInvocation that fires
 in the context of the controller.
 
*/
-(void)executeBatchFromRequest:(NSURLRequest *)request {
    NSURL *url = request.URL;
    
    NSArray *components = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:[components count]];
    [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *pair = [obj componentsSeparatedByString:@"="];
        [params setValue:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
    }];
    [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), params];
    NSString *payload_data = [(NSString *)[params objectForKey:@"payload"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (![self.hybridAuthToken isEqualToString:[params objectForKey:@"wpcom-hybrid-auth-token"]]) {
        WPFLog(@"Invalid hybrid token received %@ (expected: %@)", [params objectForKey:@"wpcom-hybrid-auth-token"], self.hybridAuthToken);
        return;
    }
     
    id payload = [payload_data objectFromJSONString];
    
    [payload enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *action = (NSDictionary *)obj;
        NSArray *args = (NSArray *)[action objectForKey:@"args"];
        NSString *method = (NSString *)[action objectForKey:@"method"];
        NSString *methodName = [method stringByPaddingToLength:([method length] + [args count]) withString:@":" startingAtIndex:0];
        SEL aSelector = NSSelectorFromString(methodName);
        NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:aSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation retainArguments];
        invocation.selector = aSelector;
        invocation.target = self;
        [args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [invocation setArgument:&obj atIndex:idx + 2];
        }];
        
        if ([self respondsToSelector:aSelector]) {
            @try {
                [invocation invoke];
                WPFLog(@"Hybrid: %@ %@", self, methodName);
            }
            @catch (NSException *exception) {
                WPFLog(@"Hybrid exception on %@ %@", self, methodName);
                WPFLog(@"%@ %@", [exception name], [exception reason]);
                WPFLog(@"%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
            }
        } else {
            WPFLog(@"Hybrid controller doesn't know how to run method: %@ %@", self, methodName);
        }
        
    }];
    
}

#pragma mark - Hybrid Helper Methods

// Just a Hello World for testing integration
- (void)enableAwesomeness
{
    [FileLogger log:@"Awesomeness Enabled"];
}

- (void)setTitle:(NSString *)title
{
    self.navigationItem.title = title;
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
    
    if ( [request.URL.scheme isEqualToString:@"wpios"] && [request.URL.host isEqualToString:@"batch"] ){
        [self executeBatchFromRequest:request];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    [self.webView stringByEvaluatingJavaScriptFromString:@"WPApp.pullToRefresh();"];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return self.loading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return self.lastWebViewRefreshDate;
    
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}





@end
