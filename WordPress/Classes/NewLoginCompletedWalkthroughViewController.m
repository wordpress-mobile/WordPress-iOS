//
//  NewLoginCompletedWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewLoginCompletedWalkthroughViewController.h"
#import "LoginCompletedWalkthroughPage1ViewController.h"
#import "LoginCompletedWalkthroughPage2ViewController.h"
#import "LoginCompletedWalkthroughPage3ViewController.h"
#import "LoginCompletedWalkthroughPage4ViewController.h"
#import "WPNUXUtility.h"
#import "NewWPWalkthroughOverlayView.h"
#import "WordPressAppDelegate.h"

@interface NewLoginCompletedWalkthroughViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate> {
    UIPageViewController *_pageViewController;
    CGFloat _heightToUseForCentering;
    BOOL _isDismissing;
}

@property (nonatomic, strong) IBOutlet UIView *bottomPanel;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UILabel *tapToDismiss;
@property (nonatomic, strong) IBOutlet UILabel *swipeToContinue;

@end

@implementation NewLoginCompletedWalkthroughViewController

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
    
    // This view just helps us visually see the page controller layout
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    _pageViewController.dataSource = self;
    _pageViewController.delegate = self;
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage1"];
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
    self.swipeToContinue.font = [WPNUXUtility swipeToContinueFont];
    
    self.tapToDismiss.text = NSLocalizedString(@"Tap to start using WordPress", @"NUX Second Walkthrough Bottom Skip Label");
    self.tapToDismiss.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    
    self.pageControl.numberOfPages = 4;
    
    [WPNUXUtility configurePageControlTintColors:self.pageControl];
    
    [self.view bringSubviewToFront:self.swipeToContinue];
    [self.view bringSubviewToFront:self.pageControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];

    [self showLoginSuccess];

}

- (void)viewDidLayoutSubviews
{
    _heightToUseForCentering = CGRectGetMinY(self.swipeToContinue.frame);
    for (UIViewController *vc in _pageViewController.childViewControllers) {
        if ([vc isKindOfClass:[LoginCompletedWalkthroughPage1ViewController class]]) {
            LoginCompletedWalkthroughPage1ViewController *page1 = (LoginCompletedWalkthroughPage1ViewController *)vc;
            page1.heightToUseForCentering = _heightToUseForCentering;
            [page1.view setNeedsUpdateConstraints];
        } else if ([vc isKindOfClass:[LoginCompletedWalkthroughPage2ViewController class]]) {
            LoginCompletedWalkthroughPage2ViewController *page2 = (LoginCompletedWalkthroughPage2ViewController *)vc;
            page2.heightToUseForCentering = _heightToUseForCentering;
            [page2.view setNeedsUpdateConstraints];
        } else if ([vc isKindOfClass:[LoginCompletedWalkthroughPage3ViewController class]]) {
            LoginCompletedWalkthroughPage3ViewController *page3 = (LoginCompletedWalkthroughPage3ViewController *)vc;
            page3.heightToUseForCentering = _heightToUseForCentering;
            [page3.view setNeedsUpdateConstraints];
        } else if ([vc isKindOfClass:[LoginCompletedWalkthroughPage4ViewController class]]) {
            LoginCompletedWalkthroughPage4ViewController *page4 = (LoginCompletedWalkthroughPage4ViewController *)vc;
            page4.heightToUseForCentering = _heightToUseForCentering;
            [page4.view setNeedsUpdateConstraints];
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
    
    if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage1ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage2"];
        LoginCompletedWalkthroughPage2ViewController *page2 = (LoginCompletedWalkthroughPage2ViewController *)vc;
        page2.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage3"];
        LoginCompletedWalkthroughPage3ViewController *page3 = (LoginCompletedWalkthroughPage3ViewController *)vc;
        page3.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage3ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage4"];
        LoginCompletedWalkthroughPage4ViewController *page4 = (LoginCompletedWalkthroughPage4ViewController *)vc;
        page4.heightToUseForCentering = _heightToUseForCentering;
    }
    
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *vc;
    
    if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage2ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage1"];
        LoginCompletedWalkthroughPage1ViewController *page1 = (LoginCompletedWalkthroughPage1ViewController *)vc;
        page1.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage3ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage2"];
        LoginCompletedWalkthroughPage2ViewController *page2 = (LoginCompletedWalkthroughPage2ViewController *)vc;
        page2.heightToUseForCentering = _heightToUseForCentering;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage4ViewController class]]) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompletedPage3"];
        LoginCompletedWalkthroughPage3ViewController *page3 = (LoginCompletedWalkthroughPage3ViewController *)vc;
        page3.heightToUseForCentering = _heightToUseForCentering;
    }
    
    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    [self setPageNumberForViewController:[pendingViewControllers objectAtIndex:0]];
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

- (void)showLoginSuccess
{
    NewWPWalkthroughOverlayView *grayOverlay = [[NewWPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    grayOverlay.overlayTitle = NSLocalizedString(@"Success!", @"NUX Second Walkthrough Success Overlay Title");
    grayOverlay.overlayDescription = NSLocalizedString(@"You have successfully signed into your WordPress account!", @"NUX Second Walkthrough Success Overlay Description");
    grayOverlay.overlayMode = NewWPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    grayOverlay.footerDescription = [NSLocalizedString(@"tap to continue", nil) uppercaseString];
    grayOverlay.icon = NewWPWalkthroughGrayOverlayViewBlueCheckmarkIcon;
    grayOverlay.hideBackgroundView = YES;
    grayOverlay.singleTapCompletionBlock = ^(NewWPWalkthroughOverlayView * overlayView){
        if (!self.showsExtraWalkthroughPages) {
            [self dismiss];
        } else {
            [overlayView dismiss];
            [self addGestureRecognizers];
        }
    };
    [self.view addSubview:grayOverlay];
}

- (void)dismiss
{
    if (!_isDismissing) {
        _isDismissing = YES;
        self.parentViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        [[WordPressAppDelegate sharedWordPressApplicationDelegate].panelNavigationController teaseSidebar];
    }
}

- (void)addGestureRecognizers
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBackground:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBottomPanel:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.bottomPanel addGestureRecognizer:gestureRecognizer];
}

- (void)clickedBackground:(UITapGestureRecognizer *)gestureRecognizer
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage];
    [self dismiss];
}

- (void)clickedBottomPanel:(UITapGestureRecognizer *)gestureRecognizer
{
    [self clickedSkipToApp:nil];
}

- (void)clickedSkipToApp:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.pageControl.currentPage == 3) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage];
    } else {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingApp];
    }
    [self dismiss];
}

- (void)setPageNumberForViewController:(UIView *)viewController
{
    if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage1ViewController class]]) {
        self.pageControl.currentPage = 0;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage2ViewController class]]) {
        self.pageControl.currentPage = 1;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage3ViewController class]]) {
        self.pageControl.currentPage = 2;
    } else if ([viewController isKindOfClass:[LoginCompletedWalkthroughPage4ViewController class]]) {
        self.pageControl.currentPage = 3;
    }
}

@end
