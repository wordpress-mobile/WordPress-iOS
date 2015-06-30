#import "ReaderBrowseSiteViewController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderPostAttributionView.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderPreviewHeaderView.h"
#import "ReaderSiteHeaderView.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTabBarController.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

@interface ReaderBrowseSiteViewController ()<WPContentAttributionViewDelegate>
@property (nonatomic, strong) ReaderPostsViewController *postsViewController;
@property (nonatomic, strong) ReaderSiteHeaderView *siteHeaderView;
@property (nonatomic, strong) ReaderPreviewHeaderView *tableHeaderView;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderTopic *siteTopic;
@end

@implementation ReaderBrowseSiteViewController

#pragma mark - Lifecycle Methods

- (void)dealloc
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [service deleteTopic:self.siteTopic];
}

- (instancetype)initWithPost:(ReaderPost *)post
{
    self = [super init];
    if (self) {
        _post = post;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Site Detail", @"Title of the blog preview screen. The screen shows a list of posts from a blog and provides an option to follow the blog.");
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    if (!self.post) {
        return;
    }

    [self createSiteTopic];
    [self configureSiteHeaderView];
    [self configurePostsViewController];
    [self configureViewConstraints];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (self.tableHeaderView) {
        CGSize size = [self.tableHeaderView sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.frame), CGFLOAT_HEIGHT_UNKNOWN)];
        self.tableHeaderView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
        [self.postsViewController setTableHeaderView:self.tableHeaderView];
    }
}


#pragma mark - Configuration

- (void)createSiteTopic
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    self.siteTopic = [topicService siteTopicForPost:self.post];
}

- (void)configureSiteHeaderView
{
    self.siteHeaderView = [[ReaderSiteHeaderView alloc] init];
    self.siteHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.siteHeaderView.backgroundColor = [UIColor whiteColor];

    ReaderPostAttributionView *attributionView = self.siteHeaderView.attributionView;
    attributionView.attributionNameLabel.text = self.siteTopic.title;
    attributionView.delegate = self;
    attributionView.backgroundColor = [UIColor whiteColor];
    [attributionView selectAttributionButton:self.post.isFollowing];

    NSURL *blogURL = [NSURL URLWithString:self.post.blogURL];
    if (self.post.isWPCom) {
        [attributionView.avatarImageView setImageWithBlavatarUrl:[blogURL host] placeholderImage:[UIImage imageNamed:@"blavatar-wpcom"]];
    } else {
        [attributionView.avatarImageView setImageWithBlavatarUrl:[blogURL host] placeholderImage:[UIImage imageNamed:@"icon-feed"]];
    }

    [self.view addSubview:self.siteHeaderView];
}

- (void)configurePostsViewController
{
    // Build the post list
    self.postsViewController = [[ReaderPostsViewController alloc] init];
    self.postsViewController.readerViewStyle = ReaderViewStyleSitePreview;
    self.postsViewController.skipIpadTopPadding = YES;
    [self addChildViewController:self.postsViewController];
    UIView *childView = self.postsViewController.view;
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];
    [self.postsViewController didMoveToParentViewController:self];

    if (self.siteTopic.topicDescription) {
        // Build the table header
        self.tableHeaderView = [[ReaderPreviewHeaderView alloc] init];
        self.tableHeaderView.text = self.siteTopic.topicDescription;
        CGSize size = [self.tableHeaderView sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.frame), CGFLOAT_HEIGHT_UNKNOWN)];
        self.tableHeaderView.frame = CGRectMake(0.0, 0.0, size.width, size.height);
        [self.postsViewController setTableHeaderView:self.tableHeaderView];
    }

    self.postsViewController.readerTopic = self.siteTopic;
}

- (void)configureViewConstraints
{
    NSInteger headerIpadWidth = WPTableViewFixedWidth;
    UIView *postsView = self.postsViewController.view;
    UIView *siteHeaderView = self.siteHeaderView;
    NSDictionary *views = NSDictionaryOfVariableBindings(siteHeaderView, postsView);
    NSDictionary *metrics = @{@"headerIpadWidth":@(headerIpadWidth)};
    if ([UIDevice isPad]) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:siteHeaderView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[siteHeaderView(headerIpadWidth)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];

    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[siteHeaderView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[siteHeaderView][postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view setNeedsUpdateConstraints];
}

- (void)attributionViewDidReceiveAvatarAction:(WPContentAttributionView *)attributionView
{
    NSURL *targetURL = [NSURL URLWithString:self.post.blogURL];
    WPWebViewController *controller = [WPWebViewController webViewControllerWithURL:targetURL];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender
{
    UIButton *followButton = (UIButton *)sender;

    if (!self.post.isFollowing) {
        [WPAnalytics track:WPAnalyticsStatReaderFollowedSite];
    }

    [followButton setSelected:!self.post.isFollowing]; // Set it optimistically

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    [context performBlock:^{
        ReaderPost *postInContext = (ReaderPost *)[context existingObjectWithID:self.post.objectID error:nil];
        if (!postInContext) {
            return;
        }

        [service toggleFollowingForPost:postInContext success:nil failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogError(@"Error Following Blog : %@", [error localizedDescription]);
                [followButton setSelected:postInContext.isFollowing];
            });
        }];
    }];
}

@end
