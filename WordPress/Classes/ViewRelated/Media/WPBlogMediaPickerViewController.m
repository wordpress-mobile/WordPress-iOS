#import "WPBlogMediaPickerViewController.h"
#import "WPBlogMediaCollectionViewController.h"

@interface WPBlogMediaPickerViewController () <UINavigationControllerDelegate>

@end

@implementation WPBlogMediaPickerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self ) {
        _showMostRecentFirst = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self setupNavigationController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationController
{
    WPBlogMediaCollectionViewController *vc = [[WPBlogMediaCollectionViewController alloc] init];
    vc.blog = self.blog;
    vc.showMostRecentFirst = self.showMostRecentFirst;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.delegate = self;
    
    [nav willMoveToParentViewController:self];
    [nav.view setFrame:self.view.bounds];
    [self.view addSubview:nav.view];
    [self addChildViewController:nav];
    [nav didMoveToParentViewController:self];
}

@end
