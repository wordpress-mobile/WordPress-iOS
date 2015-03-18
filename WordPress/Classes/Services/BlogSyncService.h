//
//  BlogSyncService.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 3/18/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPAccount;
@class Blog;

@protocol BlogSyncService

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncBlogForAccount:(WPAccount *)account username:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options needsJetpack:(void(^)())needsJetpack finishedSync:(void(^)())finishedSync;

@end

@interface BlogSyncService : NSObject<BlogSyncService>

@end
