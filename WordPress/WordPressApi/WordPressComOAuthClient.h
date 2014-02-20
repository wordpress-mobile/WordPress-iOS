//
//  WordPressComOAuthClient.h
//  WordPress
//
//  Created by Jorge Bernal on 19/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "AFHTTPClient.h"

extern NSString * const WordPressComOAuthErrorDomain;
extern NSString * const WordPressComOAuthKeychainServiceName;

typedef NS_ENUM(NSUInteger, WordPressComOAuthError) {
    WordPressComOAuthErrorUnknown,
    WordPressComOAuthErrorInvalidClient,
    WordPressComOAuthErrorUnsupportedGrantType,
    WordPressComOAuthErrorInvalidRequest,
};

/**
 `WordPressComOAuthClient` encapsulates the pattern of authenticating against WordPress.com OAuth2 service.
 
 Right now it requires a special client id and secret, so this probably won't work for you
 
 @see https://developer.wordpress.com/docs/oauth2/
 */
@interface WordPressComOAuthClient : AFHTTPClient

+ (WordPressComOAuthClient *)client;

/**
 Authenticates on WordPress.com

 @param username the account's username.
 @param password the account's password.
 @param success block to be called if authentication was successful. The OAuth2 token is passed as a parameter.
 @param failure block to be called if authentication failed. The error object is passed as a parameter.
 */
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure;

@end
