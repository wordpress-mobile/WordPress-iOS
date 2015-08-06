#import "ThemeServiceRemote.h"

#import <NSObject-SafeExpectations/NSDictionary+SafeExpectations.h>
#import "RemoteTheme.h"
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                       if (success) {
                                           RemoteTheme *theme = [self themeFromDictionary:themeDictionary];
                                           success(theme);
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themeDictionaries = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                           NSArray *themes = [self themesFromDictionaries:themeDictionaries];
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                       if (success) {
                                           RemoteTheme *theme = [self themeFromDictionary:themeDictionary];
                                           success(theme);
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themeDictionaries = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                           NSArray *themes = [self themesFromDictionaries:themeDictionaries];
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themeDictionaries = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                           NSArray *themes = [self themesFromDictionaries:themeDictionaries];
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
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    NSDictionary* parameters = @{@"theme": themeId};
    
    NSOperation *operation = [self.api POST:requestUrl
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                        if (success) {
                                            NSArray *themeDictionaries = [response arrayForKey:ThemeServiceRemoteThemesKey];
                                            NSArray *themes = [self themesFromDictionaries:themeDictionaries];
                                            success(themes);
                                        }
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        if (failure) {
                                            failure(error);
                                        }
                                    }];
    
    return operation;
}

#pragma mark - Parsing the dictionary replies

/**
 *  @brief      Creates a remote theme object from the specified dictionary.
 *
 *  @param      dictionary      The dictionary containing the theme information.  Cannot be nil.
 *
 *  @returns    A remote theme object.
 */
- (RemoteTheme *)themeFromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    static NSString* const ThemeIdKey = @"id";
    static NSString* const ThemeScreenshotKey = @"screenshot";
    static NSString* const ThemeVersionKey = @"version";
    static NSString* const ThemeDownloadURLKey = @"download_url";
    static NSString* const ThemeTrendingRankKey = @"trending_rank";
    static NSString* const ThemePopularityRankKey = @"popularity_rank";
    static NSString* const ThemeNameKey = @"name";
    static NSString* const ThemeDescriptionKey = @"description";
    static NSString* const ThemeTagsKey = @"tags";
    static NSString* const ThemePreviewURLKey = @"preview_url";
    
    RemoteTheme *theme = [RemoteTheme new];
    
    [self loadCostForTheme:theme fromDictionary:dictionary];
    [self loadLaunchDateForTheme:theme fromDictionary:dictionary];
    
    theme.desc = [dictionary stringForKey:ThemeDescriptionKey];
    theme.downloadUrl = [dictionary stringForKey:ThemeDownloadURLKey];
    theme.name = [dictionary stringForKey:ThemeNameKey];
    theme.popularityRank = [dictionary numberForKey:ThemePopularityRankKey];
    theme.previewUrl = [dictionary stringForKey:ThemePreviewURLKey];
    theme.screenshotUrl = [dictionary stringForKey:ThemeScreenshotKey];
    theme.tags = [dictionary arrayForKey:ThemeTagsKey];
    theme.themeId = [dictionary stringForKey:ThemeIdKey];
    theme.trendingRank = [dictionary numberForKey:ThemeTrendingRankKey];
    theme.version = [dictionary stringForKey:ThemeVersionKey];
    
    return theme;
}

/**
 *  @brief      Creates remote theme objects from the specified array of dictionaries.
 *
 *  @param      dictionaries    The array of dictionaries containing the themes information.  Cannot
 *                              be nil.
 *
 *  @returns    An array of remote theme objects.
 */
- (NSArray *)themesFromDictionaries:(NSArray *)dictionaries
{
    NSParameterAssert([dictionaries isKindOfClass:[NSArray class]]);
    
    NSMutableArray *themes = [[NSMutableArray alloc] initWithCapacity:dictionaries.count];
    
    for (NSDictionary *dictionary in dictionaries) {
        NSAssert([dictionary isKindOfClass:[NSDictionary class]],
                 @"Expected a dictionary.");
        
        RemoteTheme *theme = [self themeFromDictionary:dictionary];
        
        [themes addObject:theme];
    }
    
    return [NSArray arrayWithArray:themes];
}

#pragma mark - Field parsing

/**
 *  @brief      Loads the cost structure from a dictionary into the specified remote theme object.
 *
 *  @param      theme       The theme to load the info into.  Cannot be nil.
 *  @param      dictionary  The dictionary to load the info from.  Cannot be nil.
 */
- (void)loadCostForTheme:(RemoteTheme *)theme
          fromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([theme isKindOfClass:[RemoteTheme class]]);
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    static NSString* const ThemeCostKey = @"cost";
    static NSString* const ThemeCostCurrencyKey = @"currency";
    static NSString* const ThemeCostDisplayKey = @"display";
    static NSString* const ThemeCostNumberKey = @"number";
    
    NSDictionary *costDictionary = dictionary[ThemeCostKey];
    
    theme.costCurrency = [costDictionary stringForKey:ThemeCostCurrencyKey];
    theme.costDisplay = [costDictionary stringForKey:ThemeCostDisplayKey];
    theme.costNumber = [costDictionary numberForKey:ThemeCostNumberKey];
}

/**
 *  @brief      Loads a theme's launch date from a dictionary into the specified remote theme
 *              object.
 *
 *  @param      theme       The theme to load the info into.  Cannot be nil.
 *  @param      dictionary  The dictionary to load the info from.  Cannot be nil.
 */
- (void)loadLaunchDateForTheme:(RemoteTheme *)theme
                fromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([theme isKindOfClass:[RemoteTheme class]]);
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    static NSString* const ThemeLaunchDateKey = @"launch_date";
    
    NSString *launchDateString = [dictionary stringForKey:ThemeLaunchDateKey];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-mm-dd"];
    
    theme.launchDate = [formatter dateFromString:launchDateString];
}

@end
