//
//  WPComOAuthController.h
//  WordPress
//
//  Created by Jorge Bernal on 1/15/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

@class WPComOAuthController;

@protocol WPComOAuthDelegate <NSObject>
- (void)controllerDidCancel:(WPComOAuthController *)controller;
- (void)controller:(WPComOAuthController *)controller didAuthenticateWithToken:(NSString *)token blog:(NSString *)blogUrl;
@end

@interface WPComOAuthController : UIViewController<UIWebViewDelegate,NSURLConnectionDelegate>
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, assign) id<WPComOAuthDelegate> delegate;
@property (nonatomic, retain) NSString *clientId;
@property (nonatomic, retain) NSString *redirectUrl;
@property (nonatomic, retain) NSString *clientSecret;

+ (void)presentWithClientId:(NSString *)clientId redirectUrl:(NSString *)redirectUrl clientSecret:(NSString *)clientSecret delegate:(id<WPComOAuthDelegate>)delegate;
@end
