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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshWebView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopLoading];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning] == YES)
        return NO;
    
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {
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
            NSString *title = [dataManager.currentPost valueForKey:@"title"];
            title = (title == nil || ([title length] == 0) ? @"(no title)" : title);
            str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];

            NSString *desc = [dataManager.currentPost valueForKey:@"description"];

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

            NSString *tags = [dataManager.currentPost valueForKey:@"mt_keywords"];
            tags = (tags == nil ? @"" : tags);

            if (isDefaultTemplate) {
                tags = [NSString stringWithFormat:@"Tags: %@", tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
            }

            str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];

            NSArray *categories = [dataManager.currentPost valueForKey:@"categories"];
            NSString *catStr = @"";

            if ([categories isKindOfClass:[NSArray class]])
                catStr = [categories componentsJoinedByString:@", "];

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
    } else {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
    }

    isWebRefreshRequested = YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (postDetailViewController.navigationItem.rightBarButtonItem == nil ||
        postDetailViewController.navigationItem.rightBarButtonItem == postDetailViewController.saveButton) {
        [self addProgressIndicator];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView {
    if ([awebView isLoading] == NO && postDetailViewController.navigationItem.rightBarButtonItem != nil &&
        postDetailViewController.navigationItem.rightBarButtonItem != postDetailViewController.saveButton) {
        postDetailViewController.navigationItem.rightBarButtonItem = (postDetailViewController.hasChanges ? postDetailViewController.saveButton : nil);

        if (postDetailViewController.tabController.selectedViewController == self)
            postDetailViewController.navigationItem.title = self.title;

        isWebRefreshRequested = NO;
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
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    [aiv startAnimating];
    [aiv release];
    
    postDetailViewController.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityButtonItem release];
    [apool release];
}

- (void)stopLoading {
    [webView stopLoading];
    postDetailViewController.navigationItem.rightBarButtonItem = nil;
    isWebRefreshRequested = NO;
}

@end