//
//  AccountCreationService.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/18/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPAccount;
@protocol AccountCreationService

- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken;

- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password;

- (void)updateEmailAndDefaultBlogForWordPressComAccount:(WPAccount *)account;

@end

@interface AccountCreationService : NSObject<AccountCreationService>

@end
