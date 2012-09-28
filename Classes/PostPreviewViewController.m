#import "PostPreviewViewController.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"

@interface PostPreviewViewController (Private)

- (void)addProgressIndicator;
- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString;
- (NSString *)buildSimplePreview;

@end

@implementation PostPreviewViewController

@synthesize postDetailViewController, webView;

#pragma mark -
#pragma mark Memory Management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Initialization code
		webView.delegate = self;
    }
    return self;
}
 

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	webView.delegate = self;
	if (activityFooter == nil) {
		CGRect rect = CGRectMake(0, 0, 30, 30);
        activityFooter = [[UIActivityIndicatorView alloc] initWithFrame:rect];
        activityFooter.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        activityFooter.hidesWhenStopped = YES;
        activityFooter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }	
	
	[self.view addSubview:activityFooter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refreshWebView];
	if (IS_IPAD)
		[activityFooter setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
	else
		[activityFooter setCenter:CGPointMake(self.view.center.x - 20, self.view.center.y - 20)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	[webView stopLoading];
}
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (IS_IPAD == YES) {
		return YES;
	}

    WordPressAppDelegate *delegate = (WordPressAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning] == YES)
        return NO;
    
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (NSString *)buildSimplePreview {
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
	NSString *str = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:nil];
	
	if ([str length]) {
		
		//Title
		NSString *title = postDetailViewController.apost.postTitle;
		title = (title == nil || ([title length] == 0) ? NSLocalizedString(@"(no title)", @"") : title);
		str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];
		
		//Content
		NSString *desc = postDetailViewController.apost.content;
		if (!desc)
			desc = [NSString stringWithFormat:@"<h1>%@</h1>", NSLocalizedString(@"No Description available for this Post", @"")];
        else {
				desc = [self stringReplacingNewlinesWithBR:desc];
			}
		desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];
		str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];
		
		//Tags
		NSString *tags = postDetailViewController.post.tags;
		tags = (tags == nil ? @"" : tags);
		tags = [NSString stringWithFormat:NSLocalizedString(@"Tags: %@", @""), tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
		str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];
		
		//Categories [selObjects count]
		NSArray *categories = [postDetailViewController.post.categories allObjects];
		NSString *catStr = @"";
		int i = 0, count = [categories count];
		for (i = 0; i < count; i++) {
			Category *category = [categories objectAtIndex:i];
			catStr = [catStr stringByAppendingString:category.categoryName];
			if(i < count-1)
				catStr = [catStr stringByAppendingString:@", "];
		}
		catStr = [NSString stringWithFormat:NSLocalizedString(@"Categories: %@", @""), catStr]; //desc = [NSString stringWithFormat:@"%@ \n <p>Categories: %@</p><br>", desc, catStr];
		str = [str stringByReplacingOccurrencesOfString:@"!$categories$!" withString:catStr];

	} else {
		str = @"";
	}
		
	return str;
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {
	
	BOOL edited = [self.postDetailViewController hasChanges];
	NSString *status = postDetailViewController.apost.status;
	
	//draft post
	BOOL isDraft = [self.postDetailViewController isAFreshlyCreatedDraft];
	BOOL isPrivate = NO;
	BOOL isPending = NO;
    BOOL isPrivateBlog = [postDetailViewController.apost.blog isPrivate];
	
	if ([status isEqualToString:@"draft"])
		isDraft = YES;
	else if ([status isEqualToString:@"private"])
		isPrivate = YES;
	else if ([status isEqualToString:@"pending"])
		isPending = YES;
	
	if (edited) {
		[webView loadHTMLString:[self buildSimplePreview] baseURL:nil];
	} else {
		
		NSString *link = postDetailViewController.apost.permaLink;
		
        WordPressAppDelegate  *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if( appDelegate.connectionAvailable == NO ) {
            NSString *previewPageHTML = [self buildSimplePreview];
            NSString *noConnectionMessageHTML = [NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection appears to be offline.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")];
            previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:noConnectionMessageHTML];
            [webView loadHTMLString:previewPageHTML baseURL:nil];
        } else if ( postDetailViewController.apost.blog.reachable == NO ) {
            NSString *previewPageHTML = [self buildSimplePreview];
            NSString *noConnectionMessageHTML = [NSString stringWithFormat:@"<div class=\"page\"><p>%@ %@</p>", NSLocalizedString(@"The internet connection cannot reach your blog.", @""), NSLocalizedString(@"A simple preview is shown below.", @"")];
            previewPageHTML = [previewPageHTML stringByReplacingOccurrencesOfString:@"<div class=\"page\">" withString:noConnectionMessageHTML];
            [webView loadHTMLString:previewPageHTML baseURL:nil];
		} else if (link == nil ) {
			[webView loadHTMLString:[self buildSimplePreview] baseURL:nil];
		} else {
				
			// checks if this a scheduled post
			
			/*
			 Forced the preview to use the login form. Otherwise the preview of pvt blog doesn't work.
			 We can switch back to the normal call when we can access the blogOptions within the app.
			 */
			
//			NSDate *currentGMTDate = [DateUtils currentGMTDate];
			NSDate *postGMTDate = postDetailViewController.apost.date_created_gmt;
			NSDate *laterDate = postDetailViewController.apost.date_created_gmt;//[currentGMTDate laterDate:postGMTDate];
			
			if(isDraft || isPending || isPrivate || isPrivateBlog || ([laterDate isEqualToDate:postGMTDate])) {
				
				NSString *wpLoginURL = [postDetailViewController.apost.blog loginURL];
				NSURL *url = [NSURL URLWithString:wpLoginURL]; 
				NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
				[req setHTTPMethod:@"POST"];
				[req addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
				NSString *paramDataString = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@", 
											 @"log", postDetailViewController.apost.blog.username,
											 @"pwd", [[postDetailViewController.apost.blog fetchPassword] stringByUrlEncoding],
											 @"redirect_to", link];
			
				NSData *paramData = [paramDataString dataUsingEncoding:NSUTF8StringEncoding]; 
				[req setHTTPBody: paramData];
                [req setValue:[NSString stringWithFormat:@"%d", [paramData length]] forHTTPHeaderField:@"Content-Length"];
                [req addValue:@"*/*" forHTTPHeaderField:@"Accept"];
				[webView loadRequest:req];

			} else {
				[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
			}
		}
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[activityFooter startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
	[activityFooter stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[activityFooter stopAnimating];
}

- (BOOL)webView:(UIWebView *)awebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
    //return isWebRefreshRequested || postDetailViewController.navigationItem.rightBarButtonItem != nil;
}

#pragma mark -

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString {
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}


#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[webView stopLoading];
	webView.delegate = nil;
	[webView release]; webView = nil;
    [activityFooter release];
    [super dealloc];
}
@end