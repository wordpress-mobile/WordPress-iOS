//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <WPXMLRPC/WPXMLRPC.h>
#import "UIView+FormSheetHelpers.h"
#import "GeneralWalkthroughViewController.h"
#import "CreateAccountAndBlogViewController.h"
#import "AddUsersBlogsViewController.h"
#import "NewAddUsersBlogViewController.h"
#import "AboutViewController.h"
#import "WPWalkthroughButton.h"
#import "WPWalkthroughLineSeparatorView.h"
#import "WPWalkthroughTextField.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "Blog+Jetpack.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "JetpackSettingsViewController.h"
#import "WPWalkthroughGrayOverlayView.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "ReachabilityUtils.h"
#import "SFHFKeychainUtils.h"

@interface GeneralWalkthroughViewController () <
    UIScrollViewDelegate,
    UITextFieldDelegate> {
    UIScrollView *_scrollView;
    WPWalkthroughButton *_skipToCreateAccount;
    WPWalkthroughButton *_skipToSignIn;
    UIButton *_infoButton;
    
    // Page 1
    UILabel *_page1Icon;
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
    UITextField *_usernameText;
    UITextField *_passwordText;
    UITextField *_siteUrlText;
    WPWalkthroughButton *_signInButton;
    UILabel *_createAccountLabel;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    CGFloat _bottomPanelOriginalX;
    CGFloat _skipToCreateAccountOriginalX;
    CGFloat _skipToSignInOriginalX;
    CGFloat _pageControlOriginalX;
    
    UIColor *_textShadowColor;
        
    BOOL _userIsDotCom;
    BOOL _blogHasJetpack;
    BOOL _savedOriginalPositionsOfStickyControls;
    BOOL _hasViewAppeared;
    NSArray *_blogs;
    Blog *_blog;
}

@end

@implementation GeneralWalkthroughViewController

CGFloat const GeneralWalkthroughIconVerticalOffset = 77;
CGFloat const GeneralWalkthroughStandardOffset = 16;
CGFloat const GeneralWalkthroughBottomBackgroundHeight = 64;
CGFloat const GeneralWalkthroughBottomButtonWidth = 136.0;
CGFloat const GeneralWalkthroughBottomButtonHeight = 32.0;
CGFloat const GeneralWalkthroughKeyboardOffset = 65;
CGFloat const GeneralWalkthroughMaxTextWidth = 289.0;

