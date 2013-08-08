//
//  CreateAccountAndBlogPage3ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage3ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"
#import "WPComLanguages.h"
#import "WPAsyncBlockOperation.h"
#import "WordPressComApi.h"
#import "NewWPWalkthroughOverlayView.h"

@interface CreateAccountAndBlogPage3ViewController () {
    NSString *_email;
    NSString *_username;
    NSString *_siteTitle;
    NSString *_siteAddress;
    NSString *_password;
    NSDictionary *_language;
    NSOperationQueue *_operationQueue;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *finalLineSeparator;
@property (nonatomic, strong) IBOutlet UILabel *emailConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *usernameConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteTitleConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteAddressConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteLanguageConfirmation;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *previousButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;

@end

@implementation CreateAccountAndBlogPage3ViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"Review your information", @"NUX Create Account Page 3 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.emailConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.usernameConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteTitleConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteAddressConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteLanguageConfirmation.font = [WPNUXUtility confirmationLabelFont];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.emailConfirmation.text = [NSString stringWithFormat:NSLocalizedString(@"Email: %@", @"NUX Create Account Page 3 Email Review Label"), _email];
    self.usernameConfirmation.text = [NSString stringWithFormat:NSLocalizedString(@"Username: %@", @"NUX Create Account Page 3 Username Review Label"), _username];
    self.siteTitleConfirmation.text = [NSString stringWithFormat:NSLocalizedString(@"Site Title: %@", @"NUX Create Account Page 3 Site Title Review Label"), _siteTitle];
    self.siteAddressConfirmation.text = [NSString stringWithFormat:NSLocalizedString(@"Site Address: %@", @"NUX Create Account Page 3 Site Address Review Label"), [NSString stringWithFormat:@"%@.wordpress.com", _siteAddress]];
    self.siteLanguageConfirmation.text = [NSString stringWithFormat:NSLocalizedString(@"Site Language: %@", @"NUX Create Account Page 3 Site Language Review Label"), [_language objectForKey:@"name"]];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.finalLineSeparator;
}

- (void)setEmail:(NSString *)email
{
    if (_email != email) {
        _email = email;
    }
}

- (void)setUsername:(NSString *)username
{
    if (_username != username) {
        _username = username;
    }
}

- (void)setSiteTitle:(NSString *)siteTitle
{
    if (_siteTitle != siteTitle) {
        _siteTitle = siteTitle;
    }
}

- (void)setSiteAddress:(NSString *)siteAddress
{
    if (_siteAddress != siteAddress) {
        _siteAddress = siteAddress;
    }
}

- (void)setLanguage:(NSDictionary *)language
{
    if (_language != language) {
        _language = language;
    }
}

- (void)setPassword:(NSString *)password
{
    if (_password != password) {
        _password = password;
    }
}


#pragma mark - IBAction Methods

- (IBAction)clickedNext:(id)sender
{
    [self createUserAndSite];
}

- (IBAction)clickedPrevious:(id)sender
{
    if (self.onClickedPrevious != nil) {
        self.onClickedPrevious();
    }
}

#pragma mark - Private Methods

- (void)createUserAndSite
{
    WPAsyncBlockOperation *userCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createUserSuccess)(id) = ^(id responseObject){
            [operation didSucceed];
        };
        void (^createUserFailure)(NSError *) = ^(NSError *error) {
            [operation didFail];
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] createWPComAccountWithEmail:_email
                                                     andUsername:_username
                                                     andPassword:_password
                                                         success:createUserSuccess
                                                         failure:createUserFailure];
        
    }];
    WPAsyncBlockOperation *userSignIn = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^signInSuccess)(void) = ^{
            [operation didSucceed];
        };
        void (^signInFailure)(NSError *) = ^(NSError *error) {
            // We've hit a strange failure at this point, the user has been created successfully but for some reason
            // we are unable to sign in and proceed
            [operation didFail];
            [SVProgressHUD dismiss];
            [self displayRemoteError:error];
        };
        
        [[WordPressComApi sharedApi] signInWithUsername:_username
                                               password:_password
                                                success:signInSuccess
                                                failure:signInFailure];
    }];
    
    WPAsyncBlockOperation *blogCreation = [WPAsyncBlockOperation operationWithBlock:^(WPAsyncBlockOperation *operation){
        void (^createBlogSuccess)(id) = ^(id responseObject){
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventNUXCreateAccountCreatedAccount];
            [operation didSucceed];
            [SVProgressHUD dismiss];
            if (self.onCreatedUser) {
                self.onCreatedUser(_username, _password);
            }
        };
        void (^createBlogFailure)(NSError *error) = ^(NSError *error) {
            [SVProgressHUD dismiss];
            [operation didFail];
            [self displayRemoteError:error];
        };
        
        NSNumber *languageId = [_language objectForKey:@"lang_id"];
        [[WordPressComApi sharedApi] createWPComBlogWithUrl:_siteAddress
                                               andBlogTitle:_siteTitle
                                              andLanguageId:languageId
                                          andBlogVisibility:WordPressComApiBlogVisibilityPublic
                                                    success:createBlogSuccess
                                                    failure:createBlogFailure];
        
    }];
    
    [blogCreation addDependency:userSignIn];
    [userSignIn addDependency:userCreation];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating User and Site", nil) maskType:SVProgressHUDMaskTypeBlack];
    
    [_operationQueue addOperation:userCreation];
    [_operationQueue addOperation:userSignIn];
    [_operationQueue addOperation:blogCreation];
}

- (void)displayRemoteError:(NSError *)error
{
    NSString *errorMessage = [error.userInfo objectForKey:WordPressComApiErrorMessageKey];
    [self showError:errorMessage];
}


- (void)showError:(NSString *)message
{
    NewWPWalkthroughOverlayView *overlayView = [[NewWPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
    overlayView.overlayMode = NewWPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    overlayView.overlayTitle = NSLocalizedString(@"Error", nil);
    overlayView.overlayDescription = message;
    overlayView.footerDescription = [NSLocalizedString(@"tap to dismiss", nil) uppercaseString];
    overlayView.singleTapCompletionBlock = ^(NewWPWalkthroughOverlayView *overlayView){
        [overlayView dismiss];
    };
    [self.view addSubview:overlayView];
}


@end
