//
//  GeneralWalkthroughPage3ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <WPXMLRPC/WPXMLRPC.h>
#import "GeneralWalkthroughPage3ViewController.h"
#import "NewerAddUsersBlogViewController.h"
#import "LoginCompletedWalkthroughViewController.h"
#import "JetpackSettingsViewController.h"
#import "CreateAccountAndBlogViewController.h"
#import "NewLoginCompletedWalkthroughViewController.h"
#import "NewCreateAccountAndBlogViewController.h"
#import "ReachabilityUtils.h"
#import "WordPressComApi.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXUtility.h"
#import "NewWPWalkthroughOverlayView.h"
#import "WPWebViewController.h"
#import "HelpViewController.h"
#import "WPAccount.h"
#import "Blog.h"
#import "Blog+Jetpack.h"

@interface GeneralWalkthroughPage3ViewController () <UITextFieldDelegate> {
    CGFloat _keyboardOffset;
    NSString *_dotComSiteUrl;
    BOOL _userIsDotCom;
    BOOL _blogConnectedToJetpack;
    NSArray *_blogs;
    Blog *_blog;
    NSString *_presetUsername;
    NSString *_presetPassword;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *usernameText;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *passwordText;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *siteAddress;
@property (nonatomic, strong) IBOutlet WPNUXMainButton *signInButton;

@end

@implementation GeneralWalkthroughPage3ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    
    self.usernameText.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 3 Username Placeholder");
    self.usernameText.font = [WPNUXUtility textFieldFont];
    self.usernameText.delegate = self;

    self.passwordText.placeholder = NSLocalizedString(@"Password", nil);
    self.passwordText.font = [WPNUXUtility textFieldFont];
    self.passwordText.delegate = self;
    
    self.siteAddress.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 3 Site Address Placeholder");
    self.siteAddress.font = [WPNUXUtility textFieldFont];
    self.siteAddress.delegate = self;
    
    [self.signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    
    if (!IS_IPAD) {
        // We don't need to shift the controls up on the iPad as there's enough space.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    [self hideKeyboardOnTap];
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughOpened];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.siteAddress;
}

- (void)setUsername:(NSString *)username
{
    self.usernameText.text = username;
}

- (void)setPassword:(NSString *)password
{
    self.passwordText.text = password;
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameText) {
        [self.passwordText becomeFirstResponder];
    } else if (textField == self.passwordText) {
        [self.siteAddress becomeFirstResponder];
    } else if (textField == self.siteAddress) {
        if (self.signInButton.enabled) {
            [self clickedSignIn:nil];
        }
    }
    
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    self.signInButton.enabled = [self areDotComFieldsFilled];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL isUsernameFilled = [self isUsernameFilled];
    BOOL isPasswordFilled = [self isPasswordFilled];
    
    NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
    [updatedString replaceCharactersInRange:range withString:string];
    BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
    if (textField == self.usernameText) {
        isUsernameFilled = updatedStringHasContent;
    } else if (textField == self.passwordText) {
        isPasswordFilled = updatedStringHasContent;
    }
    self.signInButton.enabled = isUsernameFilled && isPasswordFilled;
    
    return YES;
}

#pragma mark - Keyboard Related Methods

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardOffset = (CGRectGetMaxY(self.signInButton.frame) - CGRectGetMinY(keyboardFrame)) + CGRectGetHeight(self.signInButton.frame);
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.verticalCenteringConstraint.constant -= _keyboardOffset;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = notification.userInfo;
    CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:animationDuration animations:^{
        self.verticalCenteringConstraint.constant += _keyboardOffset;
        [self.view layoutIfNeeded];
    }];
}

- (void)hideKeyboardOnTap
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBackground:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
}

#pragma mark - Displaying of Error Messages

- (NewWPWalkthroughOverlayView *)baseLoginErrorOverlayView:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [[NewWPWalkthroughOverlayView alloc] initWithFrame:self.containingView.bounds];
    overlayView.overlayMode = NewWPWalkthroughGrayOverlayViewOverlayModeTwoButtonMode;
    overlayView.overlayTitle = NSLocalizedString(@"Sorry, we can't log you in.", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    overlayView.leftButtonText = NSLocalizedString(@"Need Help?", nil);
    overlayView.rightButtonText = NSLocalizedString(@"OK", nil);
    overlayView.singleTapCompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    return overlayView;
}

