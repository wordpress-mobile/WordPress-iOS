//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <WPXMLRPC/WPXMLRPC.h>
#import "GeneralWalkthroughViewController.h"
#import "CreateWPComAccountViewController.h"
#import "AddUsersBlogsViewController.h"
#import "AboutViewController.h"
#import "WPWalkthroughButton.h"
#import "WPWalkthroughLineSeparatorView.h"
#import "WPWalkthroughTextField.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "Blog+Jetpack.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "JetpackSettingsViewController.h"

@interface GeneralWalkthroughViewController () <
    UIScrollViewDelegate,
    CreateWPComAccountViewControllerDelegate,
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
    
    CGFloat _pageWidth;
    CGFloat _pageHeight;
    
    CGFloat _bottomPanelOriginalX;
    CGFloat _skipToCreateAccountOriginalX;
    CGFloat _skipToSignInOriginalX;
    CGFloat _pageControlOriginalX;
    
    UIColor *_textShadowColor;
        
    BOOL _userIsDotCom;
    BOOL _blogHasJetpack;
    BOOL _savedOriginalPositionsOfStickyControls;
    NSArray *_blogs;
    Blog *_blog;
}

@end

@implementation GeneralWalkthroughViewController

NSUInteger const GeneralWalkthroughIconVerticalOffset = 77;
NSUInteger const GeneralWalkthroughStandardOffset = 16;
NSUInteger const GeneralWalkthroughBottomBackgroundHeight = 64;
NSUInteger const GeneralWalkthroughBottomButtonWidth = 136.0;
NSUInteger const GeneralWalkthroughBottomButtonHeight = 32.0;

NSUInteger const GeneralWalkthroughFailureAlertViewBadURLErrorTag = 20;
NSUInteger const GeneralWalkthroughFailureAlertViewXMLRPCErrorTag = 30;

NSUInteger const GeneralWalkthroughUsernameTextFieldTag = 1;
NSUInteger const GeneralWalkthroughPasswordTextFieldTag = 2;
NSUInteger const GeneralWalkthroughSiteUrlTextFieldTag = 3;
 
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _pageWidth = CGRectGetWidth(self.view.bounds);
    _pageHeight = CGRectGetHeight(self.view.bounds);
    
    // We are technically laying out the view twice on this view's initialization, but as we hardcoded the width/height
    // in viewDidLoad to prevent a flicker, we are doing this should the hardcoded dimensions no longer be correct in a
    // future version of iOS. If a future version of iOS results in different dimensions for the form sheet, this will
    // result in this page flickering but at least the layout will ultimately be correct.
    [self layoutScrollview];
    [self layoutPage1Controls];
    [self layoutPage2Controls];
    [self layoutPage3Controls];
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
    if (scrollView.contentOffset.x < 0) {
        //TODO: Remove this duplication
        CGRect bottomPanelFrame = _bottomPanel.frame;
        bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
        _bottomPanel.frame = bottomPanelFrame;
        
        CGRect skipToCreateAccountFrame = _skipToCreateAccount.frame;
        skipToCreateAccountFrame.origin.x = _skipToCreateAccountOriginalX + scrollView.contentOffset.x;
        _skipToCreateAccount.frame = skipToCreateAccountFrame;
        
        CGRect skipToSignInFrame = _skipToSignIn.frame;
        skipToSignInFrame.origin.x = _skipToSignInOriginalX + scrollView.contentOffset.x;
        _skipToSignIn.frame = skipToSignInFrame;

        return;
    }
    
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_pageWidth) + 1;
    
    // We only want the sign in, create account and help buttons to drag along until we hit the sign in screen
    if (pageViewed < 3) {
        // If the user is editing the sign in page and then swipes over, dismiss keyboard
        [self.view endEditing:YES];

        CGRect skipToCreateAccountFrame = _skipToCreateAccount.frame;
        skipToCreateAccountFrame.origin.x = _skipToCreateAccountOriginalX + scrollView.contentOffset.x;
        _skipToCreateAccount.frame = skipToCreateAccountFrame;
        
        CGRect skipToSignInFrame = _skipToSignIn.frame;
        skipToSignInFrame.origin.x = _skipToSignInOriginalX + scrollView.contentOffset.x;
        _skipToSignIn.frame = skipToSignInFrame;
        
        CGRect pageControlFrame = _pageControl.frame;
        pageControlFrame.origin.x = _pageControlOriginalX + scrollView.contentOffset.x;
        _pageControl.frame = pageControlFrame;
    }
    
    CGRect bottomPanelFrame = _bottomPanel.frame;
    bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
    _bottomPanel.frame = bottomPanelFrame;
    
    [self flagPageViewed:pageViewed];
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
    switch (textField.tag) {
        case GeneralWalkthroughUsernameTextFieldTag:
            [_passwordText becomeFirstResponder];
            break;
        case GeneralWalkthroughPasswordTextFieldTag:
            [_siteUrlText becomeFirstResponder];
            break;
        case GeneralWalkthroughSiteUrlTextFieldTag:
            [self clickedSignIn:nil];
            break;
    }
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

