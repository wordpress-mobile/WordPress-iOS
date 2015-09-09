#import "RelatedPostsSettingsViewController.h"
#import "Blog.h"

@interface RelatedPostsSettingsViewController()

@property (nonatomic, strong) Blog *blog;

@end
@implementation RelatedPostsSettingsViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.navigationItem.title = NSLocalizedString(@"Related Posts", @"Title for screen that allows configuration of your blog/site related posts settings.");
}
@end
