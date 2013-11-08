//
//  LoginCompletedWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LoginCompletedWalkthroughViewController.h"
#import "UIView+FormSheetHelpers.h"
#import "AboutViewController.h"
#import "WPWalkthroughOverlayView.h"
#import "WordPressAppDelegate.h"
#import "WPNUXUtility.h"

@interface LoginCompletedWalkthroughViewController ()<UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    UIView *_mainView;
    UILabel *_skipToApp;
    
    // Page 1
    UIImageView *_page1Icon;
    UILabel *_page1Title;
    UILabel *_page1Description;

    UIView *_bottomPanelLine;
    UIView *_bottomPanel;
    UIPageControl *_pageControl;
    
    // Page 2
    UIImageView *_page2Icon;
    UILabel *_page2Title;
    UILabel *_page2Description;
    
    // Page 3
    UIImageView *_page3Icon;
    UILabel *_page3Title;
    UILabel *_page3Description;
    
    // Page 4
    UIImageView *_page4Icon;
    UILabel *_page4Title;
    UILabel *_page4TapToContinue;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    CGFloat _currentPage;
    CGFloat _bottomPanelOriginalX;
    CGFloat _skipToAppOriginalX;
    CGFloat _pageControlOriginalX;
    CGFloat _heightFromPageControlToBottom;

    BOOL _savedOriginalPositionsOfStickyControls;
    BOOL _isDismissing;
    BOOL _viewedPage2;
    BOOL _viewedPage3;
    BOOL _viewedPage4;
}

@end

@implementation LoginCompletedWalkthroughViewController

NSUInteger const LoginCompletedWalkthroughStandardOffset = 16;
CGFloat const LoginCompletedWalkthroughIconVerticalOffset = 85;
CGFloat const LoginCompletedWalkthroughMaxTextWidth = 289.0;
CGFloat const LoginCompletedWalkthroughBottomBackgroundHeight = 64.0;
CGFloat const LoginCompeltedWalkthroughSwipeToContinueTopOffset = 14.0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
    
    self.view.backgroundColor = [WPNUXUtility backgroundColor];

    [self addBackgroundTexture];
    [self addScrollview];
    [self initializePage1];
    [self initializePage2];
    [self initializePage3];
    [self initializePage4];
    [self showLoginSuccess];
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughOpened];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self layoutScrollview];
    [self savePositionsOfStickyControls];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_viewWidth) + 1;
    [self flagPageViewed:pageViewed];
    [self moveStickyControlsForContentOffset:scrollView.contentOffset];
}


#pragma mark - Private Methods

- (void)moveStickyControlsForContentOffset:(CGPoint)contentOffset
{
    CGRect bottomPanelFrame = _bottomPanel.frame;
    bottomPanelFrame.origin.x = _bottomPanelOriginalX + contentOffset.x;
    _bottomPanel.frame = bottomPanelFrame;
    
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.origin.x = _pageControlOriginalX + contentOffset.x;
    _pageControl.frame = pageControlFrame;
    
    CGRect skipToAppFrame = _skipToApp.frame;
    skipToAppFrame.origin.x = _skipToAppOriginalX + contentOffset.x;
    _skipToApp.frame = skipToAppFrame;
}

- (void)savePositionsOfStickyControls
{
    if (!_savedOriginalPositionsOfStickyControls) {
        _savedOriginalPositionsOfStickyControls = YES;
        _skipToAppOriginalX = CGRectGetMinX(_skipToApp.frame);
        _bottomPanelOriginalX = CGRectGetMinX(_bottomPanel.frame);
        _pageControlOriginalX = CGRectGetMinX(_pageControl.frame);
    }
}

- (void)showLoginSuccess
{
    WPWalkthroughOverlayView *grayOverlay = [[WPWalkthroughOverlayView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, _viewHeight)];
    grayOverlay.overlayTitle = NSLocalizedString(@"Success!", @"NUX Second Walkthrough Success Overlay Title");
    grayOverlay.overlayDescription = NSLocalizedString(@"You have successfully signed into your WordPress account!", @"NUX Second Walkthrough Success Overlay Description");
    grayOverlay.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    grayOverlay.footerDescription = [NSLocalizedString(@"tap to continue", nil) uppercaseString];
    grayOverlay.icon = WPWalkthroughGrayOverlayViewBlueCheckmarkIcon;
    grayOverlay.hideBackgroundView = YES;
    grayOverlay.singleTapCompletionBlock = ^(WPWalkthroughOverlayView * overlayView){
        if (!self.showsExtraWalkthroughPages) {
            [self dismiss];
        } else {
            [overlayView dismiss];
        }
    };
    [self.view addSubview:grayOverlay];
}