- (id)init
{
    self = [super init];
    if (self) {
        _textShadowColor = [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _viewWidth = CGRectGetWidth(self.view.bounds);
    _viewHeight = CGRectGetHeight(self.view.bounds);
    
    // We are technically laying out the view twice on this view's initialization, but as we hardcoded the width/height
    // in viewDidLoad to prevent a flicker, we are doing this should the hardcoded dimensions no longer be correct in a
    // future version of iOS. If a future version of iOS results in different dimensions for the form sheet, this will
    // result in this page flickering but at least the layout will ultimately be correct.
    [self layoutScrollview];
    [self layoutPage1Controls];
    [self layoutPage2Controls];
    [self layoutPage3Controls];
    [self savePositionsOfStickyControls];
    
    if (_hasViewAppeared) {
        // This is for the case when the user pulls up another view from the sign in page and returns to this view. When that
        // happens the sticky controls on the bottom won't be in the correct place, so in order to set them up we first
        // 'page' to the second page to make sure that the controls at the bottom are in place should the user page back
        // and then we 'page' to the current content offset in the _scrollView to ensure that the bottom panel is in
        // the correct place
        [self moveStickyControlsForContentOffset:CGPointMake(_viewWidth, 0)];
        [self moveStickyControlsForContentOffset:_scrollView.contentOffset];
    }
    
    _hasViewAppeared = true;    
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

- (void)moveStickyControlsForContentOffset:(CGPoint)contentOffset
{
    // TODO: Redo this method, it's confusing.
    
    if (contentOffset.x < 0) {
        CGRect bottomPanelFrame = _bottomPanel.frame;
        bottomPanelFrame.origin.x = _bottomPanelOriginalX + contentOffset.x;
        _bottomPanel.frame = bottomPanelFrame;
        
        CGRect skipToCreateAccountFrame = _skipToCreateAccount.frame;
        skipToCreateAccountFrame.origin.x = _skipToCreateAccountOriginalX + contentOffset.x;
        _skipToCreateAccount.frame = skipToCreateAccountFrame;
        
        CGRect skipToSignInFrame = _skipToSignIn.frame;
        skipToSignInFrame.origin.x = _skipToSignInOriginalX + contentOffset.x;
        _skipToSignIn.frame = skipToSignInFrame;
        
        return;
    }
    
    NSUInteger pageViewed = ceil(contentOffset.x/_viewWidth) + 1;
    // We only want the sign in, create account and help buttons to drag along until we hit the sign in screen
    if (pageViewed < 3) {
        // If the user is editing the sign in page and then swipes over, dismiss keyboard
        [self.view endEditing:YES];
        
        CGRect skipToCreateAccountFrame = _skipToCreateAccount.frame;
        skipToCreateAccountFrame.origin.x = _skipToCreateAccountOriginalX + contentOffset.x;
        _skipToCreateAccount.frame = skipToCreateAccountFrame;
        
        CGRect skipToSignInFrame = _skipToSignIn.frame;
        skipToSignInFrame.origin.x = _skipToSignInOriginalX + contentOffset.x;
        _skipToSignIn.frame = skipToSignInFrame;
        
        CGRect pageControlFrame = _pageControl.frame;
        pageControlFrame.origin.x = _pageControlOriginalX + contentOffset.x;
        _pageControl.frame = pageControlFrame;
    }
    
    CGRect bottomPanelFrame = _bottomPanel.frame;
    bottomPanelFrame.origin.x = _bottomPanelOriginalX + contentOffset.x;
    _bottomPanel.frame = bottomPanelFrame;
}



#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
    if (textField == _usernameText) {
        [_passwordText becomeFirstResponder];
    } else if (textField == _passwordText) {
        [_siteUrlText becomeFirstResponder];
    } else if (textField == _siteUrlText) {
        if (_signInButton.enabled) {
            [self clickedSignIn:nil];
        }
    }
    
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    _signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == _usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == _passwordText) {
        isPasswordFilled = updatedStringHasContent;
    }
    _signInButton.enabled = isUsernameFilled && isPasswordFilled;
    
    return YES;
}

#pragma mark - Displaying of Error Messages

- (WPWalkthroughGrayOverlayView *)baseLoginErrorOverlayView:(NSString *)message
{
    WPWalkthroughGrayOverlayView *overlayView = [[WPWalkthroughGrayOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode;
    overlayView.overlayTitle = NSLocalizedString(@"Sorry, can't log in", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = NSLocalizedString(@"TAP TO DISMISS", nil);
    overlayView.button1Text = NSLocalizedString(@"Need Help?", nil);
    overlayView.button2Text = NSLocalizedString(@"OK", nil);
    overlayView.singleTapCompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
    };
    return overlayView;
}

- (void)displayErrorMessageForXMLRPC:(NSString *)message
{
    WPWalkthroughGrayOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button2Text = NSLocalizedString(@"Enable Now", nil);
    overlayView.button1CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
        
        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rng = [regex rangeOfFirstMatchInString:message options:0 range:NSMakeRange(0, [message length])];
        
        if (rng.location == NSNotFound) {
            path = [self getSiteUrl];
            path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
            path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
        } else {
            path = [message substringWithRange:rng];
        }
        
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:path]];
        [webViewController setUsername:_usernameText.text];
        [webViewController setPassword:_passwordText.text];
        webViewController.shouldScrollToBottom = YES;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    [self.view addSubview:overlayView];
}

- (void)displayErrorMessageForBadUrl:(NSString *)message
{
    WPWalkthroughGrayOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
        
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        webViewController.url = [NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

- (void)displayGenericErrorMessage:(NSString *)message
{
    WPWalkthroughGrayOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
        
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(WPWalkthroughGrayOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}

#pragma mark - Button Press Methods

- (void)clickedInfoButton:(id)sender
{
    AboutViewController *aboutViewController = [[AboutViewController alloc] init];
	aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentModalViewController:nc animated:YES];
	[self.navigationController setNavigationBarHidden:YES];
}

- (void)clickedSkipToCreate:(id)sender
{
    [_scrollView setContentOffset:CGPointMake(_viewWidth * 2, 0) animated:NO];
    [self clickedCreateAccount:nil];
}

- (void)clickedSkipToSignIn:(id)sender
{
    [_scrollView setContentOffset:CGPointMake(_viewWidth * 2, 0) animated:YES];
}

- (void)clickedCreateAccount:(UITapGestureRecognizer *)tapGestureRecognizer
{
    CreateAccountAndBlogViewController *createAccountViewController = [[CreateAccountAndBlogViewController alloc] init];
    createAccountViewController.onCreatedUser = ^(NSString *username, NSString *password) {
        _usernameText.text = username;
        _passwordText.text = password;
        _userIsDotCom = true;
        [self.navigationController popViewControllerAnimated:NO];
        [self showAddUsersBlogsForWPCom];
    };
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)clickedBackground:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.view endEditing:YES];
}

- (void)clickedSignIn:(id)sender
{
    [self.view endEditing:YES];

    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    if (![self areFieldsValid]) {
        [self displayErrorMessages];
        return;
    }
    
    [self signIn];
}

#pragma mark - Private Methods

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _viewWidth * 3;
    _scrollView.frame = self.view.bounds;
    _scrollView.contentSize = scrollViewSize;
    _scrollView.pagingEnabled = true;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    _scrollView.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = NO;
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
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    if (_infoButton == nil) {
        _infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_infoButton setImage:infoButtonImage forState:UIControlStateNormal];
        _infoButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [_infoButton addTarget:self action:@selector(clickedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_infoButton];
    }
    
    // Add Logo
    if (_page1Icon == nil) {
        _page1Icon = [[UILabel alloc] init];
        _page1Icon.backgroundColor = [UIColor clearColor];
        _page1Icon.font = [UIFont fontWithName:@"Genericons-Regular" size:90];
        _page1Icon.text = @""; // WordPress Logo
        _page1Icon.shadowColor = _textShadowColor;
        _page1Icon.textColor = [UIColor whiteColor];
        [_page1Icon sizeToFit];
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
        _page1Title.text = NSLocalizedString(@"Welcome to WordPress", nil);
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
        _page1Description.text = @"Full publishing power in a pint-sized package. Make your mark on the go!";
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
        _pageControl.numberOfPages = 3;
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

    // Add "SWIPE TO CONTINUE" text
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

    // Add Skip to Create Account Button
    if (_skipToCreateAccount == nil) {
        _skipToCreateAccount = [[WPWalkthroughButton alloc] init];
        _skipToCreateAccount.text = @"Create Account";
        [_skipToCreateAccount addTarget:self action:@selector(clickedSkipToCreate:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_skipToCreateAccount];
    }
    
    // Add Skip to Sign in Button
    if (_skipToSignIn == nil) {
        _skipToSignIn = [[WPWalkthroughButton alloc] init];
        _skipToSignIn.text = @"Sign In";
        [_skipToSignIn addTarget:self action:@selector(clickedSkipToSignIn:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_skipToSignIn];
    }
}

- (void)layoutPage1Controls
{
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    _infoButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);

    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
    CGFloat extraIconSpaceOnTop = 56;
    CGFloat extraIconSpaceOnBottom = 50;
    CGFloat x,y;
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = GeneralWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
 
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Title.frame) + 1 * GeneralWalkthroughStandardOffset;
    _page1TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page1Description.text sizeWithFont:_page1Description.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1TopSeparator.frame) + GeneralWalkthroughStandardOffset;
    _page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Description.frame) + GeneralWalkthroughStandardOffset;
    _page1BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
    
    // Layout Bottom Panel
    x = 0;
    x = [self adjustX:x forPage:1];
    y = _viewHeight - GeneralWalkthroughBottomBackgroundHeight;
    _bottomPanel.frame = CGRectMake(x, y, _viewWidth, GeneralWalkthroughBottomBackgroundHeight);
    
    // Layout Page Control
    CGFloat verticalSpaceForPageControl = 15;
    x = (_viewWidth - CGRectGetWidth(_pageControl.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) - GeneralWalkthroughStandardOffset - CGRectGetHeight(_pageControl.frame) + verticalSpaceForPageControl;
    _pageControl.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_pageControl.frame), CGRectGetHeight(_pageControl.frame)));
    
    // Layout Swipe to Continue
    x = (_viewWidth - CGRectGetWidth(_page1SwipeToContinue.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_pageControl.frame) - 5 - CGRectGetHeight(_page1SwipeToContinue.frame) + verticalSpaceForPageControl;
    _page1SwipeToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1SwipeToContinue.frame), CGRectGetHeight(_page1SwipeToContinue.frame)));
    
    // Layout Skip to Create Account Button
    x = (_viewWidth - 2*GeneralWalkthroughBottomButtonWidth - GeneralWalkthroughStandardOffset)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) + GeneralWalkthroughStandardOffset;
    _skipToCreateAccount.frame = CGRectMake(x, y, GeneralWalkthroughBottomButtonWidth, GeneralWalkthroughBottomButtonHeight);

    // Layout Skip to Sign In Button
    x = CGRectGetMaxX(_skipToCreateAccount.frame) + GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_skipToCreateAccount.frame);
    _skipToSignIn.frame = CGRectMake(x, y, GeneralWalkthroughBottomButtonWidth, GeneralWalkthroughBottomButtonHeight);
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
        _page2Icon.font = [UIFont fontWithName:@"Genericons-Regular" size:100];
        _page2Icon.text = @""; // Pencil Logo
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
        _page2Title.text = @"You can publish as inspiration strikes";
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
        _page2Description.text = @"Had a brilliant insight? Found a link to share? Captured the perfect pic? Post it in real time.";
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
    CGFloat extraIconSpaceOnTop = 40;
    CGFloat extraIconSpaceOnBottom = 68;
    x = (_viewWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = GeneralWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));

    // Layout Title
    CGSize titleSize = [_page2Title.text sizeWithFont:_page2Title.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));

    // Layout Top Separator
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Title.frame) + GeneralWalkthroughStandardOffset;
    _page2TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*GeneralWalkthroughStandardOffset, 2);

    // Layout Description
    CGSize labelSize = [_page2Description.text sizeWithFont:_page2Description.font constrainedToSize:CGSizeMake(GeneralWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2TopSeparator.frame) + GeneralWalkthroughStandardOffset;
    _page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Description.frame) + GeneralWalkthroughStandardOffset;
    _page2BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*GeneralWalkthroughStandardOffset, 2);
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
        _page3Icon.font = [UIFont fontWithName:@"Genericons-Regular" size:60];
        _page3Icon.text = @""; // Pencil Logo
        _page3Icon.shadowColor = _textShadowColor;
        _page3Icon.textColor = [UIColor whiteColor];
        [_page3Icon sizeToFit];
        [_scrollView addSubview:_page3Icon];
    }
    
    // Add Username
    if (_usernameText == nil) {
        _usernameText = [[WPWalkthroughTextField alloc] init];
        _usernameText.backgroundColor = [UIColor whiteColor];
        _usernameText.placeholder = @"Username / email";
        _usernameText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _usernameText.adjustsFontSizeToFitWidth = true;
        _usernameText.delegate = self;
        _usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_usernameText];
    }
    
    // Add Password
    if (_passwordText == nil) {
        _passwordText = [[WPWalkthroughTextField alloc] init];
        _passwordText.backgroundColor = [UIColor whiteColor];
        _passwordText.placeholder = @"Password";
        _passwordText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _passwordText.delegate = self;
        _passwordText.secureTextEntry = YES;
        [_scrollView addSubview:_passwordText];
    }
    
    // Add Site Url
    if (_siteUrlText == nil) {
        _siteUrlText = [[WPWalkthroughTextField alloc] init];
        _siteUrlText.backgroundColor = [UIColor whiteColor];
        _siteUrlText.placeholder = @"Site Address (URL)";
        _siteUrlText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _siteUrlText.adjustsFontSizeToFitWidth = true;
        _siteUrlText.delegate = self;
        _siteUrlText.keyboardType = UIKeyboardTypeURL;
        _siteUrlText.returnKeyType = UIReturnKeyGo;
        _siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
        _siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_siteUrlText];
    }
    
    // Add Sign In Button
    if (_signInButton == nil) {
        _signInButton = [[WPWalkthroughButton alloc] init];
        _signInButton.text = @"Sign In";
        [_signInButton addTarget:self action:@selector(clickedSignIn:) forControlEvents:UIControlEventTouchUpInside];
        _signInButton.enabled = NO;
        [_scrollView addSubview:_signInButton];
    }
    
    // Add Create Account Text
    if (_createAccountLabel == nil) {
        _createAccountLabel = [[UILabel alloc] init];
        _createAccountLabel.backgroundColor = [UIColor clearColor];
        _createAccountLabel.textColor = [UIColor whiteColor];
        _createAccountLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _createAccountLabel.text = @"Don't have an account? Create one!";
        _createAccountLabel.shadowColor = [UIColor blackColor];
        [_createAccountLabel sizeToFit];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedCreateAccount:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        _createAccountLabel.userInteractionEnabled = YES;
        [_createAccountLabel addGestureRecognizer:tapGestureRecognizer];
        [_scrollView addSubview:_createAccountLabel];
    }
}