- (void)displayErrorMessageForXMLRPC:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.rightButtonText = NSLocalizedString(@"Enable Now", nil);
    overlayView.button1CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedEnableXMLRPCServices];
        
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
        [webViewController setUsername:self.usernameText.text];
        [webViewController setPassword:self.passwordText.text];
        webViewController.shouldScrollToBottom = YES;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    overlayView.frame = self.containingView.bounds;
    [self.containingView addSubview:overlayView];
}

- (void)displayErrorMessageForBadUrl:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        webViewController.url = [NSURL URLWithString:@"http://ios.wordpress.org/faq/#faq_3"];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController pushViewController:webViewController animated:NO];
    };
    overlayView.button2CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    overlayView.frame = self.containingView.bounds;
    [self.containingView addSubview:overlayView];
}

- (void)displayGenericErrorMessage:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [self baseLoginErrorOverlayView:message];
    overlayView.button1CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughClickedNeededHelpOnError properties:@{@"error_message": message}];
        
        [overlayView dismiss];
        [self showHelpViewController:NO];
    };
    overlayView.button2CompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    overlayView.frame = self.containingView.bounds;
    [self.containingView addSubview:overlayView];
}

#pragma mark - Button Press Methods


#pragma mark - Private Methods

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
    NSURL *siteURL = [NSURL URLWithString:self.siteAddress.text];
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
    return [[self.usernameText.text trim] length] != 0;
}

- (BOOL)isPasswordFilled
{
    return [[self.passwordText.text trim] length] != 0;
}

- (BOOL)areDotComFieldsFilled
{
    return [self isUsernameFilled] && [self isPasswordFilled];
}

- (BOOL)areSelfHostedFieldsFilled
{
    return [self areDotComFieldsFilled] && [[self.siteAddress.text trim] length] != 0;
}

- (BOOL)hasUserOnlyEnteredValuesForDotCom
{
    return [self areDotComFieldsFilled] && ![self areSelfHostedFieldsFilled];
}

- (BOOL)areFieldsFilled
{
    return [[self.usernameText.text trim] length] != 0 && [[self.passwordText.text trim] length] != 0 && [[self.siteAddress.text trim] length] != 0;
}

- (BOOL)isUrlValid
{
    NSURL *siteURL = [NSURL URLWithString:self.siteAddress.text];
    return siteURL != nil;
}

- (void)displayErrorMessages
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)clickedBackground:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}

- (IBAction)clickedSignIn:(id)sender
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

- (void)signIn
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Authenticating", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    NSString *username = self.usernameText.text;
    NSString *password = self.passwordText.text;
    _dotComSiteUrl = nil;
    
    if ([self hasUserOnlyEnteredValuesForDotCom]) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithoutUrl];
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }
    
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInWithUrl];
    
    if ([self isUrlWPCom:self.siteAddress.text]) {
        [self signInForWPComForUsername:username andPassword:password];
        return;
    }
    
    void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
        WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];
        
        [api getBlogOptionsWithSuccess:^(id options){
            [SVProgressHUD dismiss];
            
            if ([options objectForKey:@"wordpress.com"] != nil) {
                NSDictionary *siteUrl = [options dictionaryForKey:@"home_url"];
                _dotComSiteUrl = [siteUrl objectForKey:@"value"];
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
    
    [WordPressXMLRPCApi guessXMLRPCURLForSite:self.siteAddress.text success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
}

- (void)signInForWPComForUsername:(NSString *)username andPassword:(NSString *)password
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForDotCom];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to WordPress.com", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    void (^loginSuccessBlock)(void) = ^{
        [SVProgressHUD dismiss];
        _userIsDotCom = YES;
        [self showAddUsersBlogsForWPCom];
    };
    
    void (^loginFailBlock)(NSError *) = ^(NSError *error){
        // User shouldn't get here because the getOptions call should fail, but in the unlikely case they do throw up an error message.
        [SVProgressHUD dismiss];
        DDLogError(@"Login failed with username %@ : %@", username, error);
        [self displayGenericErrorMessage:NSLocalizedString(@"Please update your credentials and try again.", nil)];
    };
    
    [[WordPressComApi sharedApi] signInWithUsername:username
                                           password:password
                                            success:loginSuccessBlock
                                            failure:loginFailBlock];
    
}

