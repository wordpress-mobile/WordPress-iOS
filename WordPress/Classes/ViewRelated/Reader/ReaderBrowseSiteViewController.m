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
#import "ReaderSiteService.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPTabBarController.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

@interface ReaderBrowseSiteViewController ()<WPContentAttributionViewDelegate>
@property (nonatomic, strong) ReaderPostsViewController *postsViewController;
@property (nonatomic, strong) ReaderSiteHeaderView *siteHeaderView;
@property (nonatomic, strong) ReaderPreviewHeaderView *tableHeaderView;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderTopic *siteTopic;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *siteURL;
@property (nonatomic) BOOL isFollowing;
@property (nonatomic) BOOL isWPcom;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
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
        _siteID = post.siteID;
        _siteURL = post.blogURL;
        _isWPcom = post.isWPCom;
        _isFollowing = post.isFollowing;
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        _siteTopic = [topicService siteTopicForPost:post];
    }
    return self;
}

- (instancetype)initWithSiteID:(NSNumber *)siteID siteURL:(NSString *)siteURL isWPcom:(BOOL)isWPcom
{
    self = [super init];
    if (self) {
        _siteID = siteID;
        _siteURL = siteURL;
        _isWPcom = isWPcom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Site Detail", @"Title of the blog preview screen. The screen shows a list of posts from a blog and provides an option to follow the blog.");
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];

    if (self.siteTopic) {
        [self configureView];
        return;
    }

    [self getTopicFromSiteID];
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

- (void)getTopicFromSiteID
{
    [self showLoadingSite];
    __weak __typeof(self) weakSelf = self;
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [topicService siteTopicForSiteWithID:self.siteID
                                 success:^(NSManagedObjectID *objectID, BOOL isFollowing) {
                                     weakSelf.isFollowing = isFollowing;
                                     NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                                     NSError *error;
                                     weakSelf.siteTopic = (ReaderTopic *)[context existingObjectWithID:objectID error:&error];
                                     if (error) {
                                         DDLogError(@"Error retrieving site topic from objectID : %@", error);
                                     }
                                     if (!weakSelf.siteTopic) {
                                         [weakSelf showLoadingFailed];
                                         return;
                                     }
                                     [weakSelf configureView];

                                 } failure:^(NSError *error) {
                                     [weakSelf showLoadingFailed];
                                 }];
}

- (void)configureView
{
    if (self.noResultsView) {
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;
    }
    [self configureSiteHeaderView];
    [self configurePostsViewController];
    [self configureViewConstraints];
}

- (void)showLoadingFailed
{
    self.noResultsView.titleText = NSLocalizedString(@"Problem Loading Site", @"Error message title informing the user that a site could not be loaded.");
    self.noResultsView.messageText = NSLocalizedString(@"Sorry. The site could not be loaded.", @"A short error message leting the user know the requested site could not be loaded.");
}

- (void)showLoadingSite
{
    if (!self.isViewLoaded) {
        return;
    }

    if (!self.noResultsView) {
        self.noResultsView = [[WPNoResultsView alloc] init];
    }

    // Refresh the NoResultsView Properties
    self.noResultsView.titleText = NSLocalizedString(@"Loading site...", @"A short message to inform the user the requested site is being loaded.");

    [self.noResultsView showInView:self.view];
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
    [attributionView selectAttributionButton:self.isFollowing];

    NSURL *blogURL = [NSURL URLWithString:self.siteURL];
    if (self.isWPcom) {
        [attributionView.avatarImageView setImageWithSiteIcon:[blogURL host] placeholderImage:[UIImage imageNamed:@"blavatar-default"]];
    } else {
        [attributionView.avatarImageView setImageWithSiteIcon:[blogURL host] placeholderImage:[UIImage imageNamed:@"icon-feed"]];
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
    NSURL *targetURL = [NSURL URLWithString:self.siteURL];
    WPWebViewController *controller = [WPWebViewController webViewControllerWithURL:targetURL];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)attributionView:(WPContentAttributionView *)attributionView didReceiveAttributionLinkAction:(id)sender
{
    // Update it optimistically
    UIButton *followButton = (UIButton *)sender;
    self.isFollowing = !self.isFollowing;
    [followButton setSelected:self.isFollowing];

    // Track all the things.
    if (self.isFollowing) {
        [WPAnalytics track:WPAnalyticsStatReaderFollowedSite];
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    __weak __typeof(self) weakSelf = self;
    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [postService setFollowing:self.isFollowing
           forWPComSiteWithID:self.siteID
                       andURL:self.siteURL
                      success:^{
                          // no op
                      } failure:^(NSError *error) {
                          DDLogError(@"Error Following/Unfollowing Site : %@", [error localizedDescription]);
                          // Roll back changes.
                          weakSelf.isFollowing = !weakSelf.isFollowing;
                          [followButton setSelected:weakSelf.isFollowing];
                      }];
}

@end