- (void)layoutPage3Controls
{
    CGFloat x,y;
    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
    CGFloat extraIconSpaceOnTop = 19;
    CGFloat extraIconSpaceOnBottom = 34;
    x = (_viewWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = GeneralWalkthroughIconVerticalOffset- extraIconSpaceOnTop;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3Icon.frame), CGRectGetHeight(_page3Icon.frame)));

    // Layout Username
    CGFloat textFieldWidth = 288.0;
    CGFloat textFieldHeight = 44.0;
    x = (_viewWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _usernameText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    // Layout Password
    x = (_viewWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_usernameText.frame) + GeneralWalkthroughStandardOffset;
    _passwordText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    // Layout Site URL
    x = (_viewWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_passwordText.frame) + GeneralWalkthroughStandardOffset;
    _siteUrlText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    // Layout Sign in Button
    CGFloat signInButtonWidth = 160.0;
    CGFloat signInButtonHeight = 40.0;
    x = (_viewWidth - signInButtonWidth) / 2.0;;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_siteUrlText.frame) + 2*GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectMake(x, y, signInButtonWidth, signInButtonHeight);

    // Layout Create Account Label
    x = (_viewWidth - CGRectGetWidth(_createAccountLabel.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMinY(_bottomPanel.frame) + (CGRectGetHeight(_bottomPanel.frame) - CGRectGetHeight(_createAccountLabel.frame))/2.0;
    _createAccountLabel.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_createAccountLabel.frame), CGRectGetHeight(_createAccountLabel.frame)));
}

