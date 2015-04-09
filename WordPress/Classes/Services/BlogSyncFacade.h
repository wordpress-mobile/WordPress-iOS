#import <Foundation/Foundation.h>

@class WPAccount;
@class Blog;

@protocol BlogSyncFacade

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)syncBlogForAccount:(WPAccount *)account username:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options needsJetpack:(void(^)(NSNumber *))needsJetpack finishedSync:(void(^)())finishedSync;

@end

@interface BlogSyncFacade : NSObject<BlogSyncFacade>

@end