- (void)addBackgroundTexture
{
    _mainView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_mainView];
    _mainView.userInteractionEnabled = NO;
}

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _viewWidth * 4;
    _scrollView.frame = self.view.bounds;
    _scrollView.contentSize = scrollViewSize;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    _scrollView.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedScrollView:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;
    [_scrollView addGestureRecognizer:gestureRecognizer];
}

- (void)layoutScrollview
{
    _scrollView.frame = self.view.bounds;
}

- (void)initializePage1
{
    [self addPage1Controls];
    [self layoutPage1Controls];
}

- (void)addPage1Controls
{
    
    // Add Icon
    if (_page1Icon == nil) {
        _page1Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-stats"]];
        [_scrollView addSubview:_page1Icon];
    }

    // Add Title
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.backgroundColor = [UIColor clearColor];
        _page1Title.textAlignment = NSTextAlignmentCenter;
        _page1Title.numberOfLines = 0;
        _page1Title.lineBreakMode = NSLineBreakByWordWrapping;
        _page1Title.font = [WPNUXUtility titleFont];
        _page1Title.text = NSLocalizedString(@"Track your site's statistics", @"NUX Second Walkthrough Page 1 Title");
        _page1Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page1Title];
    }
    
    // Add Description
    if (_page1Description == nil) {
        _page1Description = [[UILabel alloc] init];
        _page1Description.backgroundColor = [UIColor clearColor];
        _page1Description.textAlignment = NSTextAlignmentCenter;
        _page1Description.numberOfLines = 0;
        _page1Description.lineBreakMode = NSLineBreakByWordWrapping;
        _page1Description.font = [WPNUXUtility descriptionTextFont];
        _page1Description.text = NSLocalizedString(@"Learn what your visitors respond to so you can give them more of it", @"NUX Second Walkthrough Page 1 Description");
        _page1Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page1Description];
    }
    
    // Bottom Panel
    if (_bottomPanel == nil) {
        _bottomPanel = [[UIView alloc] init];
        _bottomPanel.backgroundColor = [WPNUXUtility bottomPanelBackgroundColor];
        [_scrollView addSubview:_bottomPanel];
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBottomPanel:)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_bottomPanel addGestureRecognizer:gestureRecognizer];
    }
    
    // Bottom Panel "Black" Line
    if (_bottomPanelLine == nil) {
        _bottomPanelLine = [[UIView alloc] init];
        _bottomPanelLine.backgroundColor = [WPNUXUtility bottomPanelLineColor];
        [_scrollView addSubview:_bottomPanelLine];
    }
    
    // Add Page Control
    if (_pageControl == nil) {
        // The page control adds a bunch of extra space for padding that messes with our calculations.
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.numberOfPages = 4;
        [_pageControl sizeToFit];
        [WPNUXUtility configurePageControlTintColors:_pageControl];
        [_scrollView addSubview:_pageControl];
    }
    
    // Add Skip to App Button
    if (_skipToApp == nil) {
        _skipToApp = [[UILabel alloc] init];
        _skipToApp.numberOfLines = 2;
        _skipToApp.lineBreakMode = NSLineBreakByWordWrapping;
        _skipToApp.textAlignment = NSTextAlignmentCenter;
        _skipToApp.backgroundColor = [UIColor clearColor];
        _skipToApp.textColor = [UIColor whiteColor];
        _skipToApp.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _skipToApp.text = NSLocalizedString(@"Tap to start using WordPress", @"NUX Second Walkthrough Bottom Skip Label");
        _skipToApp.shadowColor = [UIColor blackColor];
        [_skipToApp sizeToFit];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedSkipToApp:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        _skipToApp.userInteractionEnabled = YES;
        [_skipToApp addGestureRecognizer:tapGestureRecognizer];
        [_scrollView addSubview:_skipToApp];
    }
}

