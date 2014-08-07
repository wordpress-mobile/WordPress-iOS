#import "PostDetailViewController.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/NSString+Util.h>
#import "AbstractPost.h"
#import "Post.h"
#import "EditPostViewController.h"
#import "NSString+Helpers.h"
#import "EditPostTransition.h"



NSString *const WPPostDetailNavigationRestorationID = @"WPPostDetailNavigationRestorationID";

@interface PostDetailViewController() <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) AbstractPost *aPost;
@property (weak, nonatomic) IBOutlet UIWebView *previewWebView;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;

@end

@implementation PostDetailViewController

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _aPost = aPost;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Setup

- (void)setupNavbar
{
    if (self.navigationItem.rightBarButtonItem == nil) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Label for the button to edit the currently displayed post")
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(editPost)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}

- (void)setupPreviewView
{
    [self.previewWebView loadHTMLString:self.aPost.contentForDisplay baseURL:nil];
}

- (void)setupTagsView
{
    self.tagsLabel.font = [WPStyleGuide regularTextFont];
    self.tagsLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];
    if (self.post && ![self.post.tags isEmpty]) {
        self.tagsLabel.text = self.post.tags;
    } else {
        self.tagsLabel.text = @"No tags for you!";
    }
}

#pragma mark - Actions

- (void)editPost
{
    EditPostViewController *editPostViewController = [[EditPostViewController alloc] initWithPost:self.aPost];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationCustom;
    navController.transitioningDelegate = self;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    [self.view.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    EditPostTransition *transition = [[EditPostTransition alloc] init];
    transition.mode = EditPostTransitionModePresent;
    return transition;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    //Need to refresh the post on this screen before the transition
    [self refreshDisplay];
    
    EditPostTransition *transition = [[EditPostTransition alloc] init];
    transition.mode = EditPostTransitionModeDismiss;
    return transition;
}

#pragma mark - Instance Methods

- (Post *)post {
    if ([self.aPost isKindOfClass:[Post class]]) {
        return (Post *)self.aPost;
    } else {
        return nil;
    }
}

- (void)refreshDisplay
{
    self.navigationItem.title = self.aPost.titleForDisplay;
    [self setupTagsView];
    [self setupPreviewView];
}

@end