- (void)getInitialWidthAndHeight
{
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
}

- (void)savePositionsOfStickyControls
{
    // The reason we save these positions is because it allows us to drag certain controls along
    // the scrollview as the user moves along the walkthrough.
    if (!_savedOriginalPositionsOfStickyControls) {
        _savedOriginalPositionsOfStickyControls = true;
        _skipToCreateAccountOriginalX = CGRectGetMinX(_skipToCreateAccount.frame);
        _skipToSignInOriginalX = CGRectGetMinX(_skipToSignIn.frame);
        _bottomPanelOriginalX = CGRectGetMinX(_bottomPanel.frame);
        _pageControlOriginalX = CGRectGetMinX(_pageControl.frame);
    }
}

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page
{
    return (x + _viewWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)pageViewed
{
    _pageControl.currentPage = pageViewed - 1;
}

- (void)showCompletionWalkthrough
{
    LoginCompletedWalkthroughViewController *loginCompletedViewController = [[LoginCompletedWalkthroughViewController alloc] init];
    loginCompletedViewController.showsExtraWalkthroughPages = _userIsDotCom || _blogHasJetpack;
    [self.navigationController pushViewController:loginCompletedViewController animated:YES];
}

- (void)showJetpackAuthentication
{
    [SVProgressHUD dismiss];
    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:_blog];
    jetpackSettingsViewController.canBeSkipped = YES;
    [jetpackSettingsViewController setCompletionBlock:^(BOOL didAuthenticate) {
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    }];
    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}

