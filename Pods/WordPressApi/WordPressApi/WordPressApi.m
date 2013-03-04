//
//  WordPressApi.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import "WordPressApi.h"
#import "WordPressXMLRPCApi.h"
#import "WordPressRestApi.h"

@implementation WordPressApi

+ (void)signInWithURL:(NSString *)url username:(NSString *)username password:(NSString *)password success:(void (^)(NSURL *xmlrpcURL))success failure:(void (^)(NSError *error))failure {
    [WordPressXMLRPCApi guessXMLRPCURLForSite:url success:^(NSURL *xmlrpcURL) {
        [self signInWithXMLRPCURL:xmlrpcURL username:username password:password success:^{
            if (success) {
                success(xmlrpcURL);
            }
        } failure:failure];
    } failure:failure];
}

+ (void)signInWithXMLRPCURL:(NSURL *)xmlrpcURL username:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure {
    WordPressXMLRPCApi *api = [self apiWithXMLRPCURL:xmlrpcURL username:username password:password];
    [api authenticateWithSuccess:success failure:failure];
}

+ (id<WordPressBaseApi>)apiWithXMLRPCURL:(NSURL *)xmlrpcURL username:(NSString *)username password:(NSString *)password {
    return [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlrpcURL username:username password:password];
}

+ (void)signInWithOauthWithSuccess:(void (^)(NSString *authToken, NSString *siteId))success failure:(void (^)(NSError *error))failure {
    [WordPressRestApi signInWithOauthWithSuccess:success failure:failure];
}

+ (id<WordPressBaseApi>)apiWithOauthToken:(NSString *)authToken siteId:(NSString *)siteId {
    return [[WordPressRestApi alloc] initWithOauthToken:authToken siteId:siteId];
}

+ (void)signInWithJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure {
    [WordPressRestApi signInWithJetpackUsername:username password:password success:success failure:failure];
}

+ (void)setWordPressComClient:(NSString *)clientId {
    [WordPressRestApi setWordPressComClient:clientId];
}

+ (void)setWordPressComSecret:(NSString *)secret {
    [WordPressRestApi setWordPressComSecret:secret];
}

+ (void)setWordPressComRedirectUrl:(NSString *)redirectUrl {
    [WordPressRestApi setWordPressComRedirectUrl:redirectUrl];
}

+ (BOOL)handleOpenURL:(NSURL *)URL {
    return [WordPressRestApi handleOpenURL:URL];
}

@end