- (void)layoutPage1Controls
{
    CGFloat x,y;
    
    // Layout Stats Icon
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
 
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Description
    CGSize labelSize = [_page1Description.text sizeWithFont:_page1Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Title.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Panel
    x = 0;
    x = [self adjustX:x forPage:1];
    y = _viewHeight - LoginCompletedWalkthroughBottomBackgroundHeight;
    _bottomPanel.frame = CGRectMake(x, y, _viewWidth, LoginCompletedWalkthroughBottomBackgroundHeight);
        
    // Layout Bottom Panel Line
    x = 0;
    y = CGRectGetMinY(_bottomPanel.frame);
    _bottomPanelLine.frame = CGRectMake(x, y, _viewWidth, 1);
    
    // Layout Page Control
    CGFloat verticalSpaceForPageControl = 15;
    CGSize pageControlSize = [_pageControl sizeForNumberOfPages:4];
    x = (_viewWidth - CGRectGetWidth(_pageControl.frame))/2.0;
    if (IS_IPAD) {
        // UIPageControl seems to add about half it's size in padding on the iPad
        // TODO : Figure out why this is happening
        x += pageControlSize.width/2.0;
    }
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) - LoginCompletedWalkthroughStandardOffset - CGRectGetHeight(_pageControl.frame) + verticalSpaceForPageControl;
    _pageControl.frame = CGRectIntegral(CGRectMake(x, y, pageControlSize.width, pageControlSize.height));

    // Layout Skip and Start Using App
    CGSize skipToAppLabelSize = [_skipToApp.text sizeWithFont:_skipToApp.font constrainedToSize:CGSizeMake(_viewWidth - 2*LoginCompletedWalkthroughStandardOffset, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - skipToAppLabelSize.width)/2.0;
    y = CGRectGetMinY(_bottomPanel.frame) + (CGRectGetHeight(_bottomPanel.frame) - skipToAppLabelSize.height)/2.0;
    _skipToApp.frame = CGRectIntegral(CGRectMake(x, y, skipToAppLabelSize.width, skipToAppLabelSize.height));
    
    _heightFromPageControlToBottom = _viewHeight - CGRectGetMinY(_pageControl.frame) - CGRectGetHeight(_pageControl.frame);
    NSArray *viewsToCenter = @[_page1Icon, _page1Title, _page1Description];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page1Icon andEndingView:_page1Description forHeight:(_viewHeight-_heightFromPageControlToBottom)];
}

- (void)initializePage2
{
    [self addPage2Controls];
    [self layoutPage2Controls];
}

- (void)addPage2Controls
{
    // Add Icon
    if (_page2Icon == nil) {
        _page2Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-reader"]];
        [_scrollView addSubview:_page2Icon];
    }
    
    // Add Title
    if (_page2Title == nil) {
        _page2Title = [[UILabel alloc] init];
        _page2Title.backgroundColor = [UIColor clearColor];
        _page2Title.textAlignment = NSTextAlignmentCenter;
        _page2Title.numberOfLines = 0;
        _page2Title.lineBreakMode = NSLineBreakByWordWrapping;
        _page2Title.font = [WPNUXUtility titleFont];
        _page2Title.text = NSLocalizedString(@"Explore the WordPress.com Reader", @"NUX Second Walkthrough Page 2 Title");
        _page2Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page2Title];
    }
    
    // Add Description
    if (_page2Description == nil) {
        _page2Description = [[UILabel alloc] init];
        _page2Description.backgroundColor = [UIColor clearColor];
        _page2Description.textAlignment = NSTextAlignmentCenter;
        _page2Description.numberOfLines = 0;
        _page2Description.lineBreakMode = NSLineBreakByWordWrapping;
        _page2Description.font = [WPNUXUtility descriptionTextFont];
        _page2Description.text = NSLocalizedString(@"Browse the entire WordPress ecosystem. Thousands of topics at the flick of a finger.", @"NUX Second Walkthrough Page 2 Description");
        _page2Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page2Description];
    }
}

- (void)layoutPage2Controls
{
    CGFloat x,y;

    x = (_viewWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));

    // Layout Title
    CGSize titleSize = [_page2Title.text sizeWithFont:_page2Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Description
    CGSize labelSize = [_page2Description.text sizeWithFont:_page2Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Title.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));

    NSArray *viewsToCenter = @[_page2Icon, _page2Title, _page2Description];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page2Icon andEndingView:_page2Description forHeight:(_viewHeight-_heightFromPageControlToBottom)];
}

- (void)initializePage3
{
    [self addPage3Controls];
    [self layoutPage3Controls];
}

- (void)addPage3Controls
{
    // Add Icon
    if (_page3Icon == nil) {
        _page3Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-notifications"]];
        [_scrollView addSubview:_page3Icon];
    }
    
    // Add Title
    if (_page3Title == nil) {
        _page3Title = [[UILabel alloc] init];
        _page3Title.backgroundColor = [UIColor clearColor];
        _page3Title.textAlignment = NSTextAlignmentCenter;
        _page3Title.numberOfLines = 0;
        _page3Title.lineBreakMode = NSLineBreakByWordWrapping;
        _page3Title.font = [WPNUXUtility titleFont];
        _page3Title.text = NSLocalizedString(@"Get real-time comment notifications", @"NUX Second Walkthrough Page 3 Title");
        _page3Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page3Title];
    }
    
    // Add Description
    if (_page3Description == nil) {
        _page3Description = [[UILabel alloc] init];
        _page3Description.backgroundColor = [UIColor clearColor];
        _page3Description.textAlignment = NSTextAlignmentCenter;
        _page3Description.numberOfLines = 0;
        _page3Description.lineBreakMode = NSLineBreakByWordWrapping;
        _page3Description.font = [WPNUXUtility descriptionTextFont];
        _page3Description.text = NSLocalizedString(@"Keep the conversation going with notifications on the go. No need for a desktop to nurture the dialogue.", @"NUX Second Walkthrough Page 3 Description");
        _page3Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page3Description];
    }
}