- (void)showHelpViewController:(BOOL)animated
{
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    helpViewController.isBlogSetup = YES;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:helpViewController animated:animated];
}

- (BOOL)isUrlWPCom:(NSString *)url
{
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[url trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[url trim] length])];
    
    return [result count] != 0;
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    NSString *url = [siteURL absoluteString];
    
    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if ([self isUrlWPCom:url]) {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"https://%@", url];
        } else {
            if ([url rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@"https://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [url length])];
            }
        }
    } else {
        if (siteURL.scheme == nil) {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
    }
    
    NSRegularExpression *wplogin = [NSRegularExpression regularExpressionWithPattern:@"/wp-login.php$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *wpadmin = [NSRegularExpression regularExpressionWithPattern:@"/wp-admin/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *trailingslash = [NSRegularExpression regularExpressionWithPattern:@"/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    url = [wplogin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [wpadmin stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    url = [trailingslash stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, [url length]) withTemplate:@""];
    
    return url;
}

- (BOOL)areFieldsValid
{
    if ([self areSelfHostedFieldsFilled]) {
        return [self isUrlValid];
    } else {
        return [self areDotComFieldsFilled];
    }
}

- (BOOL)isUsernameFilled
{
    return [[_usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[_passwordText.text trim] length] != 0;
}

- (BOOL)areDotComFieldsFilled
{
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)areSelfHostedFieldsFilled
{
    return [self areDotComFieldsFilled] && [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)hasUserOnlyEnteredValuesForDotCom
{
    return [self areDotComFieldsFilled] && ![self areSelfHostedFieldsFilled];
}

- (BOOL)areFieldsFilled
{
    return [[_usernameText.text trim] length] != 0 && [[_passwordText.text trim] length] != 0 && [[_siteUrlText.text trim] length] != 0;
}

- (BOOL)isUrlValid
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    return siteURL != nil;
}

- (void)displayErrorMessages
{
    //TODO: Flesh out more
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"Fill out all fields" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)signIn
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = _usernameText.text;
    NSString *password = _passwordText.text;
    
    if ([self hasUserOnlyEnteredValuesForDotCom] || [self isUrlWPCom:_siteUrlText.text]) {
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }
        
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];
        
        [api getBlogOptionsWithSuccess:^(id options){
            [SVProgressHUD dismiss];
            
            if ([options objectForKey:@"wordpress.com"] != nil) {
                [self signInForWPComForUsername:username andPassword:password];
            } else {
                [self signInForSelfHostedForUsername:username password:password options:options andApi:api];
            }
        } failure:^(NSError *error){
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        }];
    };
    
    void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
        [self handleGuessXMLRPCURLFailure:error];
    };
    
    [WordPressXMLRPCApi guessXMLRPCURLForSite:_siteUrlText.text success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)signInForWPComForUsername:(NSString *)username andPassword:(NSString *)password
{
    _userIsDotCom = true;
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to WordPress.com", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    void (^loginSuccessBlock)(void) = ^{
        [SVProgressHUD dismiss];
        [self showAddUsersBlogsForWPCom];
    };
    
    void (^loginFailBlock)(NSError *) = ^(NSError *error){
        // User shouldn't get here because the getOptions call should fail, but in the unlikely case they do throw up an error message.
        [SVProgressHUD dismiss];
        WPFLog(@"Login failed with username %@ : %@", username, error);
        [self displayGenericErrorMessage:NSLocalizedString(@"Please update your credentials and try again.", nil)];
    };
    
    [[WordPressComApi sharedApi] signInWithUsername:username
                                           password:password
                                            success:loginSuccessBlock
                                            failure:loginFailBlock];
    
}

