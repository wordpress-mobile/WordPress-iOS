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
- (void)controller:(WPComOAuthController *)controller didAuthenticateWithToken:(NSString *)token blog:(NSString *)blogUrl scope:(NSString *)scope;
@end

@interface WPComOAuthController : UIViewController<UIWebViewDelegate,NSURLConnectionDelegate>
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, weak) id<WPComOAuthDelegate> delegate;
@property (nonatomic, strong) NSString *clientId;
@property (nonatomic, strong) NSString *redirectUrl;
@property (nonatomic, strong) NSString *clientSecret;
@property (nonatomic, strong) NSString *blogId;
@property (nonatomic, strong) NSString *scope;

+ (void)presentWithClientId:(NSString *)clientId
                redirectUrl:(NSString *)redirectUrl
               clientSecret:(NSString *)clientSecret
                     blogId:(NSString *)blogId
                      scope:(NSString *)scope
                   delegate:(id<WPComOAuthDelegate>)delegate;

+ (void)presentWithClientId:(NSString *)clientId
                redirectUrl:(NSString *)redirectUrl
               clientSecret:(NSString *)clientSecret
                   delegate:(id<WPComOAuthDelegate>)delegate;
@end
