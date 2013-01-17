//
//  WPComOAuthController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPComOAuthController.h"
#import "WordPressAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "AFHTTPRequestOperation.h"
#import "JSONKit.h"

#define OAUTH_BASE_URL @"https://public-api.wordpress.com/oauth2"
#define WPCOM_LOGIN_URL @"https://wordpress.com/wp-login.php"

@implementation WPComOAuthController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];

    NSError *error = nil;
    NSString *wpcom_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    NSString *wpcom_password = [SFHFKeychainUtils getPasswordForUsername:wpcom_username
                                                          andServiceName:@"WordPress.com"
                                                                   error:&error];

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    NSString *queryUrl = [NSString stringWithFormat:@"%@/authorize?client_id=%@&redirect_uri=%@&response_type=code&scope=%@", OAUTH_BASE_URL, self.clientId, self.redirectUrl, self.scope];
    if (self.blogId != nil) {
        queryUrl = [queryUrl stringByAppendingFormat:@"&blog_id=%@", self.blogId];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:queryUrl]];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    if (wpcom_username && wpcom_password) {
        queryUrl = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                       NULL,
                                                                       (CFStringRef)queryUrl,
                                                                       NULL,
                                                                       (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                       kCFStringEncodingUTF8 ));
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [wpcom_username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [wpcom_password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  queryUrl];
        NSLog(@"request_body: %@", request_body);
        [request setURL:[NSURL URLWithString:WPCOM_LOGIN_URL]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    }
    [self.webView loadRequest:request];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -

- (IBAction)cancel:(id)sender {
    UIWindow *window = [[WordPressAppDelegate sharedWordPressApplicationDelegate] window];
    [window.rootViewController dismissModalViewControllerAnimated:YES];

    if (self.delegate && [self.delegate respondsToSelector:@selector(controllerDidCancel:)]) {
        [self.delegate controllerDidCancel:self];
    }
}

- (void)getTokenForAuthCode:(NSString *)code {
    NSString *tokenUrl = [NSString stringWithFormat:@"%@/token", OAUTH_BASE_URL];
    __block NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:tokenUrl]];
    [request setValue:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSString *request_body = [NSString stringWithFormat:@"client_id=%@&redirect_uri=%@&client_secret=%@&code=%@&grant_type=authorization_code",
                              self.clientId,
                              self.redirectUrl,
                              self.clientSecret,
                              code];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseString = operation.responseString;
        NSDictionary *response = (NSDictionary *)[responseString objectFromJSONString];
        NSString *token = [response objectForKey:@"access_token"];
        NSString *blogUrl = [response objectForKey:@"blog_url"];
        NSString *scope = [response objectForKey:@"scope"];
        if (token && blogUrl) {
            UIWindow *window = [[WordPressAppDelegate sharedWordPressApplicationDelegate] window];
            [window.rootViewController dismissModalViewControllerAnimated:YES];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(controller:didAuthenticateWithToken:blog:scope:)]) {
                [self.delegate controller:self didAuthenticateWithToken:token blog:blogUrl scope:scope];
            }
        } else {
            [self cancel:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self cancel:nil];
    }];
    [self.webView loadHTMLString:@"Access granted, getting permament access..." baseURL:[NSURL URLWithString:OAUTH_BASE_URL]];
    [operation start];
}

+ (void)presentWithClientId:(NSString *)clientId redirectUrl:(NSString *)redirectUrl clientSecret:(NSString *)clientSecret blogId:(NSString *)blogId scope:(NSString *)scope delegate:(id<WPComOAuthDelegate>)delegate {
    WPComOAuthController *controller = [[WPComOAuthController alloc] init];
    controller.clientId = clientId;
    controller.redirectUrl = redirectUrl;
    controller.delegate = delegate;
    controller.clientSecret = clientSecret;
    controller.scope = scope;
    controller.blogId = blogId;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    UIWindow *window = [[WordPressAppDelegate sharedWordPressApplicationDelegate] window];
    if (IS_IPAD) {
        navigation.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [window.rootViewController presentModalViewController:navigation animated:YES];

}

+ (void)presentWithClientId:(NSString *)clientId redirectUrl:(NSString *)redirectUrl clientSecret:(NSString *)clientSecret delegate:(id<WPComOAuthDelegate>)delegate {
    [self presentWithClientId:clientId redirectUrl:redirectUrl clientSecret:clientSecret blogId:nil scope:nil delegate:delegate];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"webView should load %@", [request URL]);
    NSURL *url = [request URL];
    if ([[url absoluteString] hasPrefix:OAUTH_BASE_URL] || [[url absoluteString] hasPrefix:WPCOM_LOGIN_URL]) {
        NSLog(@"loading %@", url);
        return YES;
    } else if ([[url absoluteString] hasPrefix:self.redirectUrl]) {
        NSLog(@"found redirect URL");
        NSString *query = [url query];
        NSArray *parameters = [query componentsSeparatedByString:@"&"];
        NSString *code = nil;
        for (NSString *parameter in parameters) {
            if ([parameter hasPrefix:@"code="]) {
                code = [[parameter componentsSeparatedByString:@"="] lastObject];
                NSLog(@"found code: %@", code);
                break;
            }
        }
        if (code) {
            [self getTokenForAuthCode:code];
            return NO;
        } else {
            [self cancel:nil];
        }
    }
    return NO;
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
    // 102 is the error code when we refuse to load a request
    if (error.code != 102) {
        NSLog(@"webView failed loading %@: %@", aWebView.request.URL, [error localizedDescription]);
        [self cancel:nil];
    }
}

@end
