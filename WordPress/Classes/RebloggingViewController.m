#import "RebloggingViewController.h"
#import "ReaderPost.h"
#import "ReaderPostView.h"
#import "BlogSelectorViewController.h"
#import "WPBlogSelectorButton.h"
#import "BlogService.h"
#import "ContextManager.h"

@interface RebloggingViewController ()<UIPopoverControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *titleBarButton;
@property (nonatomic, strong) UIPopoverController *blogSelectorPopover;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) ReaderPostView *postView;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation RebloggingViewController

- (id)initWithPost:(id)post {
    self = [self init];
    if (self){
        self.post = post;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureNavbar];
    [self configurePostInfo];
}

- (void)configureNavbar {

    if (!self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Publish", @"")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(handlePublishAction:)];
    }

    if (!self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(handleCancelAction:)];
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    NSInteger blogCount = [blogService blogCountForAllAccounts];
    if (blogCount < 2) {
        self.navigationItem.title = NSLocalizedString(@"Reblog", @"");
    } else {
        UIButton *titleButton = self.titleBarButton;
        self.navigationItem.titleView = titleButton;
        NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Reblog to", @"")]
                                                                                      attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Bold" size:14.0] }];

        if (!self.blog) {
            self.blog = [blogService lastUsedOrFirstWPcomBlog];
        }
        NSDictionary *subtextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:10.0] };
        NSMutableAttributedString *titleSubtext = [[NSMutableAttributedString alloc] initWithString:self.blog.blogName
                                                                                         attributes:subtextAttributes];
        [titleText appendAttributedString:titleSubtext];
        [titleButton setAttributedTitle:titleText forState:UIControlStateNormal];
        [titleButton sizeToFit];
    }
}


- (UIButton *)titleBarButton {
    if (_titleBarButton) {
        return _titleBarButton;
    }
    UIButton *titleButton = [WPBlogSelectorButton buttonWithType:UIButtonTypeSystem];
    titleButton.frame = CGRectMake(0.0f, 0.0f, 200.0f, 33.0f);
    titleButton.titleLabel.numberOfLines = 2;
    titleButton.titleLabel.textColor = [UIColor whiteColor];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [titleButton setImage:[UIImage imageNamed:@"icon-navbar-dropdown.png"] forState:UIControlStateNormal];
    [titleButton addTarget:self action:@selector(showBlogSelector) forControlEvents:UIControlEventTouchUpInside];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [titleButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [titleButton setAccessibilityHint:NSLocalizedString(@"Tap to select which site to publish to", nil)];

    _titleBarButton = titleButton;

    return _titleBarButton;
}


- (void)showBlogSelector {
    if (IS_IPAD && self.blogSelectorPopover.isPopoverVisible) {
        [self.blogSelectorPopover dismissPopoverAnimated:YES];
        self.blogSelectorPopover = nil;
    }

    void (^dismissHandler)() = ^(void) {
        if (IS_IPAD) {
            [self.blogSelectorPopover dismissPopoverAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    };
    void (^selectedCompletion)(NSManagedObjectID *) = ^(NSManagedObjectID *selectedObjectID) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        Blog *blog = (Blog *)[context objectWithID:selectedObjectID];
        if (blog) {
            self.blog = blog;
        }
        [self configureNavbar];
        dismissHandler();
    };

    BlogSelectorViewController *vc = [[BlogSelectorViewController alloc] initWithSelectedBlogObjectID:self.blog.objectID
                                                                                   selectedCompletion:selectedCompletion
                                                                                     cancelCompletion:dismissHandler];
    vc.title = NSLocalizedString(@"Select Site", @"");

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.translucent = NO;
    navController.navigationBar.barStyle = UIBarStyleBlack;

    if (IS_IPAD) {
        vc.preferredContentSize = CGSizeMake(320.0, 500);

        CGRect titleRect = self.navigationItem.titleView.frame;
        titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];

        self.blogSelectorPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.blogSelectorPopover.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
        self.blogSelectorPopover.delegate = self;
        [self.blogSelectorPopover presentPopoverFromRect:titleRect inView:self.navigationController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

    } else {
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)configurePostInfo {
    if (!self.postView) {
        self.postView = [[ReaderPostView alloc] initWithFrame:self.view.bounds showFullContent:NO];
        self.postView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.postView configurePost:self.post];
    }
    [self.view addSubview:self.postView];
}

- (void)configureNoteForm {
    if (!self.textView) {
        self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];

    }
    [self.view addSubview:self.textView];
}

- (void)handleCancelAction:(id)sender {
    [self dismiss];
}

- (void)handlePublishAction:(id)sender {
    [self dismiss];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
