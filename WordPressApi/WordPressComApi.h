//
//  WordPressComApi.h
//  WordPress
//
//  Created by Jorge Bernal on 6/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WordPressApi.h"

#define WordPressComApiDidLoginNotification @"WordPressComApiDidLogin"
#define WordPressComApiDidLogoutNotification @"WordPressComApiDidLogout"

@interface WordPressComApi : WordPressApi
@property (nonatomic,readonly,strong) NSString *username;
@property (nonatomic,readonly,strong) NSString *password;

+ (WordPressComApi *)sharedApi;
- (void)setUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)signOut;
- (void)updateCredentailsFromStore;
@end
