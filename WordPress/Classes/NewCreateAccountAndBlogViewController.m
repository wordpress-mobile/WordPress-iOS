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

@interface NewCreateAccountAndBlogViewController () {
    UIPageViewController *_pageViewController;
    CreateAccountAndBlogPage1ViewController *_page1ViewController;
    CreateAccountAndBlogPage2ViewController *_page2ViewController;
    CreateAccountAndBlogPage3ViewController *_page3ViewController;
    NSUInteger _currentPage;
}

@property (nonatomic, strong) IBOutlet WPNUXBackButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *helpButton;

@end

@implementation NewCreateAccountAndBlogViewController

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

    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [_pageViewController setViewControllers:@[[self page1ViewController]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:_pageViewController];
    [[self view] addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self];
    
    [self.view bringSubviewToFront:self.backButton];
    [self.view bringSubviewToFront:self.helpButton];
    
    _currentPage = 1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBAction methods

- (IBAction)clickedCancel:(id)sender
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountClickedCancel];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)moveToPage:(NSUInteger)page
{
    UIPageViewControllerNavigationDirection direction;
    if (page == 1) {
        [_pageViewController setViewControllers:@[[self page1ViewController]] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
    } else if (page == 2) {
        if (_currentPage == 1) {
            direction = UIPageViewControllerNavigationDirectionForward;
        } else {
            direction = UIPageViewControllerNavigationDirectionReverse;
        }
        [_pageViewController setViewControllers:@[[self page2ViewController]] direction:direction animated:YES completion:nil];
    } else if (page == 3) {
        if (_currentPage == 2) {
            direction = UIPageViewControllerNavigationDirectionForward;
        } else {
            direction = UIPageViewControllerNavigationDirectionReverse;
        }
        [_pageViewController setViewControllers:@[[self page3ViewController]] direction:direction animated:YES completion:nil];
    }
    
    _currentPage = page;
}

- (UIViewController *)page1ViewController
{
    if (_page1ViewController == nil) {
        __weak NewCreateAccountAndBlogViewController *weakSelf = self;
        _page1ViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage1"];
        _page1ViewController.containingView = self.view;
        _page1ViewController.onClickedNext = ^{
            [weakSelf moveToPage:2];
        };
        _page1ViewController.onValidatedUserFields = ^(NSString *email, NSString *username, NSString *password) {
            CreateAccountAndBlogPage2ViewController *page2ViewController = (CreateAccountAndBlogPage2ViewController *)[weakSelf page2ViewController];
            [page2ViewController setDefaultSiteAddress:[NSString stringWithFormat:@"%@.wordpress.com", username]];
            
            CreateAccountAndBlogPage3ViewController *page3ViewController = (CreateAccountAndBlogPage3ViewController *)[weakSelf page3ViewController];
            [page3ViewController setEmail:email];
            [page3ViewController setUsername:username];
            [page3ViewController setPassword:password];
        };

    }
    
    return _page1ViewController;
}

- (UIViewController *)page2ViewController
{
    if (_page2ViewController == nil) {
        __weak NewCreateAccountAndBlogViewController *weakSelf = self;
        _page2ViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage2"];
        _page2ViewController.containingView = self.view;
        _page2ViewController.onClickedPrevious = ^{
            [weakSelf moveToPage:1];
        };
        _page2ViewController.onClickedNext = ^{
            [weakSelf moveToPage:3];
        };
        _page2ViewController.onValidatedSiteFields = ^(NSString *siteAddress, NSString *siteTitle, NSDictionary *language) {
            CreateAccountAndBlogPage3ViewController *page3ViewController = (CreateAccountAndBlogPage3ViewController *)[weakSelf page3ViewController];
            [page3ViewController setSiteAddress:siteAddress];
            [page3ViewController setSiteTitle:siteTitle];
            [page3ViewController setLanguage:language];
        };
    }
    
    return _page2ViewController;
}

- (UIViewController *)page3ViewController
{
    if (_page3ViewController == nil) {
        __weak NewCreateAccountAndBlogViewController *weakSelf = self;
        _page3ViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccountPage3"];
        _page3ViewController.onCreatedUser = ^(NSString *username, NSString *password) {
            if (weakSelf.onCreatedUser != nil) {
                weakSelf.onCreatedUser(username, password);
            }
        };
        _page3ViewController.onClickedPrevious = ^{
            [weakSelf moveToPage:2];
        };
        _page3ViewController.onClickedNext = ^{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"DONE" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        };
    }
    return _page3ViewController;
}

@end
