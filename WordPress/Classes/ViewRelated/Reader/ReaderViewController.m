#import "ReaderViewController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderPostService.h"
#import "ReaderPostsViewController.h"
#import "ReaderPostDetailViewController.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "WPTabBarController.h"
#import "WordPress-Swift.h"

@interface ReaderViewController () <UIViewControllerRestoration>
@property (nonatomic, strong) ReaderPostsViewController *postsViewController;
@end

@implementation ReaderViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WPTabBarController sharedInstance] readerViewController];
}

#pragma mark - Life Cycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAccount:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerTopicDidChange:) name:ReaderTopicDidChangeNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureNavBar];
    [self configurePostsViewController];

    ReaderTopic *topic = [self currentTopic];
    if (topic) {
        [self assignTopic:topic];
    } else {
        [self syncTopics];
    }

}


#pragma mark - Public methods

- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId
{
    ReaderPostDetailViewController *controller = [ReaderPostDetailViewController detailControllerWithPostID:postId siteID:blogId];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Private Methods

#pragma mark - Getters / Setters

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (ReaderTopic *)currentTopic
{
    return [[[ReaderTopicService alloc] initWithManagedObjectContext:[self managedObjectContext]] currentTopic];
}


#pragma mark - Instance methods

- (void)configureNavBar
{
    UINavigationItem *navigationItem = self.navigationItem;

    // Don't show 'Reader' in the next-view back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    navigationItem.backBarButtonItem = backButton;

    // Topics button
    UIImage *image = [UIImage imageNamed:@"icon-reader-topics"];
    CustomHighlightButton *topicsButton = [CustomHighlightButton buttonWithType:UIButtonTypeCustom];
    topicsButton.tintColor = [WPStyleGuide navbarButtonTintColor];
    [topicsButton setImage:image forState:UIControlStateNormal];
    topicsButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    [topicsButton addTarget:self action:@selector(topicsAction:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:topicsButton];
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"Accessibility label for the topics button. The user does not see this text but it can be spoken by a screen reader.")];
    navigationItem.rightBarButtonItem = button;

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:button forNavigationItem:navigationItem];
}

- (void)configurePostsViewController
{
    self.postsViewController = [[ReaderPostsViewController alloc] init];
    [self addChildViewController:self.postsViewController];
    UIView *childView = self.postsViewController.view;
    childView.frame = self.view.bounds;
    childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:childView];
    [self.postsViewController didMoveToParentViewController:self];
}

- (void)syncTopics
{
    // TODO: Should we check for an account?
    NSManagedObjectContext *context = [self managedObjectContext];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    if ([service numberOfAccounts] == 0) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [topicService fetchReaderMenuWithSuccess:^{
        [weakSelf assignTopic:[weakSelf currentTopic]];
    } failure:^(NSError *error) {
        DDLogError(@"Error refreshing topics: %@", error);
    }];
}

- (void)assignTopic:(ReaderTopic *)topic
{
    self.postsViewController.readerTopic = topic;

    // Update our title
    if (topic) {
        self.title = topic.title;
    } else {
        self.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
    }

    // Make sure that the tab bar item does not change its title.
    self.navigationController.tabBarItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
}


#pragma mark - Notifications

- (void)readerTopicDidChange:(NSNotification *)notification
{
    if (!self.postsViewController) {
        return;
    }

    [self assignTopic:[self currentTopic]];
}

- (void)didChangeAccount:(NSNotification *)notification
{
    [self assignTopic:nil];
    [self.navigationController popToViewController:self animated:NO];

    NSManagedObjectContext *context = [self managedObjectContext];
    [[[ReaderTopicService alloc] initWithManagedObjectContext:context] deleteAllTopics];
    [[[ReaderPostService alloc] initWithManagedObjectContext:context] deletePostsWithNoTopic];

    [self syncTopics];
}


#pragma mark - Actions

- (void)topicsAction:(id)sender
{
    ReaderSubscriptionViewController *controller = [[ReaderSubscriptionViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Scrollable Controller

- (void)scrollViewToTop
{
    [self.postsViewController.tableView setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
}

@end
