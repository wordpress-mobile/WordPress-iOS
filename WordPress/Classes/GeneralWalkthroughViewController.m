//
//  GeneralWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//
#import <SVProgressHUD/SVProgressHUD.h>
#import <WPXMLRPC/WPXMLRPC.h>
#import "GeneralWalkthroughViewController.h"
#import "AboutViewController.h"
#import "AddUsersBlogsViewController.h"
#import "JetpackSettingsViewController.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "CreateWPComAccountViewController.h"
#import "WordPressComApi.h"
#import "WPWebViewController.h"
#import "Blog+Jetpack.h"

@interface GeneralWalkthroughViewController () <
    CreateWPComAccountViewControllerDelegate,
    UIScrollViewDelegate,
    UITextFieldDelegate> {
        
    CGFloat _pageWidth;
    CGFloat _signInButtonOriginalX;
    CGFloat _createAccountButtonOriginalX;
    CGFloat _helpButtonOriginalX;
        
    NSArray *_blogs;
        
    Blog *_blog;
        
    BOOL _userIsDotCom;
    BOOL _blogHasJetpack;
}

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIButton *createAccountButton;
@property (nonatomic, strong) IBOutlet UIButton *signInButton;
@property (nonatomic, strong) IBOutlet UIButton *helpButton;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) IBOutlet UILabel *page1Label;

@property (nonatomic, strong) IBOutlet UILabel *page2Label;

@property (nonatomic, strong) IBOutlet UILabel *page3Label;

@property (nonatomic, strong) IBOutlet UITextField *usernameText;
@property (nonatomic, strong) IBOutlet UITextField *passwordText;
@property (nonatomic, strong) IBOutlet UITextField *siteUrlText;
@property (nonatomic, strong) IBOutlet UIButton *page4SignInButton;
@property (nonatomic, strong) IBOutlet UIButton *page4CreateAccountButton;

@end

@implementation GeneralWalkthroughViewController

NSUInteger const GeneralWalkthroughUsernameTextFieldTag = 1;
NSUInteger const GeneralWalkthroughPasswordTextFieldTag = 2;
NSUInteger const GeneralWalkthroughSiteUrlTextFieldTag = 3;

NSUInteger const GeneralWalkthroughFailureAlertViewBadURLErrorTag = 20;
NSUInteger const GeneralWalkthroughFailureAlertViewXMLRPCErrorTag = 30;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    
    _pageWidth = CGRectGetWidth(self.view.frame);
    
    // These are needed so we can create the sticky effect for the sign in, create, and help buttons
    _signInButtonOriginalX = CGRectGetMinX(self.signInButton.frame);
    _createAccountButtonOriginalX = CGRectGetMinX(self.createAccountButton.frame);
    _helpButtonOriginalX = CGRectGetMinX(self.helpButton.frame);
    
    [self moveControl:self.page1Label toPage:1];
    
    [self moveControl:self.page2Label toPage:2];
    
    [self moveControl:self.page3Label toPage:3];
    
    [self moveControl:self.usernameText toPage:4];
    [self moveControl:self.passwordText toPage:4];
    [self moveControl:self.siteUrlText toPage:4];
    [self moveControl:self.page4CreateAccountButton toPage:4];
    [self moveControl:self.page4SignInButton toPage:4];
        
    self.usernameText.delegate = self;
    self.usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
    self.usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameText.tag = GeneralWalkthroughUsernameTextFieldTag;
    
    self.passwordText.delegate = self;
    self.passwordText.tag = GeneralWalkthroughPasswordTextFieldTag;
    
    self.siteUrlText.delegate = self;
    self.siteUrlText.keyboardType = UIKeyboardTypeURL;
    self.siteUrlText.returnKeyType = UIReturnKeyGo;
    self.siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
    self.siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.siteUrlText.tag = GeneralWalkthroughSiteUrlTextFieldTag;
    
    self.pageControl.numberOfPages = 4;
    
    CGSize scrollViewSize = self.scrollView.contentSize;
    scrollViewSize.width = _pageWidth * 4;
    self.scrollView.frame = self.view.frame;
    self.scrollView.contentSize = scrollViewSize;
    self.scrollView.pagingEnabled = true;
    self.scrollView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE)
        return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x < 0)
        return;
    
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_pageWidth) + 1;

    // We only want the sign in, create account and help buttons to drag along until we hit the sign in screen
    if (pageViewed < 4) {
        CGRect signInButtonFrame = self.signInButton.frame;
        signInButtonFrame.origin.x = _signInButtonOriginalX + scrollView.contentOffset.x;
        self.signInButton.frame = signInButtonFrame;
        
        CGRect createAccountButtonFrame = self.createAccountButton.frame;
        createAccountButtonFrame.origin.x = _createAccountButtonOriginalX + scrollView.contentOffset.x;
        self.createAccountButton.frame = createAccountButtonFrame;
        
        CGRect helpButtonFrame = self.helpButton.frame;
        helpButtonFrame.origin.x = _helpButtonOriginalX + scrollView.contentOffset.x;
        self.helpButton.frame = helpButtonFrame;        
    }
    
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

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == GeneralWalkthroughFailureAlertViewBadURLErrorTag) {
        [self handleAlertViewForBadURL:alertView withButtonIndex:buttonIndex];
    } else if (alertView.tag == GeneralWalkthroughFailureAlertViewXMLRPCErrorTag) {
        [self handleAlertViewForXMLRPCError:alertView withButtonIndex:buttonIndex];
    } else {
        [self handleAlertViewForGeneralError:alertView withButtonIndex:buttonIndex];
    }
}

