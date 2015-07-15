#import "ThemeServiceRemote.h"
#import "WordPressComApi.h"

// Service dictionary keys
static NSString* const ThemeServiceRemoteThemesKey = @"themes";

@implementation ThemeServiceRemote

#pragma mark - Getting themes

- (NSOperation *)getActiveThemeForBlogId:(NSNumber *)blogId
                                 success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                                 failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    
    NSOperation *operation = [self.api GET:path
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                       if (success) {
                                           success(themeDictionary);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];
    
    return operation;
}

- (NSOperation *)getPurchasedThemesForBlogId:(NSNumber *)blogId
                                     success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                                     failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/purchased", blogId];
    
    NSOperation *operation = [self.api GET:path
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themes = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                           
                                           success(themes);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];
    
    return operation;
}

- (NSOperation *)getThemeId:(NSString*)themeId
                    success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                    failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"themes/%@", themeId];
    
    NSOperation *operation = [self.api GET:path
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                       if (success) {
                                           success(themeDictionary);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];
    
    return operation;
}

- (NSOperation *)getThemes:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                   failure:(ThemeServiceRemoteFailureBlock)failure
{
    static NSString* const path = @"themes";
    
    NSOperation *operation = [self.api GET:path
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themes = [response arrayForKey:ThemeServiceRemoteThemesKey];
                  
                                           success(themes);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];
    
    return operation;
}

- (NSOperation *)getThemesForBlogId:(NSNumber *)blogId
                            success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                            failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes", blogId];
    
    NSOperation *operation = [self.api GET:path
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themes = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                           
                                           success(themes);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];
    
    return operation;
}

#pragma mark - Activating themes

- (NSOperation *)activateThemeId:(NSString*)themeId
                       forBlogId:(NSNumber *)blogId
                         success:(ThemeServiceRemoteSuccessBlock)success
                         failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString* const path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSDictionary* parameters = @{@"theme": themeId};
    
    NSOperation *operation = [self.api POST:path
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                        if (success) {
                                            NSArray *themes = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                            
                                            success(themes);
                                        }
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        if (failure) {
                                            failure(error);
                                        }
                                    }];
    
    return operation;
}

@end
