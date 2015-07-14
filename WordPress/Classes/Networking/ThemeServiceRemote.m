#import "ThemeServiceRemote.h"
#import "WordPressComApi.h"

// Service dictionary keys
static NSString* const ThemeServiceRemoteThemesKey = @"themes";

@implementation ThemeServiceRemote

#pragma mark - Getting themes

- (void)getActiveThemeForBlogId:(NSNumber *)blogId
                        success:(ThemeServiceThemeRequestSuccessBlock)success
                        failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    
    [self.api GET:path
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
}

- (void)getPurchasedThemesForBlogId:(NSNumber *)blogId
                            success:(ThemeServiceThemesRequestSuccessBlock)success
                            failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/purchased", blogId];
    
    [self.api GET:path
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
}

- (void)getThemeId:(NSString*)themeId
           success:(ThemeServiceThemeRequestSuccessBlock)success
           failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    
    NSString *path = [NSString stringWithFormat:@"themes/%@", themeId];
    
    [self.api GET:path
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
}

- (void)getThemes:(ThemeServiceThemesRequestSuccessBlock)success
          failure:(ThemeServiceFailureBlock)failure
{
    static NSString* const path = @"themes";
    
    [self.api GET:path
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
}

- (void)getThemesForBlogId:(NSNumber *)blogId
                   success:(ThemeServiceThemesRequestSuccessBlock)success
                   failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes", blogId];
    
    [self.api GET:path
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
}

#pragma mark - Activating themes

- (void)activateThemeId:(NSString*)themeId
              forBlogId:(NSNumber *)blogId
                success:(ThemeServiceSuccessBlock)success
                failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString* const path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSDictionary* parameters = @{@"theme": themeId};
    
    [self.api POST:path
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
}

@end
