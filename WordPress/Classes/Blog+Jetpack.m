//
//  Blog+Jetpack.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <objc/runtime.h>

#import "Blog+Jetpack.h"
#import "SFHFKeychainUtils.h"
#import "WordPressAppDelegate.h"

NSString * const BlogJetpackErrorDomain = @"BlogJetpackError";
NSString * const BlogJetpackApiBaseUrl = @"https://public-api.wordpress.com/";
NSString * const BlogJetpackApiPath = @"get-user-blogs/1.0";
NSString * const BlogJetpackKeychainPrefix = @"jetpackblog-";

// AFJSONRequestOperation requires that a URI end with .json in order to match
// This will make any request to be processed as JSON
@interface BlogJetpackJSONRequestOperation : AFJSONRequestOperation
@end
@implementation BlogJetpackJSONRequestOperation
+(BOOL)canProcessRequest:(NSURLRequest *)urlRequest {
    return YES;
}
@end


@implementation Blog (Jetpack)

- (BOOL)hasJetpack {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return (nil != [self jetpackVersion]);
}

- (NSString *)jetpackVersion {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return [self.options stringForKeyPath:@"jetpack_version.value"];
}

- (NSNumber *)jetpackBlogID {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

	return [self.options numberForKeyPath:@"jetpack_client_id.value"];
}

- (NSString *)jetpackUsername {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    return [[NSUserDefaults standardUserDefaults] stringForKey:[self jetpackDefaultsKey]];
}

- (NSString *)jetpackPassword {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");

    NSError *error = nil;
    return [SFHFKeychainUtils getPasswordForUsername:[self jetpackUsername] andServiceName:@"WordPress.com" error:&error];
}

- (void)validateJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)())success failure:(void (^)(NSError *))failure {
    NSAssert(![self isWPcom], @"Can't validate credentials for a WordPress.com blog");
    NSAssert(username != nil, @"Can't validate with a nil username");
    NSAssert(password != nil, @"Can't validate with a nil password");

    if ([self isWPcom]) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:BlogJetpackErrorDomain code:BlogJetpackErrorCodeInvalidBlog userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Can't validate credentials for a WordPress.com blog", @"")}];
            failure(error);
            return;
        }
    }

    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:BlogJetpackApiBaseUrl]];
    [client registerHTTPOperationClass:[BlogJetpackJSONRequestOperation class]];
    [client setDefaultHeader:@"User-Agent" value:[[WordPressAppDelegate sharedWordPressApplicationDelegate] applicationUserAgent]];
    [client setAuthorizationHeaderWithUsername:username password:password];
    [client getPath:BlogJetpackApiPath
         parameters:@{@"f": @"json"}
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSArray *blogs = [responseObject arrayForKeyPath:@"userinfo.blog"];
                NSNumber *searchID = [self jetpackBlogID];
                NSString *searchURL = self.url;
                WPFLog(@"Available wp.com/jetpack blogs for %@: %@", username, blogs);
                NSArray *foundBlogs = [blogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    BOOL valid = NO;
                    if (searchID && [[evaluatedObject numberForKey:@"id"] isEqualToNumber:searchID]) {
                        valid = YES;
                    } else if ([[evaluatedObject stringForKey:@"url"] isEqualToString:searchURL]) {
                        valid = YES;
                    }
                    if (valid) {
                        WPFLog(@"Found blog: %@", evaluatedObject);
                        [self saveJetpackUsername:username andPassword:password];
                    }
                    return valid;
                }]];
                if (foundBlogs && [foundBlogs count] > 0) {
                    
                    if (success) success();
                } else {
                    NSError *error = [NSError errorWithDomain:BlogJetpackErrorDomain
                                                         code:BlogJetpackErrorCodeNoRecordForBlog
                                                     userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"This blog is not connected to that WordPress.com username", @"")}];
                    if (failure) failure(error);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) {
                    NSError *jetpackError = error;
                    if (operation.response.statusCode == 401) {
                        jetpackError = [NSError errorWithDomain:BlogJetpackErrorDomain
                                                           code:BlogJetpackErrorCodeInvalidCredentials
                                                       userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid username or password", @""), NSUnderlyingErrorKey: error}];

                    }
                    failure(jetpackError);
                }
            }];
}

- (void)removeJetpackCredentials {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self jetpackDefaultsKey]];
}

#pragma mark - Private methods

- (void)saveJetpackUsername:(NSString *)username andPassword:(NSString *)password {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:[self jetpackDefaultsKey]];
    NSError *error;
    [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:@"WordPress.com" updateExisting:YES error:&error];
}

- (NSString *)jetpackDefaultsKey {
    NSAssert(![self isWPcom], @"Blog+Jetpack doesn't support WordPress.com blogs");
    return [NSString stringWithFormat:@"%@%@", BlogJetpackKeychainPrefix, self.url];
}

/*
 Replacement method for `-[Blog remove]`
 
 @warning Don't call this directly
 */
- (void)removeWithoutJetpack {
    [self removeJetpackCredentials];

    // Since we exchanged implementations, this actually calls `-[Blog remove]`
    [self removeWithoutJetpack];
}

+ (void)load {
    Method originalRemove = class_getInstanceMethod(self, @selector(remove));
    Method customRemove = class_getInstanceMethod(self, @selector(removeWithoutJetpack));
    method_exchangeImplementations(originalRemove, customRemove);
}

@end
