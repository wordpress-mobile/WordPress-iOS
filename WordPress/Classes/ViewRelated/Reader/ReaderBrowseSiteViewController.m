#import "ReaderBrowseSiteViewController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderSiteHeaderView.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPTabBarController.h"
#import "WordPress-Swift.h"

static const NSInteger ReaderSiteHeaderHeight = 44.0;
static const NSInteger ReaderSiteHeaderTopPadding = 10.0;
static const NSInteger ReaderSiteHeaderHorizontalPadding = 8.0;

@interface ReaderBrowseSiteViewController ()
@property (nonatomic, strong) ReaderPostsViewController *postsViewController;
@property (nonatomic, strong) ReaderSiteHeaderView *headerView;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderTopic *siteTopic;
@end

@implementation ReaderBrowseSiteViewController

#pragma mark - Lifecycle Methods

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

    if (!self.post) {
        return;
    }

    [self createSiteTopic];
    [self configureHeaderView];
    [self configurePostsViewController];
    [self configureViewConstraints];
}

- (void)createSiteTopic
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    self.siteTopic = [topicService siteTopicForPost:self.post];
}

#pragma mark - Configuration

- (void)configureHeaderView
{
    self.headerView = [[ReaderSiteHeaderView alloc] init];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.title = self.siteTopic.title;
    self.headerView.subtitle = self.siteTopic.topicDescription;

    NSInteger imageWidth = (NSInteger)ReaderHeaderViewAvatarSize;
    NSString *blogPath = [self.post.blogURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *mshotPath = [NSString stringWithFormat:@"http://s.wordpress.com/mshots/v1/%@/?w=%d", blogPath, imageWidth];

    // TODO: Need loading placeholder.
    if (!self.post.isPrivate) {
        [self.headerView.avatarImageView setImageWithURL:[NSURL URLWithString:mshotPath] placeholderImage:[UIImage imageNamed:@""]];
    } else {
        // TODO: Need "Lock" icon for private sites.
        [self.headerView.avatarImageView setImage:[UIImage imageNamed:@""]];
    }

    [self.view addSubview:self.headerView];
}

- (void)configurePostsViewController
{
    self.postsViewController = [[ReaderPostsViewController alloc] init];
    self.postsViewController.readerViewStyle = ReaderViewStyleSitePreview;
    self.postsViewController.skipIpadTopPadding = YES;
    [self addChildViewController:self.postsViewController];
    UIView *childView = self.postsViewController.view;
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];
    [self.postsViewController didMoveToParentViewController:self];

    self.postsViewController.readerTopic = self.siteTopic;
}

- (void)configureViewConstraints
{
    NSInteger headerIpadWidth = WPTableViewFixedWidth - (ReaderSiteHeaderHorizontalPadding * 2);
    UIView *postsView = self.postsViewController.view;
    UIView *headerView = self.headerView;
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, postsView);
    NSDictionary *metrics = @{
                              @"headerHeight":@(ReaderSiteHeaderHeight),
                              @"headerIpadWidth":@(headerIpadWidth),
                              @"headerTopPadding":@(ReaderSiteHeaderTopPadding),
                              @"headerHorizontalPadding":@(ReaderSiteHeaderHorizontalPadding)
                              };
    if ([UIDevice isPad]) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[headerView(headerIpadWidth)]"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];

    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(headerHorizontalPadding)-[headerView]-(headerHorizontalPadding)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(headerTopPadding)-[headerView]-[postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view setNeedsUpdateConstraints];
}

@end