- (void)signInForSelfHostedForUsername:(NSString *)username password:(NSString *)password options:(NSDictionary *)options andApi:(WordPressXMLRPCApi *)api
{
    [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughSignedInForSelfHosted];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", nil) maskType:SVProgressHUDMaskTypeBlack];
    
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

- (NewerAddUsersBlogViewController *)addUsersBlogViewController:(NSString *)xmlRPCUrl
{
    BOOL isWPCom = (xmlRPCUrl == nil);
    NewerAddUsersBlogViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AddBlogs"];
    vc.account = [self createAccountWithUsername:self.usernameText.text andPassword:self.passwordText.text isWPCom:isWPCom xmlRPCUrl:xmlRPCUrl];
    vc.blogAdditionCompleted = ^(NewerAddUsersBlogViewController * viewController){
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onNoBlogsLoaded = ^(NewerAddUsersBlogViewController *viewController) {
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    };
    vc.onErrorLoading = ^(NewerAddUsersBlogViewController *viewController, NSError *error) {
        DDLogError(@"There was an error loading blogs after sign in");
        [self.navigationController popViewControllerAnimated:YES];
        [self displayGenericErrorMessage:[error localizedDescription]];
    };
    
    return vc;
}

- (void)showAddUsersBlogsForSelfHosted:(NSString *)xmlRPCUrl
{
    NewerAddUsersBlogViewController *vc = [self addUsersBlogViewController:xmlRPCUrl];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAddUsersBlogsForWPCom
{
    NewerAddUsersBlogViewController *vc = [self addUsersBlogViewController:nil];
    
    NSString *siteUrl = [self.siteAddress.text trim];
    if ([siteUrl length] != 0) {
        vc.siteUrl = siteUrl;
    } else if ([_dotComSiteUrl length] != 0) {
        vc.siteUrl = _dotComSiteUrl;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlRPCUrl andBlogDetails:(NSDictionary *)blogDetails
{
    NSParameterAssert(blogDetails != nil);
    
    WPAccount *account = [self createAccountWithUsername:self.usernameText.text andPassword:self.passwordText.text isWPCom:NO xmlRPCUrl:xmlRPCUrl];
    
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:xmlRPCUrl forKey:@"xmlrpc"];
    
    _blog = [account findOrCreateBlogFromDictionary:newBlog withContext:account.managedObjectContext];
    [_blog dataSave];
    
}

- (WPAccount *)createAccountWithUsername:(NSString *)username andPassword:(NSString *)password isWPCom:(BOOL)isWPCom xmlRPCUrl:(NSString *)xmlRPCUrl {
    WPAccount *account;
    if (isWPCom) {
        account = [WPAccount createOrUpdateWordPressComAccountWithUsername:username andPassword:password];
    } else {
        account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlRPCUrl username:username andPassword:password];
    }
    return account;
}

- (void)synchronizeNewlyAddedBlog
{
    [SVProgressHUD setStatus:NSLocalizedString(@"Synchronizing Blog", nil)];
    void (^successBlock)() = ^{
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
        [SVProgressHUD dismiss];
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack];
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

- (void)showCompletionWalkthrough
{
    NewLoginCompletedWalkthroughViewController *loginCompletedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginCompleted"];
    loginCompletedViewController.showsExtraWalkthroughPages = _userIsDotCom || _blogConnectedToJetpack;
    [self.navigationController pushViewController:loginCompletedViewController animated:YES];
}

- (void)showCreateAccountView
{
    NewCreateAccountAndBlogViewController *createAccountViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateAccount"];
    createAccountViewController.onCreatedUser = ^(NSString *username, NSString *password) {
        self.usernameText.text = username;
        self.passwordText.text = password;
        _userIsDotCom = YES;
        [self.navigationController popViewControllerAnimated:NO];
        [self showAddUsersBlogsForWPCom];
    };
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)showJetpackAuthentication
{
    [SVProgressHUD dismiss];
    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:_blog];
    jetpackSettingsViewController.canBeSkipped = YES;
    [jetpackSettingsViewController setCompletionBlock:^(BOOL didAuthenticate) {
        _blogConnectedToJetpack = didAuthenticate;
        
        if (_blogConnectedToJetpack) {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserConnectedToJetpack];
        } else {
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXFirstWalkthroughUserSkippedConnectingToJetpack];
        }
        
        [self.navigationController popViewControllerAnimated:NO];
        [self showCompletionWalkthrough];
    }];
    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}


@end
