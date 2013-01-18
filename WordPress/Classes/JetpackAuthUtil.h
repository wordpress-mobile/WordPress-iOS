//
//  JetpackAuthUtil.h
//  WordPress
//
//  Created by Eric Johnson on 8/22/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Blog;

@protocol JetpackAuthUtilDelegate;

@interface JetpackAuthUtil : NSObject <NSXMLParserDelegate> {
    id<JetpackAuthUtilDelegate> __weak delegate;
}

@property (nonatomic, weak) id<JetpackAuthUtilDelegate> delegate;

+ (NSString *)getJetpackUsernameForBlog:(Blog *)blog;
+ (NSString *)getJetpackPasswordForBlog:(Blog *)blog;
+ (NSString *)getWporgBlogJetpackKey:(NSString *)urlPath;
+ (void)setCredentialsForBlog:(Blog *)blog withUsername:(NSString *)username andPassword:(NSString *)password;

- (void)validateCredentialsForBlog:(Blog *)blog withUsername:(NSString *)aUsername andPassword:(NSString *)aPassword;

@end


@protocol JetpackAuthUtilDelegate <NSObject>

- (void)jetpackAuthUtil:(JetpackAuthUtil *)util didValidateCredentailsForBlog:(Blog *)blog;
- (void)jetpackAuthUtil:(JetpackAuthUtil *)util noRecordForBlog:(Blog *)blog; // good credentails but blog not found.
- (void)jetpackAuthUtil:(JetpackAuthUtil *)util errorValidatingCredentials:(Blog *)blog withError:(NSString *)errorMessage; // server or parse error.

@optional
- (void)jetpackAuthUtil:(JetpackAuthUtil *)util invalidBlog:(Blog *)blog;

@end
