#import "ReaderViewController.h"

#import <WordPressShared/WPStyleGuide.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "CustomHighlightButton.h"
#import "ReaderPostService.h"
#import "ReaderSubscriptionViewController.h"
#import "ReaderTopicService.h"
#import "WordPressAppDelegate.h"
#import "WPTabBarController.h"
#import "WordPress-Swift.h"

@interface ReaderViewController () <UIViewControllerRestoration>
@property (nonatomic, strong) ReaderStreamViewController *postsViewController;
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
        [self cleanupPreviewedPostsAndTopics];

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

    ReaderAbstractTopic *topic = [self currentTopic];
    if (topic) {
        [self assignTopic:topic];
    } else {
        [self syncTopics];
    }
}


#pragma mark - Public methods

- (void)openPost:(NSNumber *)postID onBlog:(NSNumber *)blogID
{
    ReaderDetailViewController *controller = [ReaderDetailViewController controllerWithPostID:postID siteID:blogID];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Private Methods

#pragma mark - Getters / Setters

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (ReaderAbstractTopic *)currentTopic
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
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Menu", @"")
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(topicsAction:)];
    [button setAccessibilityLabel:NSLocalizedString(@"Menu", @"Accessibility label for the menu button. The user does not see this text but it can be spoken by a screen reader.")];
    navigationItem.leftBarButtonItem = button;
}

- (void)configurePostsViewController
{
    if (self.postsViewController) {
        [self.postsViewController.view removeFromSuperview];
        [self.postsViewController removeFromParentViewController];
        self.postsViewController = nil;
    }

    self.postsViewController = [ReaderStreamViewController controllerWithTopic:nil];
    [self addChildViewController:self.postsViewController];
    UIView *childView = self.postsViewController.view;
    childView.frame = self.view.bounds;
    childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:childView];
    [self.postsViewController didMoveToParentViewController:self];
}

- (void)cleanupPreviewedPostsAndTopics
{
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [topicService deleteNonMenuTopics];

    ReaderPostService *postService = [[ReaderPostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService deletePostsWithNoTopic];
}

- (void)syncTopics
{
    if ([WordPressAppDelegate sharedInstance].testSuiteIsRunning) {
        // Skip syncing when running the test suite.
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

- (void)assignTopic:(ReaderAbstractTopic *)topic
{
    // Update our title
    if (topic) {
        self.navigationItem.title = topic.title;
    } else {
        self.navigationItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");
    }

    // Don't recycle an existing controller.  Instead create a new one.
    // This resolves some layout issues swapping out tableHeaderViews on iOS 9
    if (self.postsViewController.readerTopic && ![self.postsViewController.readerTopic isEqual:topic]) {
        [self configurePostsViewController];
    }

    self.postsViewController.readerTopic = topic;
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
    [self.postsViewController scrollViewToTop];
}

@end
