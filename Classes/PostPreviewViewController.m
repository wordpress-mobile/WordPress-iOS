#import "PostPreviewViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"

@interface PostPreviewViewController (Private)

- (void)addProgressIndicator;
- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString;

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
    [FlurryAPI logEvent:@"PostPreview"];
	webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refreshWebView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopLoading];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning] == YES)
        return NO;
    
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {
	
	BOOL edited = [self.postDetailViewController hasChanges];
	NSString *status = postDetailViewController.apost.status;
    
	//draft post
	BOOL isDraft = [self.postDetailViewController isAFreshlyCreatedDraft];
	if ([status isEqualToString:@"draft"])
        isDraft = YES;
	
    BOOL isPrivate = NO;
    if ([status isEqualToString:@"private"])
        isPrivate = YES;
	
    if (edited || isDraft || isPrivate) {
		NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
		NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
		NSString *str = [NSString stringWithContentsOfFile:fpath];
		
        if ([str length]) {
			
			//Title
            NSString *title = postDetailViewController.apost.postTitle;
            title = (title == nil || ([title length] == 0) ? @"(no title)" : title);
            str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];
			
			//Content
            NSString *desc = postDetailViewController.apost.content;
            if (!desc)
                desc = @"<h1>No Description available for this Post</h1>";else {
					desc = [self stringReplacingNewlinesWithBR:desc];
				}
            desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];
            str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];
			
			//Tags
            NSString *tags = postDetailViewController.post.tags;
            tags = (tags == nil ? @"" : tags);
			tags = [NSString stringWithFormat:@"Tags: %@", tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
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
			catStr = [NSString stringWithFormat:@"Categories: %@", catStr]; //desc = [NSString stringWithFormat:@"%@ \n <p>Categories: %@</p><br>", desc, catStr];
            str = [str stringByReplacingOccurrencesOfString:@"!$categories$!" withString:catStr];
			
            [webView loadHTMLString:str baseURL:nil];
            return;
        }
    }
	
    NSString *link = postDetailViewController.apost.permaLink;
	
    if (link == nil) {
        NSString *desc = postDetailViewController.apost.content;
		
        if (desc) {
            [webView loadHTMLString:desc baseURL:nil];
        } else {
            [webView loadHTMLString:@"" baseURL:nil];
        }
    }
	else {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
    }
	
    isWebRefreshRequested = YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	if (DeviceIsPad() == NO) {
		[self addProgressIndicator];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
	if (DeviceIsPad() == NO) {
		if ([awebView isLoading] == NO && postDetailViewController.navigationItem.rightBarButtonItem != nil) {
			isWebRefreshRequested = NO;
		}
	}
}

- (BOOL)webView:(UIWebView *)awebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
    return isWebRefreshRequested || postDetailViewController.navigationItem.rightBarButtonItem != nil;
}

#pragma mark -

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString {
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}

- (void)addProgressIndicator {
    return; // Disabled for now
	if (DeviceIsPad() == NO) {
		UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
		[aiv startAnimating];
		[aiv release];
		postDetailViewController.navigationItem.rightBarButtonItem = activityButtonItem;
	}
}

- (void)stopLoading {
    [webView stopLoading];
	if (DeviceIsPad() == NO) {
		postDetailViewController.navigationItem.rightBarButtonItem = nil;
	}
    isWebRefreshRequested = NO;
}

@end