- (void)layoutPage3Controls
{
    CGFloat x,y;
    
    x = (_viewWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3Icon.frame), CGRectGetHeight(_page3Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page3Title.text sizeWithFont:_page3Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page3Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Description
    CGSize labelSize = [_page3Description.text sizeWithFont:_page3Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Title.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page3Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    NSArray *viewsToCenter = @[_page3Icon, _page3Title, _page3Description];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page3Icon andEndingView:_page3Description forHeight:(_viewHeight-_heightFromPageControlToBottom)];
}

- (void)initializePage4
{
    [self addPage4Controls];
    [self layoutPage4Controls];
}

- (void)addPage4Controls
{
    // Add Icon
    if (_page4Icon == nil) {
        _page4Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-check"]];
        [_scrollView addSubview:_page4Icon];
    }
    
    // Add Title
    if (_page4Title == nil) {
        _page4Title = [[UILabel alloc] init];
        _page4Title.backgroundColor = [UIColor clearColor];
        _page4Title.textAlignment = NSTextAlignmentCenter;
        _page4Title.numberOfLines = 0;
        _page4Title.lineBreakMode = NSLineBreakByWordWrapping;
        _page4Title.font = [WPNUXUtility titleFont];
        _page4Title.text = NSLocalizedString(@"Get started!", @"NUX Second Walkthrough Page 4 Title");
        _page4Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page4Title];
    }
    
    // Add "SWIPE TO CONTINUE"
    if (_page4TapToContinue == nil) {
        _page4TapToContinue = [[UILabel alloc] init];
        [_page4TapToContinue setTextColor:[WPNUXUtility swipeToContinueTextColor]];
        _page4TapToContinue.backgroundColor = [UIColor clearColor];
        _page4TapToContinue.textAlignment = NSTextAlignmentCenter;
        _page4TapToContinue.numberOfLines = 1;
        _page4TapToContinue.font = [WPNUXUtility swipeToContinueFont];
        _page4TapToContinue.text = [NSLocalizedString(@"tap to continue", nil) uppercaseString];
        [_page4TapToContinue sizeToFit];
        [_scrollView addSubview:_page4TapToContinue];
    }
}

- (void)layoutPage4Controls
{
    CGFloat x,y;
    CGFloat currentPage=4;
    
    x = (_viewWidth - CGRectGetWidth(_page4Icon.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page4Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page4Icon.frame), CGRectGetHeight(_page4Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page4Title.text sizeWithFont:_page4Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page4Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page4Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Swipe to Continue Label
    CGFloat verticalSpaceForPageControl = 15;
    x = (_viewWidth - CGRectGetWidth(_page4TapToContinue.frame))/2.0;
    x = [self adjustX:x forPage:4];
    y = CGRectGetMinY(_pageControl.frame) - LoginCompeltedWalkthroughSwipeToContinueTopOffset - CGRectGetHeight(_page4TapToContinue.frame) + verticalSpaceForPageControl;
    _page4TapToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page4TapToContinue.frame), CGRectGetHeight(_page4TapToContinue.frame)));
    
    NSArray *viewsToCenter = @[_page4Icon, _page4Title];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page4Title andEndingView:_page4Title forHeight:(_viewHeight-_heightFromPageControlToBottom)];
}

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page
{
    return (x + _viewWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)pageViewed
{
    _pageControl.currentPage = pageViewed - 1;
    _currentPage = pageViewed;
    
    // We do this so we don't keep flagging events if the user goes back and forth on pages
    if (pageViewed == 2 && !_viewedPage2) {
        _viewedPage2 = YES;
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughViewedPage2];
    } else if (pageViewed == 3 && !_viewedPage3) {
        _viewedPage3 = YES;
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughViewedPage3];
    } else if (pageViewed == 4 && !_viewedPage4) {
        _viewedPage4 = YES;
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughViewedPage4];
    }
}

- (void)clickedSkipToApp:(UITapGestureRecognizer *)gestureRecognizer
{
    if (_currentPage == 4) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage];
    } else {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingApp];
    }
    [self dismiss];
}

- (void)clickedBottomPanel:(UITapGestureRecognizer *)gestureRecognizer
{
    [self clickedSkipToApp:nil];
}

- (void)clickedScrollView:(UITapGestureRecognizer *)gestureRecognizer
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage];
    [self dismiss];
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

@end
