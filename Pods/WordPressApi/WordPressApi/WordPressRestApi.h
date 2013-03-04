//
//  WordPressRestApi.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WordPressBaseApi.h"

typedef NS_ENUM(NSUInteger, WordPressRestApiError) {
    WordPressRestApiErrorJSON,
    WordPressRestApiErrorNoAccessToken,
    WordPressRestApiErrorLoginFailed,
    WordPressRestApiErrorInvalidToken,
    WordPressRestApiErrorAuthorizationRequired,
};

extern NSString *const WordPressRestApiEndpointURL;
extern NSString *const WordPressRestApiErrorDomain;
extern NSString *const WordPressRestApiErrorCodeKey;

@interface WordPressRestApi : NSObject <WordPressBaseApi>

+ (void)signInWithOauthWithSuccess:(void (^)(NSString *authToken, NSString *siteId))success failure:(void (^)(NSError *error))failure;
+ (void)signInWithJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure;

- (id<WordPressBaseApi>)initWithOauthToken:(NSString *)authToken siteId:(NSString *)siteId;

/**
 Helper function for [UIApplicationDelegate application:handleOpenURL:] to process the authentication callback from the WordPress app

 @param url The url passed to [UIApplicationDelegate application:handleOpenURL:]
 @param success A block called if the url could be processed. The block has no return value and takes two arguments: the XML-RPC endpoint for the blog and the OAuth token. We highly recommend you store these in a secure place like the keychain.
 @returns YES if the url passed was a valid callback from authentication and it could be processed. Otherwise it returns NO.
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

+ (void)setWordPressComClient:(NSString *)clientId;
+ (void)setWordPressComSecret:(NSString *)secret;
+ (void)setWordPressComRedirectUrl:(NSString *)redirectUrl;

@end
