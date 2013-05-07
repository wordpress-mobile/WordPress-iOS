//
//  LoginCompletedWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "LoginCompletedWalkthroughViewController.h"
#import "UIView+FormSheetHelpers.h"
#import "AboutViewController.h"
#import "WPWalkthroughButton.h"
#import "WPWalkthroughLineSeparatorView.h"
#import "WPWalkthroughGrayOverlayView.h"

@interface LoginCompletedWalkthroughViewController ()<UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    UIButton *_infoButton;
    UILabel *_skipToApp;
    
    // Page 1
    UIImageView *_page1Icon;
    UILabel *_page1Title;
    UILabel *_page1Description;
    UILabel *_page1SwipeToContinue;
    WPWalkthroughLineSeparatorView *_page1TopSeparator;
    WPWalkthroughLineSeparatorView *_page1BottomSeparator;
    UIView *_bottomPanel;
    UIPageControl *_pageControl;
    
    // Page 2
    UILabel *_page2Icon;
    UILabel *_page2Title;
    UILabel *_page2Description;
    WPWalkthroughLineSeparatorView *_page2TopSeparator;
    WPWalkthroughLineSeparatorView *_page2BottomSeparator;
    
    // Page 3
    UILabel *_page3Icon;
    UILabel *_page3Title;
    UILabel *_page3Description;
    WPWalkthroughLineSeparatorView *_page3TopSeparator;
    WPWalkthroughLineSeparatorView *_page3BottomSeparator;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    CGFloat _bottomPanelOriginalX;
    CGFloat _skipToAppOriginalX;
    CGFloat _pageControlOriginalX;

    BOOL _savedOriginalPositionsOfStickyControls;
    BOOL _isDismissing;
    
    UIColor *_textShadowColor;
}

@end

@implementation LoginCompletedWalkthroughViewController

NSUInteger const LoginCompletedWalkthroughStandardOffset = 16;
CGFloat const LoginCompletedWalkthroughIconVerticalOffset = 85;
CGFloat const LoginCompletedWalkthroughMaxTextWidth = 289.0;
CGFloat const LoginCompletedWalkthroughBottomBackgroundHeight = 64.0;


- (id)init
{
    self = [super init];
    if (self) {
        _textShadowColor = [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getInitialWidthAndHeight];
    self.view.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
    [self addScrollview];
    [self initializePage1];
    [self initializePage2];
    [self initializePage3];
    [self addLoginSuccessView];
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
    [self layoutPage1Controls];
    [self layoutPage2Controls];
    [self layoutPage3Controls];
    [self savePositionsOfStickyControls];
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // TODO: Clean up this method as it's confusing
    if (scrollView.contentOffset.x < 0) {
        CGRect bottomPanelFrame = _bottomPanel.frame;
        bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
        _bottomPanel.frame = bottomPanelFrame;
        
        CGRect skipToAppFrame = _skipToApp.frame;
        skipToAppFrame.origin.x = _skipToAppOriginalX + scrollView.contentOffset.x;
        _skipToApp.frame = skipToAppFrame;
        
        return;
    }
    
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_viewWidth) + 1;
    
    // We only want the sign in, create account and help buttons to drag along until we hit the sign in screen
    if (pageViewed < 4) {
        CGRect bottomPanelFrame = _bottomPanel.frame;
        bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
        _bottomPanel.frame = bottomPanelFrame;
        
        CGRect skipToAppFrame = _skipToApp.frame;
        skipToAppFrame.origin.x = _skipToAppOriginalX + scrollView.contentOffset.x;
        _skipToApp.frame = skipToAppFrame;

        CGRect pageControlFrame = _pageControl.frame;
        pageControlFrame.origin.x = _pageControlOriginalX + scrollView.contentOffset.x;
        _pageControl.frame = pageControlFrame;
    }
    
    if (pageViewed >= 4) {
        [self dismiss];
    }
    
    CGRect bottomPanelFrame = _bottomPanel.frame;
    bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
    _bottomPanel.frame = bottomPanelFrame;
    
    [self flagPageViewed:pageViewed];
}


#pragma mark - Private Methods

- (void)getInitialWidthAndHeight
{
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
}

- (void)savePositionsOfStickyControls
{
    if (!_savedOriginalPositionsOfStickyControls) {
        _savedOriginalPositionsOfStickyControls = true;
        _skipToAppOriginalX = CGRectGetMinX(_skipToApp.frame);
        _bottomPanelOriginalX = CGRectGetMinX(_bottomPanel.frame);
        _pageControlOriginalX = CGRectGetMinX(_pageControl.frame);
    }
}

