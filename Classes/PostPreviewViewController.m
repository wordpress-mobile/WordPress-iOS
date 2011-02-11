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
		[self refreshWebView];
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


- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }
    
    WordPressAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:appDelegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"post == %@", self.postDetailViewController.post]];
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    resultsController = [[NSFetchedResultsController alloc]
						 initWithFetchRequest:fetchRequest
						 managedObjectContext:appDelegate.managedObjectContext
						 sectionNameKeyPath:nil
						 cacheName:[NSString stringWithFormat:@"Media-%@-%@",
									self.postDetailViewController.post.blog.hostURL,
									self.postDetailViewController.post.postID]];
    resultsController.delegate = self;
    
    [fetchRequest release];
    [sortDescriptorDate release]; sortDescriptorDate = nil;
    [sortDescriptors release]; sortDescriptors = nil;
    
    NSError *error = nil;
    if (![resultsController performFetch:&error]) {
        NSLog(@"Couldn't fetch media");
        resultsController = nil;
    }
    
    return resultsController;
}

#pragma mark -
#pragma mark Webkit View Delegate Methods

- (void)refreshWebView {

	BOOL edited = [self.postDetailViewController hasChanges];
    BOOL isDraft = [self.postDetailViewController isAFreshlyCreatedDraft];

    NSString *status = postDetailViewController.apost.status;
    BOOL isPrivate = NO;
    if ([status isEqualToString:@"private"])
        isPrivate = YES;

	
	id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[self.resultsController sections] objectAtIndex:0];
	int photoCount = [sectionInfo numberOfObjects];
	
    NSString *photosMessage = @"{%d Photo(s) will be attached to the bottom of the post when published.}";
    photosMessage = [NSString stringWithFormat:photosMessage, photoCount];

    if (edited || isDraft || isPrivate) {
        // TODO use a default template so that we alwyas have one
		NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
		NSString *fpath = [NSString stringWithFormat:@"%@/defaultPostTemplate.html", resourcePath];
		NSString *str = [NSString stringWithContentsOfFile:fpath];
		
        if ([str length]) {
            NSString *title = postDetailViewController.apost.postTitle;
            title = (title == nil || ([title length] == 0) ? @"(no title)" : title);
            str = [str stringByReplacingOccurrencesOfString:@"!$title$!" withString:title];

            NSString *desc = postDetailViewController.apost.content;

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

            NSString *tags = postDetailViewController.post.tags;
            tags = (tags == nil ? @"" : tags);
			tags = [NSString stringWithFormat:@"Tags: %@", tags]; //desc = [NSString stringWithFormat:@"%@ \n <p>Tags: %@</p><br>", desc, tags];
            

            str = [str stringByReplacingOccurrencesOfString:@"!$mt_keywords$!" withString:tags];

            NSArray *categories = nil;
            NSString *catStr = @"";

            if ([categories isKindOfClass:[NSArray class]])
                catStr = [categories componentsJoinedByString:@", "];

       
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