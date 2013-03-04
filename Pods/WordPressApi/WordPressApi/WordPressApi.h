//
//  WordPressApi.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef _WORDPRESSAPI
#define _WORDPRESSAPI
#import "WPXMLRPCClient.h"
#import "WPXMLRPCRequest.h"
#import "WPXMLRPCRequestOperation.h"
#import "WordPressBaseApi.h"
#import "WordPressRestApi.h"
#import "WordPressXMLRPCApi.h"
#import "WPComOAuthController.h"
#endif /* _WORDPRESSAPI */

@interface WordPressApi : NSObject
+ (void)signInWithURL:(NSString *)url username:(NSString *)username password:(NSString *)password success:(void (^)(NSURL *xmlrpcURL))success failure:(void (^)(NSError *error))failure;

+ (void)signInWithXMLRPCURL:(NSURL *)xmlrpcURL username:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure;
+ (id<WordPressBaseApi>)apiWithXMLRPCURL:(NSURL *)xmlrpcURL username:(NSString *)username password:(NSString *)password;

+ (void)signInWithOauthWithSuccess:(void (^)(NSString *authToken, NSString *siteId))success failure:(void (^)(NSError *error))failure;
+ (id<WordPressBaseApi>)apiWithOauthToken:(NSString *)authToken siteId:(NSString *)siteId;

+ (void)signInWithJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure;

+ (void)setWordPressComClient:(NSString *)clientId;
+ (void)setWordPressComSecret:(NSString *)secret;
+ (void)setWordPressComRedirectUrl:(NSString *)redirectUrl;
+ (BOOL)handleOpenURL:(NSURL *)URL;

@end