- (void)addLoginSuccessView
{
    WPWalkthroughGrayOverlayView *grayOverlay = [[WPWalkthroughGrayOverlayView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, _viewHeight)];
    grayOverlay.overlayTitle = @"Success!";
    grayOverlay.overlayDescription = @"You have successfully signed into your WordPress account!";
    grayOverlay.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    grayOverlay.footerDescription = @"TAP TO CONTINUE";
    grayOverlay.icon = WPWalkthroughGrayOverlayViewBlueCheckmarkIcon;
    grayOverlay.hideBackgroundView = YES;
    grayOverlay.singleTapCompletionBlock = ^(WPWalkthroughGrayOverlayView * overlayView){
        [overlayView dismiss];
        if (!self.showsExtraWalkthroughPages) {
            [self dismiss];
        }
    };
    [self.view addSubview:grayOverlay];
}

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _viewWidth * 4;
    _scrollView.frame = self.view.bounds;
    _scrollView.contentSize = scrollViewSize;
    _scrollView.pagingEnabled = true;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    _scrollView.delegate = self;
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
    // Add Info Button
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    if (_infoButton == nil) {
        _infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_infoButton setImage:infoButtonImage forState:UIControlStateNormal];
        _infoButton.frame = CGRectMake(LoginCompletedWalkthroughStandardOffset, LoginCompletedWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [_infoButton addTarget:self action:@selector(clickedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_infoButton];
    }
    
    if (_page1Icon == nil) {
        _page1Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nuxStatsIcon"]];
        [_scrollView addSubview:_page1Icon];
    }

    // Add Title
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.backgroundColor = [UIColor clearColor];
        _page1Title.textAlignment = UITextAlignmentCenter;
        _page1Title.numberOfLines = 0;
        _page1Title.lineBreakMode = UILineBreakModeWordWrap;
        _page1Title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
        _page1Title.text = @"Track your site's statistics";
        _page1Title.shadowColor = _textShadowColor;
        _page1Title.shadowOffset = CGSizeMake(1.0, 1.0);
        _page1Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page1Title];
    }
    
    // Add Top Separator
    if (_page1TopSeparator == nil) {
        _page1TopSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page1TopSeparator];
    }
    
    // Add Description
    if (_page1Description == nil) {
        _page1Description = [[UILabel alloc] init];
        _page1Description.backgroundColor = [UIColor clearColor];
        _page1Description.textAlignment = UITextAlignmentCenter;
        _page1Description.numberOfLines = 0;
        _page1Description.lineBreakMode = UILineBreakModeWordWrap;
        _page1Description.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _page1Description.text = @"Learn what your readers respond to so you can give them more of it";
        _page1Description.shadowColor = _textShadowColor;
        _page1Description.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page1Description];
    }
    
    // Add Bottom Separator
    if (_page1BottomSeparator == nil) {
        _page1BottomSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page1BottomSeparator];
    }
    
    // Bottom Portion
    if (_bottomPanel == nil) {
        _bottomPanel = [[UIView alloc] init];
        _bottomPanel.backgroundColor = [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:1.0];
        [_scrollView addSubview:_bottomPanel];
    }
    
    // Add Page Control
    if (_pageControl == nil) {
        // The page control adds a bunch of extra space for padding that messes with our calculations.
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.numberOfPages = 4;
        [_pageControl sizeToFit];
        // This only works on iOS6+
        if ([_pageControl respondsToSelector:@selector(pageIndicatorTintColor)]) {
            UIColor *currentPageTintColor = [UIColor colorWithRed:46.0/255.0 green:162.0/255.0 blue:204.0/255.0 alpha:1.0];
            UIColor *pageIndicatorTintColor = [UIColor colorWithRed:38.0/255.0 green:151.0/255.0 blue:197.0/255.0 alpha:1.0];
            _pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
            _pageControl.currentPageIndicatorTintColor = currentPageTintColor;
        }
        [_scrollView addSubview:_pageControl];
    }
    
    // Add "SWIPE TO CONTINUE"
    if (_page1SwipeToContinue == nil) {
        _page1SwipeToContinue = [[UILabel alloc] init];
        _page1SwipeToContinue.backgroundColor = [UIColor clearColor];
        _page1SwipeToContinue.textAlignment = UITextAlignmentCenter;
        _page1SwipeToContinue.numberOfLines = 1;
        _page1SwipeToContinue.font = [UIFont fontWithName:@"OpenSans" size:10.0];
        _page1SwipeToContinue.text = @"SWIPE TO CONTINUE";
        _page1SwipeToContinue.shadowColor = _textShadowColor;
        _page1SwipeToContinue.textColor = [UIColor colorWithRed:86.0/255.0 green:169.0/255.0 blue:206.0/255.0 alpha:1.0];
        [_page1SwipeToContinue sizeToFit];
        [_scrollView addSubview:_page1SwipeToContinue];
    }
    
    // Add Skip to App Button
    if (_skipToApp == nil) {
        _skipToApp = [[UILabel alloc] init];
        _skipToApp.backgroundColor = [UIColor clearColor];
        _skipToApp.textColor = [UIColor whiteColor];
        _skipToApp.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _skipToApp.text = @"Skip and start using WordPress";
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
    
    // Layout Info Button
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    _infoButton.frame = CGRectMake(LoginCompletedWalkthroughStandardOffset, LoginCompletedWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);

    // Layout Stats Icon
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
 
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Icon.frame) + LoginCompletedWalkthroughStandardOffset;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Title.frame) + 3 * LoginCompletedWalkthroughStandardOffset;
    _page1TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page1Description.text sizeWithFont:_page1Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1TopSeparator.frame) + LoginCompletedWalkthroughStandardOffset;
    _page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));

    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Description.frame) + LoginCompletedWalkthroughStandardOffset;
    _page1BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Bottom Panel
    x = 0;
    x = [self adjustX:x forPage:1];
    y = _viewHeight - LoginCompletedWalkthroughBottomBackgroundHeight;
    _bottomPanel.frame = CGRectMake(x, y, _viewWidth, LoginCompletedWalkthroughBottomBackgroundHeight);
    
    // Layout Page Control
    CGFloat verticalSpaceForPageControl = 15;
    x = (_viewWidth - CGRectGetWidth(_pageControl.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) - LoginCompletedWalkthroughStandardOffset - CGRectGetHeight(_pageControl.frame) + verticalSpaceForPageControl;
    _pageControl.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_pageControl.frame), CGRectGetHeight(_pageControl.frame)));

    // Layout Swipe to Continue Label
    x = (_viewWidth - CGRectGetWidth(_page1SwipeToContinue.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_pageControl.frame) - 5 - CGRectGetHeight(_page1SwipeToContinue.frame) + verticalSpaceForPageControl;
    _page1SwipeToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1SwipeToContinue.frame), CGRectGetHeight(_page1SwipeToContinue.frame)));

    // Layout Skip and Start Using App
    x = (_viewWidth - CGRectGetWidth(_skipToApp.frame))/2.0;
    y = CGRectGetMinY(_bottomPanel.frame) + (CGRectGetHeight(_bottomPanel.frame)-CGRectGetHeight(_skipToApp.frame))/2.0;
    _skipToApp.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_skipToApp.frame), CGRectGetHeight(_skipToApp.frame)));
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
        _page2Icon = [[UILabel alloc] init];
        _page2Icon.backgroundColor = [UIColor clearColor];
        _page2Icon.font = [UIFont fontWithName:@"Genericons-Regular" size:70];
        _page2Icon.text = @""; // RSS Logo
        _page2Icon.shadowColor = _textShadowColor;
        _page2Icon.textColor = [UIColor whiteColor];
        [_page2Icon sizeToFit];
        [_scrollView addSubview:_page2Icon];
    }
    
    // Add Title
    if (_page2Title == nil) {
        _page2Title = [[UILabel alloc] init];
        _page2Title.backgroundColor = [UIColor clearColor];
        _page2Title.textAlignment = UITextAlignmentCenter;
        _page2Title.numberOfLines = 0;
        _page2Title.lineBreakMode = UILineBreakModeWordWrap;
        _page2Title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
        _page2Title.text = @"The WordPress Reader";
        _page2Title.shadowColor = _textShadowColor;
        _page2Title.shadowOffset = CGSizeMake(1, 1);
        _page2Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page2Title];
    }
    
    // Add Top Separator
    if (_page2TopSeparator == nil) {
        _page2TopSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page2TopSeparator];
    }
    
    // Add Description
    if (_page2Description == nil) {
        _page2Description = [[UILabel alloc] init];
        _page2Description.backgroundColor = [UIColor clearColor];
        _page2Description.textAlignment = UITextAlignmentCenter;
        _page2Description.numberOfLines = 0;
        _page2Description.lineBreakMode = UILineBreakModeWordWrap;
        _page2Description.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _page2Description.text = @"Browse the entire WordPress ecosystem. If you can think it, someone is writing it.";
        _page2Description.shadowColor = _textShadowColor;
        _page2Description.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page2Description];
    }
    
    // Add Bottom Separator
    if (_page2BottomSeparator == nil) {
        _page2BottomSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page2BottomSeparator];
    }
}

