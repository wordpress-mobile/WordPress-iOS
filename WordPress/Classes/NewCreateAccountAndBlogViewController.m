//
//  NewCreateAccountAndBlogViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewCreateAccountAndBlogViewController.h"
#import "CreateAccountAndBlogPage1ViewController.h"
#import "CreateAccountAndBlogPage2ViewController.h"
#import "CreateAccountAndBlogPage3ViewController.h"
#import "WPNUXBackButton.h"

@interface NewCreateAccountAndBlogViewController () <UIPageViewControllerDataSource> {
    UIPageViewController *_pageViewController;
}

@property (nonatomic, strong) IBOutlet WPNUXBackButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *helpButton;

@end

@implementation NewCreateAccountAndBlogViewController

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

    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.dataSource = self;
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage1"];
    [_pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:_pageViewController];
    [[self view] addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];

    [self.view bringSubviewToFront:self.backButton];
    [self.view bringSubviewToFront:self.helpButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - UIPageViewController Delegate methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[CreateAccountAndBlogPage1ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage2"];
    } else if ([viewController isKindOfClass:[CreateAccountAndBlogPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage3"];
    }
    
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[CreateAccountAndBlogPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage1"];
    } else if ([viewController isKindOfClass:[CreateAccountAndBlogPage3ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage2"];
    }
    
    return vc;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 3;
}


@end
