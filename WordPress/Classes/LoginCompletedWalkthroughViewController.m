//
//  LoginCompletedWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/26/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "LoginCompletedWalkthroughViewController.h"

@interface LoginCompletedWalkthroughViewController () <UIScrollViewDelegate> {
    CGFloat _pageWidth;
}

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) IBOutlet UILabel *readerLabel;
@property (nonatomic, strong) IBOutlet UILabel *statsLabel;
@property (nonatomic, strong) IBOutlet UILabel *notificationsLabel;

@property (nonatomic, strong) IBOutlet UILabel *completionLabel;
@property (nonatomic, strong) IBOutlet UIButton *completionButton;

@end

@implementation LoginCompletedWalkthroughViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:28.0/255.0 green:138.0/255.0 blue:192.0/255.0 alpha:1.0];
    
    _pageWidth = CGRectGetWidth(self.view.frame);
    
    NSUInteger numberOfPages;
    if (self.showsExtraWalkthroughPages) {
        [self move:self.readerLabel toPage:1];
        
        [self move:self.statsLabel toPage:2];
        
        [self move:self.notificationsLabel toPage:3];
        
        [self move:self.completionLabel toPage:4];
        [self move:self.completionButton toPage:4];
        
        numberOfPages = 4;
    } else {
        [self move:self.completionLabel toPage:1];
        [self move:self.completionButton toPage:1];
        
        self.pageControl.hidden = YES;
        numberOfPages = 1;
    }
    
    
    CGSize scrollViewSize = self.scrollView.contentSize;
    scrollViewSize.width = _pageWidth * numberOfPages;
    self.scrollView.frame = self.view.frame;
    self.scrollView.contentSize = scrollViewSize;
    self.scrollView.pagingEnabled = true;
    self.scrollView.delegate = self;
    
    self.pageControl.numberOfPages = numberOfPages;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBAction Methods

- (IBAction)clickedDone:(id)sender
{
    [super dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x < 0)
        return;
    
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_pageWidth) + 1;
    [self flagPageViewed:pageViewed];
}

#pragma mark - Private Methods

- (void)move:(UIView *)element toPage:(NSUInteger)page
{
    [element removeFromSuperview];
    [self.scrollView addSubview:element];
    
    CGRect elementFrame = element.frame;
    elementFrame.origin.x += _pageWidth*(page-1);
    element.frame = elementFrame;
}

- (void)flagPageViewed:(NSUInteger)page
{
    self.pageControl.currentPage = page - 1;
}

@end
