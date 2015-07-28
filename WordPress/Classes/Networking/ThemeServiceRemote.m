#import "ThemeServiceRemote.h"
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
    
    NSOperation *operation = [self.api GET:path
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
    
    NSOperation *operation = [self.api GET:path
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
    
    NSOperation *operation = [self.api GET:path
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
    
    NSOperation *operation = [self.api GET:path
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
    
    NSOperation *operation = [self.api GET:path
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
    NSDictionary* parameters = @{@"theme": themeId};
    
    NSOperation *operation = [self.api POST:path
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
    
    theme.desc = dictionary[ThemeDescriptionKey];
    theme.downloadUrl = dictionary[ThemeDownloadURLKey];
    theme.name = dictionary[ThemeNameKey];
    theme.popularityRank = dictionary[ThemePopularityRankKey];
    theme.previewUrl = dictionary[ThemePreviewURLKey];
    theme.screenshotUrl = dictionary[ThemeScreenshotKey];
    theme.tags = dictionary[ThemeTagsKey];
    theme.themeId = dictionary[ThemeIdKey];
    theme.trendingRank = dictionary[ThemeTrendingRankKey];
    theme.version = dictionary[ThemeVersionKey];
    
    return theme;
}

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
    
    theme.costCurrency = costDictionary[ThemeCostCurrencyKey];
    theme.costDisplay = costDictionary[ThemeCostDisplayKey];
    theme.costNumber = costDictionary[ThemeCostNumberKey];
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
    
    NSString *launchDateString = dictionary[ThemeLaunchDateKey];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-mm-dd"];
    
    theme.launchDate = [formatter dateFromString:launchDateString];
}

@end
