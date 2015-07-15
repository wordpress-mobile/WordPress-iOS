#import "ThemeService.h"

#import "Blog.h"
#import "ThemeServiceRemote.h"
#import "WPAccount.h"

@implementation ThemeService

#pragma mark - Themes availability

- (BOOL)accountSupportsThemeServices:(WPAccount *)account
{
    NSParameterAssert([account isKindOfClass:[WPAccount class]]);
    
    return [account isWPComAccount];
}

- (BOOL)blogSupportsThemeServices:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    
    return blog.restApi && [blog dotComID];
}

#pragma mark - Getting themes

- (NSOperation *)getActiveThemeForBlog:(Blog *)blog
                               success:(ThemeServiceThemeRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    
    NSOperation *operation = [remote getActiveThemeForBlogId:[blog dotComID]
                                                     success:^(NSDictionary *themeDictionary) {
                                                         if (success) {
                                                             Theme *theme = [self themeFromDictionary:themeDictionary];
                                                             success(theme);
                                                         }
                                                     } failure:failure];
    
    return operation;
}

- (NSOperation *)getPurchasedThemesForBlog:(Blog *)blog
                                   success:(ThemeServiceThemesRequestSuccessBlock)success
                                   failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    
    NSOperation *operation = [remote getPurchasedThemesForBlogId:[blog dotComID]
                                                         success:^(NSArray *themeDictionaries) {
                                                             if (success) {
                                                                 NSArray *themes = [self themesFromDictionaries:themeDictionaries];
                                                                 
                                                                 success(themes);
                                                             }
                                                         } failure:failure];
    
    return operation;
}

- (NSOperation *)getThemeId:(NSString*)themeId
                 forAccount:(WPAccount *)account
                    success:(ThemeServiceThemeRequestSuccessBlock)success
                    failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSAssert([self accountSupportsThemeServices:account],
             @"Do not call this method on unsupported accounts, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:account.restApi];
    
    NSOperation *operation = [remote getThemeId:themeId
                                        success:^(NSDictionary *themeDictionary) {
                                            if (success) {
                                                Theme *theme = [self themeFromDictionary:themeDictionary];
                                                success(theme);
                                            }
                                        } failure:failure];
    
    return operation;
}

- (NSOperation *)getThemesForAccount:(WPAccount *)account
                             success:(ThemeServiceThemesRequestSuccessBlock)success
                             failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([account isKindOfClass:[WPAccount class]]);
    NSAssert([self accountSupportsThemeServices:account],
             @"Do not call this method on unsupported accounts, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:account.restApi];
    
    NSOperation *operation = [remote getThemes:^(NSArray *themeDictionaries) {
        if (success) {
            NSArray *themes = [self themesFromDictionaries:themeDictionaries];
            success(themes);
        }
    } failure:failure];
    
    return operation;
}


- (NSOperation *)getThemesForBlog:(Blog *)blog
                          success:(ThemeServiceThemesRequestSuccessBlock)success
                          failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    
    NSOperation *operation = [remote getThemesForBlogId:[blog dotComID]
                                                success:^(NSArray *themeDictionaries) {
                                                    if (success) {
                                                        NSArray *themes = [self themesFromDictionaries:themeDictionaries];
                                                        success(themes);
                                                    }
                                                } failure:failure];
    
    return operation;
}

#pragma mark - Activating themes

- (NSOperation *)activateTheme:(Theme *)theme
                       forBlog:(Blog *)blog
                       success:(ThemeServiceSuccessBlock)success
                       failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([theme isKindOfClass:[Theme class]]);
    NSParameterAssert([theme.themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    
    NSOperation *operation = [remote activateThemeId:theme.themeId
                                           forBlogId:[blog dotComID]
                                             success:success
                                             failure:failure];
    
    return operation;
}

#pragma mark - Parsing the dictionary replies

- (Theme *)themeFromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    Theme *theme = nil;
    
    return theme;
}

- (NSArray *)themesFromDictionaries:(NSArray *)dictionaries
{
    NSParameterAssert([dictionaries isKindOfClass:[NSArray class]]);
    
    NSMutableArray *themes = [[NSMutableArray alloc] initWithCapacity:dictionaries.count];
    
    for (NSDictionary *dictionary in dictionaries) {
        NSAssert([dictionary isKindOfClass:[NSDictionary class]],
                 @"Expected a dictionary.");
        
        Theme *theme = [self themeFromDictionary:dictionary];
        
        [themes addObject:theme];
    }
    
    return [NSArray arrayWithArray:themes];
}

@end
