//
//  WPFriendFinderViewController.m
//  WordPress
//
//  Created by Beau Collins on 5/31/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "WPFriendFinderViewController.h"
#import "JSONKit.h"
#import "WordPressAppDelegate.h"
#import "UIBarButtonItem+Styled.h"
#import "ReachabilityUtils.h"

typedef void (^DismissBlock)(int buttonIndex);
typedef void (^CancelBlock)();


@interface WPFriendFinderViewController () <UIAlertViewDelegate>

@property (nonatomic, copy) DismissBlock dismissBlock;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

- (void)findEmails;
- (void)findTwitterFriends;
- (void)findFacebookFriends;
- (void)facebookDidLogIn:(NSNotification *)notification;
- (void)facebookDidNotLogIn:(NSNotification *)notification;
- (void)dismissFriendFinder:(id)sender;
- (UIAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle confirmButtonTitle:(NSString *)confirmButtonTitle dismissBlock:(DismissBlock)dismiss;
@end

@implementation WPFriendFinderViewController

@synthesize dismissBlock;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // register for a notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(facebookDidLogIn:) name:kFacebookLoginNotificationName object:nil];
    [nc addObserver:self selector:@selector(facebookDidNotLogIn:) name:kFacebookNoLoginNotificationName object:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:[WPStyleGuide barButtonStyleForDone]
                                                                                           target:self 
                                                                                           action:@selector(dismissFriendFinder:)];
    if (!IS_IOS7) {
        [UIBarButtonItem styleButtonAsPrimary:self.navigationItem.rightBarButtonItem];        
    }
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    CGRect f1 = self.activityView.frame;
    CGRect f2 = self.view.frame;
    f1.origin.x = (f2.size.width / 2.0f) - (f1.size.width / 2.0f);
    f1.origin.y = (f2.size.height / 2.0f) - (f1.size.height / 2.0f);
    self.activityView.frame = f1;
    
    [self.view addSubview:self.activityView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // remove notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.dismissBlock = nil;
    self.activityView = nil;
}

- (void)dismissFriendFinder:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)configureFriendFinder:(id)config
{
    NSDictionary *settings = (NSDictionary *)config;
    NSArray *sources = (NSArray *)[settings objectForKey:@"sources"];
    
    NSMutableArray *available = [NSMutableArray arrayWithObjects:@"address-book", @"facebook", nil];
    
    if ([sources containsObject:@"twitter"]){
        [available addObject:@"twitter"];
    }
    
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.enableSources(%@)", [available JSONString]]];
}

- (void)authorizeSource:(NSString *)source
{
    // time to load up the addressbook folks!
    if ([source isEqualToString:@"address-book"]) {
        [self findEmails];
    } else if ([source isEqualToString:@"twitter"]) {
        [self findTwitterFriends];
    } else if ([source isEqualToString:@"facebook"]){
        [self findFacebookFriends];
    }
    
}

- (void) findEmails
{
    
    // aplication name
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *title = [NSString stringWithFormat:@"“%@” %@", appName, NSLocalizedString(@"Would Like Access to Address Book", @"")];
    NSString *message = NSLocalizedString(@"Your contacts will be transmitted securely and will not be stored on our servers.", @"");
    
    [self alertWithTitle:title
                 message:message
       cancelButtonTitle:NSLocalizedString(@"Don't Allow", @"")
      confirmButtonTitle:NSLocalizedString(@"OK", @"")
            dismissBlock:^(int buttonIndex) {
                
                if (1 == buttonIndex) {
                    ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, NULL);
                    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(address_book);
                    CFIndex count = CFArrayGetCount(people);
                    
                    NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:count];
                    
                    for (CFIndex i = 0; i<count; i++) {
                        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
                        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
                        for (CFIndex j = 0; j<ABMultiValueGetCount(emails); j++) {
                            NSString *email = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, j));
                            [addresses addObject:email];
                        }
                        CFRelease(emails);
                    }
                    CFRelease(people);
                    CFRelease(address_book);
                    
                    // pipe this addresses into the webview
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.findByEmail(%@)", [addresses JSONString]]];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.webView stringByEvaluatingJavaScriptFromString:@"FriendFinder.findByEmail()"];
                    });

                }
                
            }];
    
    return;
    

}

- (void) findTwitterFriends 
{
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = 
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [store requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
        
        if (granted) {
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"true", @"stringify_ids",
                                    @"-1", @"cursor",
                                    nil];
            
            NSURL *followingURL = [NSURL URLWithString:@"http://api.twitter.com/1/friends/ids.json"];
            NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
            [twitterAccounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ACAccount *account = (ACAccount *)obj;
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                        requestMethod:SLRequestMethodGET
                                                                  URL:followingURL
                                                           parameters:params];
                request.account = account;
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    NSString *responseJSON = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.findByTwitterID(%@, '%@')", responseJSON, account.accountDescription]];
                    });
                }];
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView stringByEvaluatingJavaScriptFromString:@"FriendFinder.findByTwitterID()"];
            });
        }
        
    }];
    
    
}

- (void)facebookDidLogIn:(NSNotification *)notification
{
    [self findFacebookFriends];
}

- (void)facebookDidNotLogIn:(NSNotification *)notification
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"FriendFinder.findByFacebookID()"];
}

- (void) findFacebookFriends
{
    ACAccountStore *store = [[ACAccountStore alloc] init];

    NSDictionary *options = @{
                              ACFacebookAppIdKey: kFacebookAppID,
                              ACFacebookPermissionsKey: @[]
                              };
    [store requestAccessToAccountsWithType:[store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] options:options completion:^(BOOL granted, NSError *error) {
        if (granted) {
            NSArray *facebookAccounts = [store accountsWithAccountType:[store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook]];
            [facebookAccounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ACAccount *account = (ACAccount *)obj;
                NSURL *friendsURL = [NSURL URLWithString:@"https://graph.facebook.com/me/friends"];
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                        requestMethod:SLRequestMethodGET
                                                                  URL:friendsURL
                                                           parameters:nil];
                request.account = account;
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    NSDictionary *response = [responseData objectFromJSONData];
                    if (response && [response isKindOfClass:[NSDictionary class]]) {
                        NSArray *friends = response[@"data"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.findByFacebookID(%@)", [friends JSONString]]];
                        });
                    }
                }];
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView stringByEvaluatingJavaScriptFromString:@"FriendFinder.findByFacebookID()"];
            });
        }
    }];
}

- (UIAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle confirmButtonTitle:(NSString *)confirmButtonTitle dismissBlock:(DismissBlock)dismiss
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey:kAccessedAddressBookPreference] == YES){
        dismiss(1);
        return nil;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:confirmButtonTitle, nil];
        
        self.dismissBlock = dismiss;
        [alertView show];
        return alertView;

    }

}

#pragma mark - UIAlertView Delegate Methods

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kAccessedAddressBookPreference];
        [defaults synchronize];
    }
    if (self.dismissBlock) {
        self.dismissBlock(buttonIndex);
    }
}

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView
{
    if (self.dismissBlock) {
        self.dismissBlock(-1);
    }
}

#pragma mark - UIWebView Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([[[webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML.length"] numericValue] integerValue] == 0) {
        [self.activityView startAnimating];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityView stopAnimating];
}

@end