#pragma mark - UIAlertView Delegate Related

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == GeneralWalkthroughFailureAlertViewBadURLErrorTag) {
        [self handleAlertViewForBadURL:alertView withButtonIndex:buttonIndex];
    } else if (alertView.tag == GeneralWalkthroughFailureAlertViewXMLRPCErrorTag) {
        [self handleAlertViewForXMLRPCError:alertView withButtonIndex:buttonIndex];
    } else {
        [self handleAlertViewForGeneralError:alertView withButtonIndex:buttonIndex];
    }
}

- (void)handleAlertViewForBadURL:(UIAlertView *)alertView withButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        webViewController.url = [NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
}

- (void)handleAlertViewForXMLRPCError:(UIAlertView *)alertView withButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self showHelpViewController];
    } else if (buttonIndex == 1) {
        NSString *path = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+writing.php" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *msg = [alertView message];
        NSRange rng = [regex rangeOfFirstMatchInString:msg options:0 range:NSMakeRange(0, [msg length])];
        
        if (rng.location == NSNotFound) {
            path = [self getSiteUrl];
            path = [path stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
            path = [path stringByAppendingFormat:@"/wp-admin/options-writing.php"];
        } else {
            path = [msg substringWithRange:rng];
        }
        
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:path]];
        [webViewController setUsername:_usernameText.text];
        [webViewController setPassword:_passwordText.text];
        webViewController.shouldScrollToBottom = YES;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
}

- (void)handleAlertViewForGeneralError:(UIAlertView *)alertView withButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self showHelpViewController];
    }
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
    [_scrollView setContentOffset:CGPointMake(_pageWidth * 2, 0) animated:NO];
    [self clickedCreateAccount:nil];
}

- (void)clickedSkipToSignIn:(id)sender
{
    [_scrollView setContentOffset:CGPointMake(_pageWidth * 2, 0) animated:YES];
}

- (void)clickedCreateAccount:(UITapGestureRecognizer *)tapGestureRecognizer
{
    // The reason we unhide the navigation bar here even though the create account
    // page does the same is because if we don't the animation on the create account
    // page is very jarring.
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    CreateWPComAccountViewController *createAccountViewController = [[CreateWPComAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    createAccountViewController.delegate = self;
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)clickedBackground:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.view endEditing:YES];
}

- (void)clickedSignIn:(id)sender
{
    if (![self areFieldsValid]) {
        [self displayErrorMessages];
        return;
    }
    
    [self signIn];
}

#pragma mark - CreateWPComAccountViewControllerDelegate

- (void)createdAndSignedInAccountWithUserName:(NSString *)userName
{
    [self.navigationController popViewControllerAnimated:NO];
    _userIsDotCom = true;
    [self displayAddUsersBlogsForWPCom];
}

- (void)createdAccountWithUserName:(NSString *)userName
{
    //TODO: Deal with this error where the user creates an account then we are unable to sign in. Perhaps we retry once, and then display an error?
    NSLog(@"Account created, but sign in failed for some reason");
}

