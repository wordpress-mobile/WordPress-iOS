#import "ReaderBrowseSiteViewController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderPostService.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderSiteHeaderView.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "WPTabBarController.h"
#import "WordPress-Swift.h"

static const NSInteger ReaderSiteHeaderHeight = 44.0;

@interface ReaderBrowseSiteViewController ()
@property (nonatomic, strong) ReaderPostsViewController *postsViewController;
@property (nonatomic, strong) UIView *headerView;
@end

@implementation ReaderBrowseSiteViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureHeaderView];
    [self configurePostsViewController];
    [self configureViewConstraints];
}

- (void)configureHeaderView
{
    self.headerView = [[ReaderSiteHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), ReaderSiteHeaderHeight)];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerView];
}

- (void)configurePostsViewController
{
    self.postsViewController = [[ReaderPostsViewController alloc] init];
    [self addChildViewController:self.postsViewController];
    UIView *childView = self.postsViewController.view;
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];
    [self.postsViewController didMoveToParentViewController:self];
}

- (void)configureViewConstraints
{
    UIView *postsView = self.postsViewController.view;
    UIView *headerView = self.headerView;
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, postsView);
    NSDictionary *metrics = @{@"headerHeight":@(ReaderSiteHeaderHeight)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[headerView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerView(headerHeight)][postsView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];

    [self.view setNeedsUpdateConstraints];
}


@end
