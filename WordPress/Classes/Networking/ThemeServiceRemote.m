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
    
    static NSString* const ThemeIdKey = @"id"; // string
    static NSString* const ThemeScreenshotKey = @"screenshot"; // string / URL
    static NSString* const ThemeVersionKey = @"version"; // string - version of the theme "v1.0.4"
    static NSString* const ThemeDownloadURLKey = @"download_url"; // string / URL
    static NSString* const ThemeTrendingRankKey = @"trending_rank"; // integer
    static NSString* const ThemePopularityRankKey = @"popularity_rank"; // integer
    static NSString* const ThemeNameKey = @"name"; // string
    static NSString* const ThemeDescriptionKey = @"description"; // string
    static NSString* const ThemeTagsKey = @"tags"; // array of strings
    static NSString* const ThemePreviewURLKey = @"preview_url"; // string / URL
    
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

- (void)loadCostForTheme:(RemoteTheme *)theme
          fromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([theme isKindOfClass:[RemoteTheme class]]);
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    static NSString* const ThemeCostKey = @"cost"; // struct
    static NSString* const ThemeCostCurrencyKey = @"currency"; // string
    static NSString* const ThemeCostDisplayKey = @"display"; // string - to show on screen
    static NSString* const ThemeCostNumberKey = @"number"; // float (?)
    
    NSDictionary *costDictionary = dictionary[ThemeCostKey];
    
    theme.costCurrency = costDictionary[ThemeCostCurrencyKey];
    theme.costDisplay = costDictionary[ThemeCostDisplayKey];
    theme.costNumber = costDictionary[ThemeCostNumberKey];
}

- (void)loadLaunchDateForTheme:(RemoteTheme *)theme
                fromDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert([theme isKindOfClass:[RemoteTheme class]]);
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    static NSString* const ThemeLaunchDateKey = @"launch_date"; // string / date "2015-05-10"
    
    NSString *launchDateString = dictionary[ThemeLaunchDateKey];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-mm-dd"];
    
    theme.launchDate = [formatter dateFromString:launchDateString];
}

@end