#pragma mark - Private Methods

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _pageWidth * 3;
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
    UIImage *infoButtonImage = [UIImage imageNamed:@"infoButton"];
    if (_infoButton == nil) {
        _infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_infoButton setImage:infoButtonImage forState:UIControlStateNormal];
        _infoButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
        [_infoButton addTarget:self action:@selector(clickedInfoButton:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_infoButton];
    }
    
    // Unfortunately the way iOS generates the Genericons Font results in far too much space on the top and the bottom, so for now we will adjust this by hand.
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
    
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.backgroundColor = [UIColor clearColor];
        _page1Title.textAlignment = UITextAlignmentCenter;
        _page1Title.numberOfLines = 0;
        _page1Title.lineBreakMode = UILineBreakModeWordWrap;
        _page1Title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
        _page1Title.text = NSLocalizedString(@"Welcome to WordPress", @"");
        _page1Title.shadowColor = _textShadowColor;
        _page1Title.shadowOffset = CGSizeMake(1.0, 1.0);
        _page1Title.textColor = [UIColor whiteColor];
        [_page1Title sizeToFit];
        [_scrollView addSubview:_page1Title];
    }
    
    if (_page1TopSeparator == nil) {
        _page1TopSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page1TopSeparator];
    }

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

    if (_skipToCreateAccount == nil) {
        _skipToCreateAccount = [[WPWalkthroughButton alloc] init];
        _skipToCreateAccount.text = @"Create Account";
        [_skipToCreateAccount addTarget:self action:@selector(clickedSkipToCreate:) forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:_skipToCreateAccount];
    }
    
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
    x = (_pageWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = GeneralWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
 
    x = (_pageWidth - CGRectGetWidth(_page1Title.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Title.frame), CGRectGetHeight(_page1Title.frame)));
    
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Title.frame) + 3 * GeneralWalkthroughStandardOffset;
    _page1TopSeparator.frame = CGRectMake(x, y, _pageWidth - 2*GeneralWalkthroughStandardOffset, 2);
    
    CGSize labelSize = [_page1Description.text sizeWithFont:_page1Description.font constrainedToSize:CGSizeMake(289.0, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_pageWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1TopSeparator.frame) + GeneralWalkthroughStandardOffset;
    _page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Description.frame) + GeneralWalkthroughStandardOffset;
    _page1BottomSeparator.frame = CGRectMake(x, y, _pageWidth - 2*GeneralWalkthroughStandardOffset, 2);
    
    x = 0;
    x = [self adjustX:x forPage:1];
    y = _pageHeight - GeneralWalkthroughBottomBackgroundHeight;
    _bottomPanel.frame = CGRectMake(x, y, _pageWidth, GeneralWalkthroughBottomBackgroundHeight);
    
    CGFloat verticalSpaceForPageControl = 15;
    x = (_pageWidth - CGRectGetWidth(_pageControl.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) - GeneralWalkthroughStandardOffset - CGRectGetHeight(_pageControl.frame) + verticalSpaceForPageControl;
    _pageControl.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_pageControl.frame), CGRectGetHeight(_pageControl.frame)));
    
    x = (_pageWidth - CGRectGetWidth(_page1SwipeToContinue.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_pageControl.frame) - 5 - CGRectGetHeight(_page1SwipeToContinue.frame) + verticalSpaceForPageControl;
    _page1SwipeToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1SwipeToContinue.frame), CGRectGetHeight(_page1SwipeToContinue.frame)));
    
    x = (_pageWidth - 2*GeneralWalkthroughBottomButtonWidth - GeneralWalkthroughStandardOffset)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) + GeneralWalkthroughStandardOffset;
    _skipToCreateAccount.frame = CGRectMake(x, y, GeneralWalkthroughBottomButtonWidth, GeneralWalkthroughBottomButtonHeight);

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
    
    if (_page2Title == nil) {
        _page2Title = [[UILabel alloc] init];
        _page2Title.backgroundColor = [UIColor clearColor];
        _page2Title.textAlignment = UITextAlignmentCenter;
        _page2Title.numberOfLines = 0;
        _page2Title.lineBreakMode = UILineBreakModeWordWrap;
        _page2Title.font = [UIFont fontWithName:@"OpenSans-Light" size:29];
        _page2Title.text = @"You can publish as\ninspiration strikes";
        _page2Title.shadowColor = _textShadowColor;
        _page2Title.shadowOffset = CGSizeMake(1, 1);
        _page2Title.textColor = [UIColor whiteColor];
        [_page2Title sizeToFit];
        [_scrollView addSubview:_page2Title];
    }
    
    if (_page2TopSeparator == nil) {
        _page2TopSeparator = [[WPWalkthroughLineSeparatorView alloc] init];
        [_scrollView addSubview:_page2TopSeparator];
    }
    
    if (_page2Description == nil) {
        _page2Description = [[UILabel alloc] init];
        _page2Description.backgroundColor = [UIColor clearColor];
        _page2Description.textAlignment = UITextAlignmentCenter;
        _page2Description.numberOfLines = 0;
        _page2Description.lineBreakMode = UILineBreakModeWordWrap;
        _page2Description.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _page2Description.text = @"Had a brilliant insight? Found a link to share? Captured the perfect pic?\nPost it in real time.";
        _page2Description.shadowColor = _textShadowColor;
        _page2Description.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page2Description];
    }
    
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
    x = (_pageWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = GeneralWalkthroughIconVerticalOffset - extraIconSpaceOnTop;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));

    x = (_pageWidth - CGRectGetWidth(_page2Title.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Title.frame), CGRectGetHeight(_page2Title.frame)));

    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Title.frame) + GeneralWalkthroughStandardOffset;
    _page2TopSeparator.frame = CGRectMake(x, y, _pageWidth - 2*GeneralWalkthroughStandardOffset, 2);

    CGSize labelSize = [_page2Description.text sizeWithFont:_page2Description.font constrainedToSize:CGSizeMake(289.0, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_pageWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2TopSeparator.frame) + GeneralWalkthroughStandardOffset;
    _page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    x = GeneralWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Description.frame) + GeneralWalkthroughStandardOffset;
    _page2BottomSeparator.frame = CGRectMake(x, y, _pageWidth - 2*GeneralWalkthroughStandardOffset, 2);
}

