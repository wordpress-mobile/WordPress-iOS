//
//  WPComOAuthController.m
//  WordPress
//
//  Created by Jorge Bernal on 1/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "WPComOAuthController.h"

NSString *const WPComOAuthBaseUrl = @"https://public-api.wordpress.com/oauth2";
NSString *const WPComOAuthLoginUrl = @"https://wordpress.com/wp-login.php";
NSString *const WPComOAuthErrorDomain = @"WPComOAuthError";

@interface WPComOAuthController () <UIWebViewDelegate,NSURLConnectionDelegate>
@property IBOutlet UIWebView *webView;
@end

@implementation WPComOAuthController {
    NSString *_clientId, *_redirectUrl, *_scope, *_blogId, *_secret;
    NSString *_username, *_password;
    BOOL _isSSO;
    void (^_completionBlock)(NSString *token, NSString *blogId, NSString *blogUrl, NSString *scope, NSError *error);
}

+ (WPComOAuthController *)sharedController {
    static WPComOAuthController *_sharedController = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedController = [[self alloc] init];
    });

    return _sharedController;
}

- (void)present {
    [self presentWithScope:nil blogId:nil];
}

- (void)presentWithScope:(NSString *)scope blogId:(NSString *)blogId {
    NSAssert(_clientId != nil, @"WordPress.com OAuth can't be presented without the client id. Use setClient: before presenting");
    NSAssert(_redirectUrl != nil, @"WordPress.com OAuth can't be presented without the redirect URL. Use setRedirectUrl: before presenting");
    _scope = scope;
    _blogId = blogId;

    if (![[self class] isThisTheWordPressApp] && [[self class] isWordPressAppAvailable] && !_username && !_password) {
        NSString *url = [NSString stringWithFormat:@"%@://authorize?client_id=%@&redirect_uri=%@", [[self class] wordpressAppURLScheme], _clientId, _redirectUrl];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else {
        [self presentMe];
    }
}

- (void)setWordPressComUsername:(NSString *)username {
    _username = username;
}

- (void)setWordPressComPassword:(NSString *)password {
    _password = password;
}

- (void)setClient:(NSString *)client {
    _clientId = client;
}

- (void)setRedirectUrl:(NSString *)redirectUrl {
    _redirectUrl = redirectUrl;
}

- (void)setSecret:(NSString *)secret {
    _secret = secret;
}

- (void)setCompletionBlock:(void (^)(NSString *token, NSString *blogId, NSString *blogUrl, NSString *scope, NSError *error))completionBlock {
    _completionBlock = completionBlock;
}

#pragma mark - View lifecycle

- (NSString *)nibName {
    return nil;
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:webView];
    self.webView = webView;
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *queryUrl = [NSString stringWithFormat:@"%@/authorize?client_id=%@&redirect_uri=%@&response_type=code", WPComOAuthBaseUrl, _clientId, _redirectUrl];
    if (_scope) {
        queryUrl = [queryUrl stringByAppendingFormat:@"&scope=%@", _scope];
    }
    if (_blogId) {
        queryUrl = [queryUrl stringByAppendingFormat:@"&blog_id=%@", _blogId];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:queryUrl]];
    NSString *userAgent = [self userAgent];
    if (userAgent) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    if (_username && _password) {
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [self stringByUrlEncodingString:_username],
                                  [self stringByUrlEncodingString:_password],
                                  [self stringByUrlEncodingString:queryUrl]];
        [request setURL:[NSURL URLWithString:WPComOAuthLoginUrl]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    }
    [self.webView loadRequest:request];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -

- (IBAction)cancel:(id)sender {
    [self dismissMe];

    if (_isSSO) {
        [self openCallbackWithQueryString:@"error=canceled"];
    } else {
        if (_completionBlock) {
            _completionBlock(nil, nil, nil, nil, nil);
        }
    }
}

- (void)presentMe {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController != nil) {
        presenter = presenter.presentedViewController;
    }
    [presenter presentViewController:navigation animated:YES completion:nil];
}

- (void)dismissMe {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)userAgent {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
}

- (NSMutableDictionary *)dictionaryFromQueryString:(NSString *)string {
    if (!self)
        return nil;

    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSArray *pairs = [string componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSRange separator = [pair rangeOfString:@"="];
        NSString *key, *value;
        if (separator.location != NSNotFound) {
            key = [pair substringToIndex:separator.location];
            value = [[pair substringFromIndex:separator.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            key = pair;
            value = @"";
        }

        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [result setObject:value forKey:key];
    }

    return result;
}

- (NSString *)stringByUrlEncodingString:(NSString *)string {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,  (CFStringRef)string,  NULL,  (CFStringRef)@"!*'();:@&=+$,/?%#[]",  kCFStringEncodingUTF8));
}


+ (NSString *)wordpressAppURLScheme{
	return @"wordpress-oauth-v2";
}

