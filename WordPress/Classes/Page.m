#import "Page.h"
#import "NSMutableDictionary+Helpers.h"

@interface AbstractPost (WordPressApi)
- (NSDictionary *)XMLRPCDictionary;
@end

@interface Page (WordPressApi)
- (NSDictionary *)XMLRPCDictionary;
- (void)postPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)getPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)editPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
@end

@implementation Page
@dynamic parentID;

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    if ([remoteStatus intValue] == AbstractPostRemoteStatusSync) {
		return NSLocalizedString(@"Pages", @"");
    } else {
		return [super titleForRemoteStatus:remoteStatus];
	}
}

+ (NSString *const)remoteUniqueIdentifier {
    return @"page_id";
}

- (void)updateFromDictionary:(NSDictionary *)postInfo {
	self.postTitle      = [postInfo objectForKey:@"title"];
    self.postID         = [[postInfo objectForKey:@"page_id"] numericValue];
    self.content        = [postInfo objectForKey:@"description"];
    self.date_created_gmt    = [postInfo objectForKey:@"date_created_gmt"];
    NSString *status = [postInfo objectForKey:@"page_status"];
    if ([status isEqualToString:@"future"]) {
        status = @"publish";
    }
    self.status         = status;
    NSString *password = [postInfo objectForKey:@"wp_password"];
    if ([password isEqualToString:@""]) {
        password = nil;
    }
    self.password = password;
    self.remoteStatus   = AbstractPostRemoteStatusSync;
	self.permaLink      = [postInfo objectForKey:@"permaLink"];
	self.mt_excerpt		= [postInfo objectForKey:@"mt_excerpt"];
	self.mt_text_more	= [postInfo objectForKey:@"text_more"];
	self.wp_slug		= [postInfo objectForKey:@"wp_slug"];
	self.post_thumbnail = [postInfo objectForKey:@"featured_image"];
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if ([self.password isEmpty])
        self.password = nil;

    [self save];

    if ([self hasRemote]) {
        [self editPostWithSuccess:success failure:failure];
    } else {
        [self postPostWithSuccess:success failure:failure];
    }
}

@end

@implementation Page (WordPressApi)

- (NSDictionary *)XMLRPCDictionary {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithDictionary:[super XMLRPCDictionary]];

    if (self.status == nil)
        self.status = @"publish";

    [postParams setObject:self.status forKey:@"page_status"];
    
    return postParams;
}

- (void)postPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:[self XMLRPCDictionary]];
    self.remoteStatus = AbstractPostRemoteStatusPushing;
    
    [self.blog.api callMethod:@"wp.newPage"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          if ([responseObject respondsToSelector:@selector(numericValue)]) {
                              self.postID = [responseObject numericValue];
                              self.remoteStatus = AbstractPostRemoteStatusSync;
                              // Set the temporary date until we get it from the server so it sorts properly on the list
                              self.date_created_gmt = [NSDate date];
                              [self save];
                              [self getPostWithSuccess:success failure:failure];
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
                          } else if (failure) {
                              self.remoteStatus = AbstractPostRemoteStatusFailed;
                              NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid value returned for new post: %@", responseObject] forKey:NSLocalizedDescriptionKey];
                              NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
                              failure(error);
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                          }
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          self.remoteStatus = AbstractPostRemoteStatusFailed;
                          if (failure) failure(error);
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                      }];    
}

- (void)getPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [NSArray arrayWithObjects:self.blog.blogID, self.postID, self.blog.username, self.blog.password, nil];
    [self.blog.api callMethod:@"wp.getPage"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          [self updateFromDictionary:responseObject];
                          [self save];
                          if (success) success();
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)editPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    if (self.postID == nil) {
        if (failure) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Can't edit a post if it's not in the server" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"org.wordpress.iphone" code:0 userInfo:userInfo];
            failure(error);
        }
        return;
    }
    
    NSArray *parameters = [NSArray arrayWithObjects:self.blog.blogID, self.postID, self.blog.username, self.blog.password, [self XMLRPCDictionary], nil];
    self.remoteStatus = AbstractPostRemoteStatusPushing;
    [self.blog.api callMethod:@"wp.editPage"
                   parameters:parameters
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          self.remoteStatus = AbstractPostRemoteStatusSync;
                          [self getPostWithSuccess:nil failure:nil];
                          if (success) success();
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if ([self isDeleted] || self.managedObjectContext == nil)
                              return;

                          self.remoteStatus = AbstractPostRemoteStatusFailed;
                          if (failure) failure(error);
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
                      }];
}

- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    DDLogMethod();
    BOOL remote = [self hasRemote];
    if (remote) {
        NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:self.postID];
        [self.blog.api callMethod:@"wp.deletePage"
                       parameters:parameters
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              if (success) success();
                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              if (failure) failure(error);
                          }];
    }
    [self remove];
    if (!remote && success) {
        success();
    }
}

@end