#pragma mark - IBAction Methods

- (IBAction)showAboutView:(id)sender
{
    AboutViewController *aboutViewController = [[AboutViewController alloc] init];
	aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentModalViewController:nc animated:YES];
	[self.navigationController setNavigationBarHidden:YES];
}

- (IBAction)skipToSignIn:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(_pageWidth * 3, 0) animated:YES];
}

- (IBAction)skipToCreate:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(_pageWidth * 3, 0) animated:NO];
    [self clickedCreate:nil];
}

- (IBAction)clickedSignIn:(id)sender
{
    if (![self areFieldsValid]) {
        [self displayErrorMessages];
        return;
    }
    
    [self signIn];    
}

- (IBAction)clickedCreate:(id)sender
{
    // The reason we unhide the navigation bar here even though the create account
    // page does the same is because if we don't the animation on the create account
    // page is very jarring.
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    CreateWPComAccountViewController *createAccountViewController = [[CreateWPComAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    createAccountViewController.delegate = self;
    [self.navigationController pushViewController:createAccountViewController animated:YES];
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

#pragma mark - Private Methods - Sign In Related

- (void)signIn
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", @"") maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = self.usernameText.text;
    NSString *password = self.passwordText.text;
    
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
        
    [WordPressXMLRPCApi guessXMLRPCURLForSite:self.siteUrlText.text success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
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
        [SVProgressHUD dismiss];
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
    AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] init];
    addUsersBlogsView.isWPcom = NO;
    addUsersBlogsView.usersBlogs = _blogs;
    addUsersBlogsView.url = xmlRPCUrl;
    addUsersBlogsView.username = self.usernameText.text;
    addUsersBlogsView.password = self.passwordText.text;
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
    [addUsersBlogsView setUsername:self.usernameText.text];
    [addUsersBlogsView setPassword:self.passwordText.text];
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlRPCUrl andBlogDetails:(NSDictionary *)blogDetails
{
    NSParameterAssert(blogDetails != nil);
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:self.usernameText.text forKey:@"username"];
    [newBlog setObject:self.passwordText.text forKey:@"password"];
    [newBlog setObject:xmlRPCUrl forKey:@"xmlrpc"];
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    _blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
    [_blog dataSave];
}

- (void)synchronizeNewlyAddedBlog
{
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

- (void)moveControl:(UIView *)control toPage:(NSUInteger)page
{
    [control removeFromSuperview];
    [self.scrollView addSubview:control];
    
    CGRect frame = control.frame;
    frame.origin.x += _pageWidth*(page-1);
    control.frame = frame;
}

- (void)flagPageViewed:(NSUInteger)page
{
    self.pageControl.currentPage = page - 1;
    switch (page) {
        case 1:
        case 2:
        case 3:
            [self showPageControl];
            break;
        case 4:
            [self hidePageControl];
            break;
        default:
            break;
    }
}

- (void)hidePageControl
{
    self.pageControl.hidden = YES;
}

- (void)showPageControl
{
    self.pageControl.hidden = NO;
}

- (BOOL)areFieldsValid
{
    return [self areFieldsFilled] && [self isUrlValid];
}

- (BOOL)areFieldsFilled
{
    return [[self.usernameText.text trim] length] != 0 && [[self.passwordText.text trim] length] != 0 && [[self.siteUrlText.text trim] length] != 0;
}

- (BOOL)isUrlValid
{
    NSURL *siteURL = [NSURL URLWithString:self.siteUrlText.text];
    return siteURL != nil;
}

- (void)displayErrorMessages
{
    //TODO: Flesh out more
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"Fill out all fields" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

- (BOOL)isUrlWPCom
{
    NSRegularExpression *protocol = [NSRegularExpression regularExpressionWithPattern:@"wordpress\\.com/?$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *result = [protocol matchesInString:[self.siteUrlText.text trim] options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [[self.siteUrlText.text trim] length])];
    
    return [result count] != 0;
}

- (NSString *)getSiteUrl
{
    NSURL *siteURL = [NSURL URLWithString:self.siteUrlText.text];
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

#pragma mark - Alert View Delegate Related

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
        [webViewController setUsername:self.usernameText.text];
        [webViewController setPassword:self.passwordText.text];
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

- (void)showHelpViewController
{
    HelpViewController *helpViewController = [[HelpViewController alloc] init];
    helpViewController.isBlogSetup = YES;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController pushViewController:helpViewController animated:YES];
}

@end
