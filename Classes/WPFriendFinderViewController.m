//
//  WPFriendFinderViewController.m
//  WordPress
//
//  Created by Beau Collins on 5/31/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "Facebook.h"
#import "WPFriendFinderViewController.h"
#import "JSONKit.h"
#import "WordPressAppDelegate.h"

@interface WPFriendFinderViewController ()
- (void)findEmails;
- (void)findTwitterFollowers;
- (void)findFacebookFriends;
- (void)facebookDidLogIn:(NSNotification *)notification;

@end

@implementation WPFriendFinderViewController

- (void)viewDidLoad
{
    // register for a notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookDidLogIn:) name:kFacebookLoginNotificationName object:nil];
}

- (void)viewDidUnload
{
    // remove notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Who is the delegate?: %@", self.webView.delegate);
    [super viewWillAppear:animated];
}

- (void)authorizeSource:(NSString *)source
{
    NSLog(@"Authorize source: %@", source);
    // time to load up the addressbook folks!
    if ([source isEqualToString:@"address-book"]) {
        [self findEmails];
    } else if ([source isEqualToString:@"twitter"]) {
        [self findTwitterFollowers];
    } else if ([source isEqualToString:@"facebook"]){
        [self findFacebookFriends];
    }
    
}

- (void) findEmails
{
    
    ABAddressBookRef address_book = ABAddressBookCreate();
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(address_book);
    CFIndex count = CFArrayGetCount(people);
    
    NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:count];
    
    for (CFIndex i = 0; i<count; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        for (CFIndex j = 0; j<ABMultiValueGetCount(emails); j++) {
            NSString *email = (NSString *)ABMultiValueCopyValueAtIndex(emails, j);
            [addresses addObject:email];
            [email release];
        }
        CFRelease(emails);
    }
    CFRelease(people);
    CFRelease(address_book);
        
    // pipe this addresses into the webview
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.findByEmail(%@)", [addresses JSONString]]];

}

- (void) findTwitterFollowers 
{
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = 
    [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [store requestAccessToAccountsWithType:twitterAccountType withCompletionHandler:^(BOOL granted, NSError *error) {
        
        if (granted) {
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"true", @"stringify_ids",
                                    @"-1", @"cursor",
                                    nil];
            
            NSURL *followersURL = [NSURL URLWithString:@"http://api.twitter.com/1/followers/ids.json"];
            NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
            ACAccount *account = (ACAccount *)[twitterAccounts objectAtIndex:0];
            TWRequest *request = [[[TWRequest alloc] initWithURL:followersURL
                                                      parameters:params
                                                   requestMethod:TWRequestMethodGET] autorelease];
            request.account = account;
            
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSString *responseJSON = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"FriendFinder.findByTwitterID(%@)", responseJSON]];
                });
            }];
        } else {
            [self.webView stringByEvaluatingJavaScriptFromString:@"FriendFinder.findByTwitterID(false)"];
        }
        
        
        
    }];
    
    [store release];
    
}

- (void)facebookDidLogIn:(NSNotification *)notification
{
    NSLog(@"Facebook logged in");
    [self findFacebookFriends];
}

- (void) findFacebookFriends
{
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    Facebook *facebook = appDelegate.facebook;
    
    if ([facebook isSessionValid]) {
        // find us some people
        NSLog(@"Valid session!");
                
        [facebook requestWithGraphPath:@"/me/friends" andDelegate:self];
        

    } else {
        // authorize
        [facebook authorize:nil];
    }
    
}

/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(FBRequest *)request
{
    
}

/**
 * Called when the Facebook API request has returned a response.
 *
 * This callback gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    
}

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Failed with error: %@", [error localizedDescription]);
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    Facebook *facebook = appDelegate.facebook;
    [facebook authorize:nil];
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array or a string, depending
 * on the format of the API response. If you need access to the raw response,
 * use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result
{
    NSArray *friends = (NSArray *)[result objectForKey:@"data"];
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"FriendFinder.findByFacebookID(%@)", [friends JSONString]]];
}

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data
{
}


@end