- (void)layoutPage2Controls
{
    CGFloat x,y;

    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
    CGFloat extraIconSpaceOnTop = 21;
    CGFloat extraIconSpaceOnBottom = 40;
    x = (_viewWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = LoginCompletedWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));

    // Layout Title
    CGSize titleSize = [_page2Title.text sizeWithFont:_page2Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Icon.frame) + LoginCompletedWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Title.frame) + LoginCompletedWalkthroughStandardOffset;
    _page2TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page2Description.text sizeWithFont:_page2Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2TopSeparator.frame) + LoginCompletedWalkthroughStandardOffset;
    _page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Description.frame) + LoginCompletedWalkthroughStandardOffset;
    _page2BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
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
        _page3Icon = [[UILabel alloc] init];
        _page3Icon.backgroundColor = [UIColor clearColor];
        _page3Icon.font = [UIFont fontWithName:@"Genericons-Regular" size:90];
        _page3Icon.text = @""; // Comment Logo
        _page3Icon.shadowColor = _textShadowColor;
        _page3Icon.textColor = [UIColor whiteColor];
        [_page3Icon sizeToFit];
        [_scrollView addSubview:_page3Icon];
    }
    
    // Add Title
    if (_page3Title == nil) {
        _page3Title = [[UILabel alloc] init];
        _page3Title.backgroundColor = [UIColor clearColor];
        _page3Title.textAlignment = UITextAlignmentCenter;
        _page3Title.numberOfLines = 0;
        _page3Title.lineBreakMode = UILineBreakModeWordWrap;
        _page3Title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
        _page3Title.text = @"Get notified of new Comments & Likes";
        _page3Title.shadowColor = _textShadowColor;
        _page3Title.shadowOffset = CGSizeMake(1, 1);
        _page3Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page3Title];
    }
    
    // Add Top Separator
    if (_page3TopSeparator == nil) {
        _page3TopSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page3TopSeparator];
    }
    
    // Add Description
    if (_page3Description == nil) {
        _page3Description = [[UILabel alloc] init];
        _page3Description.backgroundColor = [UIColor clearColor];
        _page3Description.textAlignment = UITextAlignmentCenter;
        _page3Description.numberOfLines = 0;
        _page3Description.lineBreakMode = UILineBreakModeWordWrap;
        _page3Description.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _page3Description.text = @"Keep the conversation going with notifications on the go. No need for a desktop to nurture the dialogue.";
        _page3Description.shadowColor = _textShadowColor;
        _page3Description.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page3Description];
    }
    
    // Add Bottom Separator
    if (_page3BottomSeparator == nil) {
        _page3BottomSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page3BottomSeparator];
    }
}