- (void)initializePage3
{
    [self addPage3Controls];
    [self layoutPage3Controls];
}

- (void)addPage3Controls
{
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
    
    if (_usernameText == nil) {
        _usernameText = [[WPWalkthroughTextField alloc] init];
        _usernameText.backgroundColor = [UIColor whiteColor];
        _usernameText.placeholder = @"Username / email";
        _usernameText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _usernameText.delegate = self;
        _usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
        _usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _usernameText.tag = GeneralWalkthroughUsernameTextFieldTag;
        [_scrollView addSubview:_usernameText];
    }
    
    if (_passwordText == nil) {
        _passwordText = [[WPWalkthroughTextField alloc] init];
        _passwordText.backgroundColor = [UIColor whiteColor];
        _passwordText.placeholder = @"Password";
        _passwordText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _passwordText.delegate = self;
        _passwordText.secureTextEntry = YES;
        _passwordText.tag = GeneralWalkthroughPasswordTextFieldTag;
        [_scrollView addSubview:_passwordText];
    }
    
    if (_siteUrlText == nil) {
        _siteUrlText = [[WPWalkthroughTextField alloc] init];
        _siteUrlText.backgroundColor = [UIColor whiteColor];
        _siteUrlText.placeholder = @"Site Address (URL)";
        _siteUrlText.font = [UIFont fontWithName:@"OpenSans" size:21.0];
        _siteUrlText.delegate = self;
        _siteUrlText.tag = GeneralWalkthroughSiteUrlTextFieldTag;
        _siteUrlText.keyboardType = UIKeyboardTypeURL;
        _siteUrlText.returnKeyType = UIReturnKeyGo;
        _siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
        _siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [_scrollView addSubview:_siteUrlText];
    }
    
    if (_signInButton == nil) {
        _signInButton = [[WPWalkthroughButton alloc] init];
        _signInButton.text = @"Sign In";
        [_signInButton addTarget:self action:@selector(clickedSignIn:) forControlEvents:UIControlEventTouchUpInside];
        _signInButton.enabled = NO;
        [_scrollView addSubview:_signInButton];
    }
    
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
    x = (_pageWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = GeneralWalkthroughIconVerticalOffset- extraIconSpaceOnTop;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3Icon.frame), CGRectGetHeight(_page3Icon.frame)));

    CGFloat textFieldWidth = 288.0;
    CGFloat textFieldHeight = 44.0;
    x = (_pageWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Icon.frame) + GeneralWalkthroughStandardOffset - extraIconSpaceOnBottom;
    _usernameText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    x = (_pageWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_usernameText.frame) + GeneralWalkthroughStandardOffset;
    _passwordText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    x = (_pageWidth - textFieldWidth)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_passwordText.frame) + GeneralWalkthroughStandardOffset;
    _siteUrlText.frame = CGRectIntegral(CGRectMake(x, y, textFieldWidth, textFieldHeight));

    CGFloat signInButtonWidth = 160.0;
    CGFloat signInButtonHeight = 40.0;
    x = (_pageWidth - signInButtonWidth) / 2.0;;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_siteUrlText.frame) + 2*GeneralWalkthroughStandardOffset;
    _signInButton.frame = CGRectMake(x, y, signInButtonWidth, signInButtonHeight);

    x = (_pageWidth - CGRectGetWidth(_createAccountLabel.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMinY(_bottomPanel.frame) + (CGRectGetHeight(_bottomPanel.frame) - CGRectGetHeight(_createAccountLabel.frame))/2.0;
    _createAccountLabel.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_createAccountLabel.frame), CGRectGetHeight(_createAccountLabel.frame)));
}

