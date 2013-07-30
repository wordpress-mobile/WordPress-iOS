//
//  NewGeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewGeneralWalkthroughViewController.h"
#import "GeneralWalkthroughPage1ViewController.h"
#import "GeneralWalkthroughPage2ViewController.h"
#import "GeneralWalkthroughPage3ViewController.h"

@interface NewGeneralWalkthroughViewController () <UIPageViewControllerDataSource> {
    UIPageViewController *_pageViewController;
    CGFloat _heightToUseForCentering;
}

@property (nonatomic, strong) IBOutlet UIView *bottomPanel;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UILabel *swipeToContinue;

@end

@implementation NewGeneralWalkthroughViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This view just helps us visually see the page controller layout
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _pageViewController.dataSource = self;
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage1"];
    [_pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:_pageViewController];
    [[self view] addSubview:_pageViewController.view];
    
    UIView *pageViewController = _pageViewController.view;
    UIView *bottomPanel = self.bottomPanel;
    NSDictionary *views = NSDictionaryOfVariableBindings(pageViewController, bottomPanel);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[pageViewController]|" options:0 metrics:0 views:views];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[pageViewController][bottomPanel]|" options:0 metrics:0 views:views];
    [self.view addConstraints:horizontalConstraints];
    [self.view addConstraints:verticalConstraints];
    [_pageViewController didMoveToParentViewController:self];
    
    self.swipeToContinue.text = [NSLocalizedString(@"swipe to continue", nil) uppercaseString];
    [self.view bringSubviewToFront:self.swipeToContinue];
    
    [self.view bringSubviewToFront:self.pageControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLayoutSubviews
{
    _heightToUseForCentering = CGRectGetMinY(self.swipeToContinue.frame);
    for (UIViewController *vc in _pageViewController.childViewControllers) {
        if ([vc isKindOfClass:[GeneralWalkthroughPage1ViewController class]]) {
            GeneralWalkthroughPage1ViewController *page1 = (GeneralWalkthroughPage1ViewController *)vc;
            page1.heightToUseForCentering = _heightToUseForCentering;
            [page1.view setNeedsUpdateConstraints];
        } else if ([vc isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
            GeneralWalkthroughPage2ViewController *page2 = (GeneralWalkthroughPage2ViewController *)vc;
            page2.heightToUseForCentering = _heightToUseForCentering;
            [page2.view setNeedsUpdateConstraints];
        } else if ([vc isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
            GeneralWalkthroughPage3ViewController *page3 = (GeneralWalkthroughPage3ViewController *)vc;
            page3.heightToUseForCentering = _heightToUseForCentering;
            [page3.view setNeedsUpdateConstraints];
        }
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UIPageViewController Delegate methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[GeneralWalkthroughPage1ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage2"];
        GeneralWalkthroughPage2ViewController *page2 = (GeneralWalkthroughPage2ViewController *)vc;
        page2.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage3"];
        GeneralWalkthroughPage3ViewController *page3 = (GeneralWalkthroughPage3ViewController *)vc;
        page3.heightToUseForCentering = _heightToUseForCentering;
    }
    
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage1"];
        GeneralWalkthroughPage1ViewController *page1 = (GeneralWalkthroughPage1ViewController *)vc;
        page1.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage2"];
        GeneralWalkthroughPage2ViewController *page2 = (GeneralWalkthroughPage2ViewController *)vc;
        page2.heightToUseForCentering = _heightToUseForCentering;
    }
    
    return vc;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 3;
}

@end
