#import "PostPreviewViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"

@interface PostPreviewViewController (Private)

- (void)addProgressIndicator;
- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString;

@end

@implementation PostPreviewViewController

@synthesize postDetailViewController, webView, postContent;

#pragma mark -
#pragma mark Memory Management

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
	[self refreshWebView];
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
	NSLog(@"refreshWebView - PostPreview");
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    // Use the template to preview if local draft, new post,
    // post has been edited, post is a draft, or post is private
    // TODO - try setting file URLs for photos not yet uploaded
    BOOL edited = [(NSNumber *)[[dataManager currentPost] objectForKey:@"hasChanges"] boolValue];

    BOOL isDraft = NO;
    NSString *status = [[dataManager currentPost] objectForKey:@"post_status"];

    if (![status isEqualToString:@"publish"] && ![status isEqualToString:@"private"])
        isDraft = YES;

    BOOL isPrivate = NO;

    if ([status isEqualToString:@"private"])
        isPrivate = YES;

    int photoCount = [[[dataManager currentPost] valueForKey:@"Photos"] count];
    NSString *photosMessage = @"{%d Photo(s) will be attached to the bottom of the post when published.}";
    photosMessage = [NSString stringWithFormat:photosMessage, photoCount];

    if (dataManager.isLocaDraftsCurrent || dataManager.currentPostIndex == -1
        || edited || isDraft || isPrivate) {
        // TODO use a default template so that we alwyas have one
        BOOL isDefaultTemplate;
        NSString *str = [dataManager templateHTMLStringForBlog:dataManager.currentBlog isDefaultTemplate:&isDefaultTemplate];

        if ([str length]) {
			NSString *title;
			NSString *desc;
			NSString *tags;
			NSString *catStr = @"";
			
			if (dataManager.currentPost == nil){
				DraftManager *draftManager = [[DraftManager alloc] init];
				
				WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
				
				Post *post = [draftManager get:delegate.postID];
				
				title = post.postTitle;
				desc = post.content;
				tags = post.tags;
				catStr = post.categories;
			}
			else {
				title = [dataManager.currentPost valueForKey:@"title"];
				if(self.postContent != nil) 
					desc = postContent;
				else
					desc = [dataManager.currentPost valueForKey:@"description"];
				
				
				tags = [dataManager.currentPost valueForKey:@"mt_keywords"];
				
				NSArray *categories;
				categories = [dataManager.currentPost valueForKey:@"categories"];
				if ([categories isKindOfClass:[NSArray class]])
					catStr = [categories componentsJoinedByString:@", "];
			}

			title = (title == nil || ([title length] == 0) ? @"(no title)" : title);
            str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];
            if (!desc)
                desc = @"<h1>No Description available for this Post</h1>";else {
                desc = [self stringReplacingNewlinesWithBR:desc];
            }

            desc = [NSString stringWithFormat:@"<p>%@</p><br />", desc];

            // append photo message
            if (photoCount) {
                desc = [NSString stringWithFormat:@"%@ \n <p>%@</p><br>", desc, photosMessage];
            }

            str = [str stringByReplacingOccurrencesOfString:@"!$text$!" withString:desc];

          
            tags = (tags == nil ? @"" : tags);
            if (isDefaultTemplate) {
                tags = [NSString stringWithFormat:@"Tags: %@", tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
            }
            str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];


            if (isDefaultTemplate) {
                catStr = [NSString stringWithFormat:@"Categories: %@", catStr]; //desc = [NSString stringWithFormat:@"%@ \n <p>Categories: %@</p><br>", desc, catStr];
            }
            str = [str stringByReplacingOccurrencesOfString:@"!$categories$!" withString:catStr];

            [webView loadHTMLString:str baseURL:nil];
            return;
        }
    }

    NSString *link = [dataManager.currentPost valueForKey:@"link"];

    if (link == nil) {
        NSString *desc = [dataManager.currentPost valueForKey:@"description"];

        if (desc) {
            [webView loadHTMLString:[NSString stringWithFormat:@"%@<p>%@</p>", desc, photosMessage] baseURL:nil];
        } else {
            [webView loadHTMLString:[NSString stringWithFormat:@"%@<p>%@</p>", @"", photosMessage] baseURL:nil];
        }
    }
	else {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
    }

    isWebRefreshRequested = YES;
}

#pragma mark -
#pragma mark UIWebViewDelegate Protocol

- (void)webViewDidStartLoad:(UIWebView *)webView {
	if (DeviceIsPad() == NO) {
		[self addProgressIndicator];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
	if (DeviceIsPad() == NO) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		if ([awebView isLoading] == NO && postDetailViewController.navigationItem.rightBarButtonItem != nil) {
			isWebRefreshRequested = NO;
		}
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (DeviceIsPad() == NO) {
		isWebRefreshRequested = NO;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}


- (BOOL)webView:(UIWebView *)awebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
    //return isWebRefreshRequested || postDetailViewController.navigationItem.rightBarButtonItem != nil;
}

#pragma mark -

//fix for #645
- (void)setUpdatedPostDescription:(NSString *)surString {
	self.postContent = surString;
}

- (NSString *)stringReplacingNewlinesWithBR:(NSString *)surString {
    NSArray *comps = [surString componentsSeparatedByString:@"\n"];
    return [comps componentsJoinedByString:@"<br>"];
}

- (void)addProgressIndicator {
	if (DeviceIsPad() == NO) {
		 [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		//postDetailViewController.navigationItem.rightBarButtonItem = activityButtonItem;
	}
}

- (void)stopLoading {
    [webView stopLoading];
	[webView loadHTMLString:@"<html><head></head><body></body>" baseURL:nil];
	if (DeviceIsPad() == NO) {
		 [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		//postDetailViewController.navigationItem.rightBarButtonItem = nil;
	}
    isWebRefreshRequested = NO;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[super dealloc];
}

@end