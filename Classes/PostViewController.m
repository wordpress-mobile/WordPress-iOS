//
//  PostViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 12/30/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "PostViewController.h"
#import "NSString+XMLExtensions.h"
#import "PanelNavigationConstants.h"

@implementation PostViewController
@synthesize titleTitleLabel, tagsTitleLabel, categoriesTitleLabel;
@synthesize titleLabel, tagsLabel, categoriesLabel;
@synthesize contentView;
@synthesize contentWebView;
@synthesize apost;
@synthesize blog;

#pragma mark -
#pragma mark LifeCycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.apost = nil;
	self.blog = nil;
    self.contentView = nil;
    self.contentWebView = nil;
    self.titleLabel = nil;
    self.tagsLabel = nil;
    self.categoriesLabel = nil;
    self.titleTitleLabel = nil;
    self.tagsTitleLabel = nil;
    self.categoriesTitleLabel = nil;
	
    [super dealloc];
}


- (id)initWithPost:(AbstractPost *)aPost {
    if ((self = [super initWithNibName:@"PostViewController-iPad" bundle:nil])) {
        self.apost = aPost;
		self.blog = self.apost.blog; //keep a reference to the blog
    }
    return self;
}


- (void)viewDidLoad {
	[FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewDidLoad];
    [self refreshUI];
    
    self.titleTitleLabel.text = NSLocalizedString(@"Title:", @"");
    self.tagsTitleLabel.text = NSLocalizedString(@"Tags:", @"");
    self.categoriesTitleLabel.text = NSLocalizedString(@"Categories:", @"");
    
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                 target:self
                                                                                 action:@selector(showModalEditor)] autorelease];
    if (IS_IPAD) {
        self.toolbarItems = [NSArray arrayWithObject:editButton];
    } else {
        self.navigationItem.rightBarButtonItem = editButton;
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(IS_IPAD){
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
    }
}


#pragma mark -
#pragma mark Accessors

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}


- (void)setPost:(Post *)aPost {
    self.apost = aPost;
}


- (BOOL)expectsWidePanel {
    return YES;
}


#pragma mark -
#pragma mark Instance Methods

- (void)refreshUI {
    titleLabel.text = self.apost.postTitle;
    if (self.post) {
        tagsLabel.text = self.post.tags;
        categoriesLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
    }
	if ((self.apost.mt_text_more != nil) && ([self.apost.mt_text_more length] > 0)) {
		contentView.text = [NSString stringWithFormat:@"%@\n<!--more-->\n%@", self.apost.content, self.apost.mt_text_more];
    } else {
		contentView.text = self.apost.content;
        
        NSString *postPreviewPath = [[NSBundle mainBundle] pathForResource:@"postpreview" ofType:@"html"];
        NSString *htmlStr = [NSString stringWithContentsOfFile:postPreviewPath encoding:NSUTF8StringEncoding error:nil];
        NSString *contentStr = [self.apost.content stringByReplacingOccurrencesOfRegex:@">\\n+<" withString:@"><"];
        contentStr = [contentStr stringByReplacingOccurrencesOfRegex:@"\\n{3,999}" withString:@"\n"];
        contentStr = [htmlStr stringByAppendingString:contentStr];
        [contentWebView loadHTMLString:contentStr baseURL:nil];
    }
}


- (void)showModalEditor {
    if (self.modalViewController) {
        NSLog(@"Trying to show editor a second time: bad");
        return;
    }
	if (self.apost.remoteStatus == AbstractPostRemoteStatusPushing) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't edit just yet", @"")
														message:NSLocalizedString(@"Sorry, you can't edit a post while it's being uploaded. Try again in a moment", @"")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", @"")
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
    EditPostViewController *postViewController;
	[self checkForNewItem];
    AbstractPost *postRevision = [self.apost createRevision];
    postViewController = [self getPostOrPageController: postRevision];
    postViewController.editMode = kEditPost;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editorDismissed:) name:@"PostEditorDismissed" object:postViewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:postViewController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //nav.navigationBar.tintColor = [UIColor colorWithRed:31/256.0 green:126/256.0 blue:163/256.0 alpha:1.0];
    [self presentModalViewController:nav animated:YES];
    [nav release];
}


- (EditPostViewController *)getPostOrPageController:(AbstractPost *)revision {
	return [[[EditPostViewController alloc] initWithPost:revision] autorelease];
}

// Subclassed in PageViewController
- (void)checkForNewItem {
	if(!self.apost)  //when it was a new post and user clicked on cancel
		self.apost = [[Post newDraftForBlog:self.blog] autorelease];
}


- (void)editorDismissed:(NSNotification *)aNotification {
    if (![self.apost hasRemote] && self.apost.remoteStatus == AbstractPostRemoteStatusLocal && !self.apost.postTitle && !self.apost.content) {
		//do not remove the post here. it is removed in EditPostViewController
		[self.apost deletePostWithSuccess:nil failure:nil]; //this is a local draft no remote errors checking.
		self.apost = nil;
    }
    [self refreshUI];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    // Did the touch ended inside?
    if (CGRectContainsPoint(self.view.bounds, point)) {
        [self showModalEditor];
    }
}


#pragma mark -
#pragma mark UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Disable user interaction if we don't need to scroll. This will let taps on the view invoke 
    // the edit form.
    UIScrollView *scrollView = nil;
    if ([webView respondsToSelector:@selector(scrollView)]) {
        scrollView = (UIScrollView *)[webView performSelector:@selector(scrollView)];
    } else {
        for (UIView* subView in webView.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView*)subView;
                break;
            }
        }
    }
    if (scrollView.contentSize.height > webView.bounds.size.height) {
        webView.userInteractionEnabled = YES;
    } else {
        webView.userInteractionEnabled = NO;
    }
}


@end
