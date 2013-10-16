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
#import "NewCreateAccountAndBlogViewController.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPWalkthroughOverlayView.h"
#import "WPNUXUtility.h"
#import "NewWPWalkthroughOverlayView.h"

@interface NewGeneralWalkthroughViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate> {
    UIPageViewController *_pageViewController;
    CGFloat _heightToUseForCentering;
    GeneralWalkthroughPage3ViewController *_page3ViewController;
}

@property (nonatomic, strong) IBOutlet UIView *bottomPanel;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UILabel *swipeToContinue;
@property (nonatomic, strong) IBOutlet UILabel *createAccountLabel;
@property (nonatomic, strong) IBOutlet WPNUXSecondaryButton *createAccountButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *signInButton;

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
    
    [self addBackgroundTexture];
    
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _pageViewController.dataSource = self;
    _pageViewController.delegate = self;
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
    
    _page3ViewController = (GeneralWalkthroughPage3ViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage3"];
    _page3ViewController.containingView = self.view;
    
    self.swipeToContinue.text = [NSLocalizedString(@"swipe to continue", nil) uppercaseString];
    
    self.createAccountLabel.text = NSLocalizedString(@"Don't have an account? Create one!", nil);
    self.createAccountLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    self.createAccountLabel.alpha = 0.0;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedCreateAccount:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.createAccountLabel addGestureRecognizer:tapGestureRecognizer];

    [self.createAccountButton setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
    
    [self.signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    
    self.pageControl.numberOfPages = 3;
    [WPNUXUtility configurePageControlTintColors:self.pageControl];
    
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
        vc = [self page2ViewController];
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
        vc = [self page3ViewController];
    }
    
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
        vc = [self page1ViewController];
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
        vc = [self page2ViewController];
    }
    
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    [self setPageNumberForViewController:[pendingViewControllers objectAtIndex:0]];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (!completed)
        return;
    
    if ([[previousViewControllers objectAtIndex:0] isKindOfClass:[GeneralWalkthroughPage2ViewController class]]  && [[pageViewController.viewControllers objectAtIndex:0] isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
        // Viewing Page 3 from Page 2
        [self showCreateAccountLabelAndHideButtons];
    } else if ([[previousViewControllers objectAtIndex:0] isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
        // Viewing Page 2 from Page 3
        [self hideCreateAccountLabelAndShowButtons];
    }
    
    [self togglePageNumberVisibilityBasedOnPage];
}

- (void)setPageNumberForViewController:(UIView *)viewController
{
    if ([viewController isKindOfClass:[GeneralWalkthroughPage1ViewController class]]) {
        self.pageControl.currentPage = 0;
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage2ViewController class]]) {
        self.pageControl.currentPage = 1;
    } else if ([viewController isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
        self.pageControl.currentPage = 2;
    }
}

- (void)togglePageNumberVisibilityBasedOnPage
{
    if (self.pageControl.currentPage < 2) {
        self.pageControl.hidden = NO;
        self.swipeToContinue.hidden = NO;
    } else {
        self.pageControl.hidden = YES;
        self.swipeToContinue.hidden = YES;
    }
}

#pragma mark - IBAction Methods

- (IBAction)clickedSignIn:(id)sender
{
    // TODO : Clean this up
    GeneralWalkthroughPage2ViewController *page2ViewController = (GeneralWalkthroughPage2ViewController *)[self page2ViewController];
    GeneralWalkthroughPage3ViewController *page3ViewController = (GeneralWalkthroughPage3ViewController *)[self page3ViewController];
    __weak UIPageViewController *pageViewController = _pageViewController;
    __weak NewGeneralWalkthroughViewController *weakSelf = self;
    self.pageControl.currentPage = 2;
    [_pageViewController setViewControllers:@[page2ViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        [pageViewController setViewControllers:@[page3ViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
            [weakSelf showCreateAccountLabelAndHideButtons];
            [weakSelf togglePageNumberVisibilityBasedOnPage];
        }];
    }];
}

- (IBAction)clickedCreateAccount:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedCreateAccount];
    NewCreateAccountAndBlogViewController *vc = (NewCreateAccountAndBlogViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccount"];
    vc.onCreatedUser = ^(NSString *username, NSString *password) {
        [self.navigationController popViewControllerAnimated:NO];
        GeneralWalkthroughPage3ViewController *page3 = (GeneralWalkthroughPage3ViewController *)[self page3ViewController];
        
        if (![[_pageViewController.viewControllers objectAtIndex:0] isKindOfClass:[GeneralWalkthroughPage3ViewController class]]) {
            [_pageViewController setViewControllers:@[page3] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
                [page3 setUsername:username];
                [page3 setPassword:password];
                [page3 showAddUsersBlogsForWPCom];
            }];
        } else {
            [page3 setUsername:username];
            [page3 setPassword:password];
            [page3 showAddUsersBlogsForWPCom];
        }
    };
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Methods

- (void)addBackgroundTexture
{
    UIView *mainTextureView = [[UIView alloc] initWithFrame:self.view.bounds];
    mainTextureView.translatesAutoresizingMaskIntoConstraints = NO;
    mainTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    [self.view addSubview:mainTextureView];
    mainTextureView.userInteractionEnabled = NO;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(mainTextureView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainTextureView]|" options:0 metrics:0 views:views];
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mainTextureView]|" options:0 metrics:0 views:views];
    
    [self.view addConstraints:horizontalConstraints];
    [self.view addConstraints:verticalConstraints];
}

- (void)hideCreateAccountLabelAndShowButtons
{
    [UIView animateWithDuration:0.25 animations:^{
        self.createAccountLabel.alpha = 0.0;
        self.createAccountButton.alpha = 1.0;
        self.signInButton.alpha = 1.0;
    }];
}

- (void)showCreateAccountLabelAndHideButtons
{
    [UIView animateWithDuration:0.25 animations:^{
        self.createAccountLabel.alpha = 1.0;
        self.createAccountButton.alpha = 0.0;
        self.signInButton.alpha = 0.0;
    }];
}

- (UIViewController *)page1ViewController
{
    GeneralWalkthroughPage1ViewController *page1 = (GeneralWalkthroughPage1ViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage1"];
    page1.heightToUseForCentering = _heightToUseForCentering;
    return page1;
}

- (UIViewController *)page2ViewController
{
    GeneralWalkthroughPage2ViewController *page2 = (GeneralWalkthroughPage2ViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"GeneralWalkthroughPage2"];
    page2.heightToUseForCentering = _heightToUseForCentering;
    return page2;
}

- (UIViewController *)page3ViewController
{
    _page3ViewController.heightToUseForCentering = _heightToUseForCentering;
    return _page3ViewController;
}


@end