- (void)getInitialWidthAndHeight
{
    if (IS_IPAD) {
        // This is a hacky, but it seems like Apple won't give you the correct dimensions of a view inside a form sheet
        // until viewDidAppear which will result in a nasty layout flicker because we don't have the correct dimensions
        // from self.view.bounds.
        _pageWidth = 540;
        _pageHeight = 620;
    } else {
        _pageWidth = CGRectGetWidth(self.view.bounds);
        _pageHeight = CGRectGetHeight(self.view.bounds);
    }
}

- (void)savePositionsOfStickyControls
{
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
    return (x + _pageWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)pageViewed
{
    _pageControl.currentPage = pageViewed - 1;
}

- (void)blogsRefreshNotificationReceived:(NSNotification *)notification
{
    // User added blogs, now show completion walkthrough
    [self.navigationController popViewControllerAnimated:NO];
    [self showCompletionWalkthrough];
}

- (void)showCompletionWalkthrough
{
    BOOL showExtraPages = _userIsDotCom || _blogHasJetpack;
    LoginCompletedWalkthroughViewController *loginCompletedViewController = [[LoginCompletedWalkthroughViewController alloc] init];
    loginCompletedViewController.showsExtraWalkthroughPages = showExtraPages;
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

- (void)showHelpViewController
{
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    helpViewController.isBlogSetup = YES;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:helpViewController animated:YES];
}

- (BOOL)isUrlWPCom
{
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[_siteUrlText.text trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[_siteUrlText.text trim] length])];
    
    return [result count] != 0;
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:_siteUrlText.text];
    NSString *url = [siteURL absoluteString];
    
    // If the user enters a WordPress.com url we want to ensure we are communicating over https
    if ([self isUrlWPCom]) {
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

#pragma mark - Private Methods Related to Sign In

- (BOOL)areFieldsValid
{
    if ([self areSelfHostedFieldsFilled]) {
        return [self isUrlValid];
    } else {
        return [self areDotComFieldsFilled];
    }
}

- (BOOL)areDotComFieldsFilled
{
    return [[_usernameText.text trim] length] != 0 && [[_passwordText.text trim] length] != 0;
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
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", @"") maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = _usernameText.text;
    NSString *password = _passwordText.text;
    
    if ([self hasUserOnlyEnteredValuesForDotCom]) {
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
        [self displayAddUsersBlogsForWPCom];
    };
    
    void (^loginFailBlock)(NSError *) = ^(NSError *error){
        // User shouldn't get here because the getOptions call should fail, but in the unlikely case they do throw up an error message.
        [SVProgressHUD dismiss];
        WPFLog(@"Login failed with username %@ : %@", username, error);
        UIAlertView *failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", nil)
                                                                   message:NSLocalizedString(@"Please update your credentials and try again.", @"")
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                         otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
        [failureAlertView show];
    };
    
    [[WordPressComApi sharedApi] signInWithUsername:username
                                           password:password
                                            success:loginSuccessBlock
                                            failure:loginFailBlock];
    
}

- (void)signInForSelfHostedForUsername:(NSString *)username password:(NSString *)password options:(NSDictionary *)options andApi:(WordPressXMLRPCApi *)api
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", @"") maskType:SVProgressHUDMaskTypeBlack];
    
    if ([options objectForKey:@"jetpack_version"] != nil) {
        _blogHasJetpack = true;
    }
    
    // Self Hosted
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
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"There was a server error communicating with your site:\n%@\nTap 'Need Help?' to view the FAQ.", @""), [error localizedDescription]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  str, NSLocalizedDescriptionKey,
                                  nil];
        NSError *err = [NSError errorWithDomain:@"org.wordpress.iphone" code:NSURLErrorBadServerResponse userInfo:userInfo];
        [self displayRemoteError:err];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  NSLocalizedString(@"Unable to find a WordPress site at that URL. Tap 'Need Help?' to view the FAQ.", @""), NSLocalizedDescriptionKey,
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
            [self displayAddUsersBlogsForXmlRpc:xmlRPCUrl];
        } else {
            [self createBlogWithXmlRpc:xmlRPCUrl andBlogDetails:subsite];
            [self synchronizeNewlyAddedBlog];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", @"")}];
        [self displayRemoteError:error];
    }
}

