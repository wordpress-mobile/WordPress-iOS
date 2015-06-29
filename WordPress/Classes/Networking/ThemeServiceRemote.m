#import "ThemeServiceRemote.h"
#import "WordPressComApi.h"

// Service dictionary keys
static NSString* const ThemeServiceRemoteThemesKey = @"themes";

@interface ThemeServiceRemote ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *context;
@end

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

#pragma mark - Old services...

/*
- (void)fetchAndInsertThemesForBlogId:(NSNumber *)blogId
                            success:(ThemeServiceSuccessBlock)success
                            failure:(ThemeServiceFailureBlock)failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    [[defaultAccount restApi] fetchThemesForBlogId:blogId.stringValue success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] newDerivedContext];
        [backgroundMOC performBlock:^{
            NSMutableArray *themesToKeep = [NSMutableArray array];
            for (NSDictionary *t in responseObject[@"themes"]) {
                Theme *theme = [Theme createOrUpdateThemeFromDictionary:t withBlog:blog withContext:backgroundMOC];
                [themesToKeep addObject:theme];
            }
            
            NSSet *existingThemes = ((Blog *)[backgroundMOC objectWithID:blog.objectID]).themes;
            for (Theme *theme in existingThemes) {
                if (![themesToKeep containsObject:theme]) {
                    [backgroundMOC deleteObject:theme];
                }
            }
            
            [[ContextManager sharedInstance] saveDerivedContext:backgroundMOC];
            
            dateFormatter = nil;
            
            if (success) {
                dispatch_async(dispatch_get_main_queue(), success);
            }
            
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchCurrentThemeForBlog:(Blog *)blog
                         success:(ThemeServiceSuccessBlock)success
                         failure:(ThemeServiceFailureBlock)failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    [[defaultAccount restApi] fetchCurrentThemeForBlogId:blog.blogID.stringValue success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [blog.managedObjectContext performBlock:^{
            blog.currentThemeId = responseObject[@"id"];
            [[ContextManager sharedInstance] saveContext:blog.managedObjectContext];
            if (success) {
                dispatch_async(dispatch_get_main_queue(), success);
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)activateThemeWithSuccess:(ThemeServiceSuccessBlock)success
                         failure:(ThemeServiceFailureBlock)failure
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    [[defaultAccount restApi] activateThemeForBlogId:self.blog.blogID.stringValue themeId:self.themeId success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.blog.managedObjectContext performBlock:^{
            self.blog.currentThemeId = self.themeId;
            [[ContextManager sharedInstance] saveContext:self.blog.managedObjectContext];
            if (success) {
                dispatch_async(dispatch_get_main_queue(), success);
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}
 */

@end