- (void)layoutPage3Controls
{
    CGFloat x,y;
    
    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
    CGFloat extraIconSpaceOnTop = 45;
    CGFloat extraIconSpaceOnBottom = 59;
    x = (_viewWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = LoginCompletedWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3Icon.frame), CGRectGetHeight(_page3Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page3Title.text sizeWithFont:_page3Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Icon.frame) + LoginCompletedWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page3Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Title.frame) + LoginCompletedWalkthroughStandardOffset;
    _page3TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page3Description.text sizeWithFont:_page3Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3TopSeparator.frame) + LoginCompletedWalkthroughStandardOffset;
    _page3Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Description.frame) + LoginCompletedWalkthroughStandardOffset;
    _page3BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
}

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page
{
    return (x + _viewWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)pageViewed
{
    _pageControl.currentPage = pageViewed - 1;
}

- (void)clickedInfoButton:(id)sender
{
    AboutViewController *aboutViewController = [[AboutViewController alloc] init];
	aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentModalViewController:nc animated:YES];
	[self.navigationController setNavigationBarHidden:YES];
}

- (void)clickedSkipToApp:(UITapGestureRecognizer *)gestureRecognizer
{
    [self dismiss];
}

- (void)dismiss
{
    if (!_isDismissing) {
        _isDismissing = true;
        self.parentViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

@end