- (void)signInForSelfHostedForUsername:(NSString *)username password:(NSString *)password options:(NSDictionary *)options andApi:(WordPressXMLRPCApi *)api
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    if ([options objectForKey:@"jetpack_version"] != nil) {
        _blogHasJetpack = true;
    }
    
    [api getBlogsWithSuccess:^(NSArray *blogs) {
        _blogs = blogs;
        [self handleGetBlogsSuccess:[api.xmlrpc absoluteString]];
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [self displayRemoteError:error];
    }];
}

- (void)handleGuessXMLRPCURLFailure:(NSError *)error
{
    [SVProgressHUD dismiss];
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorUserCancelledAuthentication) {
        [self displayRemoteError:nil];
    } else if ([error.domain isEqual:WPXMLRPCErrorDomain] && error.code == WPXMLRPCInvalidInputError) {
        [self displayRemoteError:error];
    } else if([error.domain isEqual:AFNetworkingErrorDomain]) {
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", nil), [error localizedDescription]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  str, NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
        [self displayRemoteError:err];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", nil), NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadURL userInfo:userInfo];
        [self displayRemoteError:err];
    }
}

- (void)handleGetBlogsSuccess:(NSString *)xmlRPCUrl {
    if ([_blogs count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install,
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([_blogs count] > 1) {
            subsite = [[_blogs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlRPCUrl]] lastObject];
        }
        
        if (subsite == nil) {
            subsite = [_blogs objectAtIndex:0];
        }
        
        if ([_blogs count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            [SVProgressHUD dismiss];
            [self showAddUsersBlogsForSelfHosted:xmlRPCUrl];
        } else {
            [self createBlogWithXmlRpc:xmlRPCUrl andBlogDetails:subsite];
            [self synchronizeNewlyAddedBlog];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", nil)}];
        [self displayRemoteError:error];
    }
}

- (void)displayRemoteError:(NSError *)error {
    NSString *message = [error localizedDescription];
    if ([error code] == 403) {
        message = NSLocalizedString(@"Please update your credentials and try again.", nil);
    }
    
    if ([[message trim] length] == 0) {
        message = NSLocalizedString(@"Sign in failed. Please try again.", nil);
    }
    
    if ([error code] == 405) {
        [self displayErrorMessageForXMLRPC:message];
    } else {
        if ([error code] == NSURLErrorBadURL) {
            [self displayErrorMessageForBadUrl:message];
        } else {
            [self displayGenericErrorMessage:message];
        }
    }
}

- (NewAddUsersBlogViewController *)addUsersBlogViewController
{
    NewAddUsersBlogViewController *vc = [[NewAddUsersBlogViewController alloc] init];
    vc.username = _usernameText.text;
    vc.password = _passwordText.text;
    vc.blogAdditionCompleted = ^(NewAddUsersBlogViewController * viewController){
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onNoBlogsLoaded = ^(NewAddUsersBlogViewController *viewController) {
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onErrorLoading = ^(NewAddUsersBlogViewController *viewController, NSError *error) {
        WPFLog(@"There was an error loading blogs after sign in");
        [self.navigationController popViewControllerAnimated:YES];
        [self displayGenericErrorMessage:[error localizedDescription]];
    };
    
    return vc;
}

- (void)showAddUsersBlogsForSelfHosted:(NSString *)xmlRPCUrl
{
    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController];
    vc.isWPCom = NO;
    vc.xmlRPCUrl = xmlRPCUrl;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAddUsersBlogsForWPCom
{
    NewAddUsersBlogViewController *vc = [self addUsersBlogViewController];
    vc.isWPCom = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlRPCUrl andBlogDetails:(NSDictionary *)blogDetails
{
    NSParameterAssert(blogDetails != nil);
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:_usernameText.text forKey:@"username"];
    [newBlog setObject:_passwordText.text forKey:@"password"];
    [newBlog setObject:xmlRPCUrl forKey:@"xmlrpc"];
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    _blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
    [_blog dataSave];
}

- (void)synchronizeNewlyAddedBlog
{
    [SVProgressHUD setStatus:NSLocalizedString(@"Synchronizing Blog", nil)];
    void (^successBlock)() = ^{
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
        [SVProgressHUD dismiss];
        if ([_blog hasJetpack]) {
            [self showJetpackAuthentication];
        } else {
            [self showCompletionWalkthrough];
        }
    };
    void (^failureBlock)(NSError*) = ^(NSError * error) {
        [SVProgressHUD dismiss];
    };
    [_blog syncBlogWithSuccess:successBlock failure:failureBlock];
}

- (void)keyboardWillShow
{
    [UIView animateWithDuration:0.3 animations:^{
        NSArray *controlsToMove = @[_page3Icon, _usernameText, _passwordText, _siteUrlText, _signInButton];
        
        for (UIControl *control in controlsToMove) {
            CGRect frame = control.frame;
            frame.origin.y -= GeneralWalkthroughKeyboardOffset;
            control.frame = frame;
        }
    }];
}

- (void)keyboardWillHide
{
    [UIView animateWithDuration:0.3 animations:^{
        NSArray *controlsToMove = @[_page3Icon, _usernameText, _passwordText, _siteUrlText, _signInButton];
        
        for (UIControl *control in controlsToMove) {
            CGRect frame = control.frame;
            frame.origin.y += GeneralWalkthroughKeyboardOffset;
            control.frame = frame;
        }
    }];
}

@end