+ (BOOL)isWordPressAppAvailable {
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:[[self wordpressAppURLScheme] stringByAppendingString:@":"]]];
}

+ (BOOL)isThisTheWordPressApp {
    NSString *appIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    return [appIdentifier isEqualToString:@"org.wordpress"];
}

#pragma mark -

- (id)initForSSO {
    self = [super init];
    if (self) {
        _isSSO = YES;
    }
    return self;
}

- (void)getTokenWithCode:(NSString *)code secret:(NSString *)secret {
    NSAssert(secret != nil, @"WordPress.com OAuth can't be presented without the secret. Use setSecret: before presenting");
    NSString *tokenUrl = [NSString stringWithFormat:@"%@/token", WPComOAuthBaseUrl];
    __block NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:tokenUrl]];
    NSString *userAgent = [self userAgent];
    if (userAgent) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    NSString *request_body = [NSString stringWithFormat:@"client_id=%@&redirect_uri=%@&client_secret=%@&code=%@&grant_type=authorization_code",
                              _clientId,
                              _redirectUrl,
                              secret,
                              code];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSString *token = [response objectForKey:@"access_token"];
        NSString *blogUrl = [response objectForKey:@"blog_url"];
        NSString *blogId = [response objectForKey:@"blog_url"];
        NSString *scope = [response objectForKey:@"scope"];
        if (token && blogUrl) {
            [self dismissMe];

            if (_completionBlock) {
                _completionBlock(token, blogId, blogUrl, scope, nil);
            }
        } else if ([response objectForKey:@"error_description"]) {
            if (_completionBlock) {
                _completionBlock(nil, nil, nil, nil, [NSError errorWithDomain:WPComOAuthErrorDomain code:WPComOAuthErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: [response objectForKey:@"error_description"]}]);
            }
        } else {
            if (_completionBlock) {
                _completionBlock(nil, nil, nil, nil, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self cancel:nil];
    }];
    [self.webView loadHTMLString:@"Access granted, getting permament access..." baseURL:[NSURL URLWithString:WPComOAuthBaseUrl]];
    [operation start];
}

- (BOOL)handleOpenURL:(NSURL *)URL {
    if ([[URL scheme] isEqualToString:[[self class] wordpressAppURLScheme]] && [[URL host] isEqualToString:@"authorize"]) {
        NSDictionary *params = [self dictionaryFromQueryString:[URL query]];
        NSString *clientId = [params objectForKey:@"client_id"];
        NSString *redirectUrl = [params objectForKey:@"redirect_uri"];
        if (clientId && redirectUrl) {
            WPComOAuthController *ssoController = [[WPComOAuthController alloc] initForSSO];
            [ssoController setClient:clientId];
            [ssoController setRedirectUrl:redirectUrl];
            [ssoController present];
            return YES;
        }
    }

    if (![[self class] isThisTheWordPressApp] && [[URL scheme] hasPrefix:@"wordpress-"] && [[URL host] isEqualToString:@"wordpress-sso"]) {
        NSDictionary *params = [self dictionaryFromQueryString:[URL query]];
        NSString *code = [params objectForKey:@"code"];
        if (code) {
            [self getTokenWithCode:code secret:_secret];
        } else if ([params objectForKey:@"error_description"]) {
            if (_completionBlock) {
                _completionBlock(nil, nil, nil, nil, [NSError errorWithDomain:WPComOAuthErrorDomain code:WPComOAuthErrorCodeUnknown userInfo:@{NSLocalizedDescriptionKey: [params objectForKey:@"error_description"]}]);
            }
        } else {
            if (_completionBlock) {
                _completionBlock(nil, nil, nil, nil, nil);
            }
        }
        return YES;
    }
    return NO;
}

- (void)openCallbackWithQueryString:(NSString *)query {
    _isSSO = NO;
    NSString *callbackUrl = [NSString stringWithFormat:@"wordpress-%@://wordpress-sso?%@", _clientId, query];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callbackUrl]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"webView should load %@", [request URL]);
    NSURL *url = [request URL];
    if ([[url absoluteString] isEqualToString:@"about:blank"]) {
        return YES;
    }
    if ([[url absoluteString] hasPrefix:WPComOAuthBaseUrl] || [[url absoluteString] hasPrefix:WPComOAuthLoginUrl]) {
        NSLog(@"loading %@", url);
        return YES;
    } else if ([[url absoluteString] hasPrefix:_redirectUrl]) {
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
            if (_isSSO) {
                [self openCallbackWithQueryString:query];
            } else {
                [self getTokenWithCode:code secret:_secret];
            }
            [self dismissMe];
            return NO;
        } else {
            [self cancel:nil];
        }
    }
    return YES;
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
    // 102 is the error code when we refuse to load a request
    if (error.code != 102) {
        NSLog(@"webView failed loading %@: %@", aWebView.request.URL, [error localizedDescription]);
        [self cancel:nil];
    }
}

@end