- (void)displayRemoteError:(NSError *)error {
    NSString *message = [error localizedDescription];
    if ([error code] == 403) {
        message = NSLocalizedString(@"Please update your credentials and try again.", @"");
    }
    
    UIAlertView *failureAlertView;
    if ([error code] == 405) {
        // XMLRPC disabled.
        failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                            otherButtonTitles:NSLocalizedString(@"Enable Now", @""), nil];
        
        failureAlertView.tag = GeneralWalkthroughFailureAlertViewXMLRPCErrorTag;
    } else {
        failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                            otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
        
        if ([error code] == NSURLErrorBadURL) {
            // take the user to the FAQ page when they hit "Need Help"
            failureAlertView.tag = GeneralWalkthroughFailureAlertViewBadURLErrorTag;
        }
    }
    
    [failureAlertView show];
}

- (void)displayAddUsersBlogsForXmlRpc:(NSString *)xmlRPCUrl
{
    [SVProgressHUD dismiss];
    AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] init];
    addUsersBlogsView.isWPcom = NO;
    addUsersBlogsView.usersBlogs = _blogs;
    addUsersBlogsView.url = xmlRPCUrl;
    addUsersBlogsView.username = _usernameText.text;
    addUsersBlogsView.password = _passwordText.text;
    addUsersBlogsView.geolocationEnabled = true;
    addUsersBlogsView.hideBackButton = true;
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];
}

- (void)displayAddUsersBlogsForWPCom
{
    AddUsersBlogsViewController *addUsersBlogsView;
    if (IS_IPAD == YES) {
        addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController-iPad" bundle:nil];
    }
    else {
        addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
    }
    addUsersBlogsView.isWPcom = true;
    addUsersBlogsView.hideBackButton = true;
    [addUsersBlogsView setUsername:_usernameText.text];
    [addUsersBlogsView setPassword:_passwordText.text];
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];
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
    [SVProgressHUD setStatus:NSLocalizedString(@"Synchronizing Blog", @"")];
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

@end
