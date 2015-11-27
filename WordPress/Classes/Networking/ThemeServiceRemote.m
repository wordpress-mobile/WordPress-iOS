#import "ThemeServiceRemote.h"

#import "RemoteTheme.h"
#import "WordPressComApi.h"

// Service dictionary keys
static NSString* const ThemeServiceRemoteThemesKey = @"themes";
static NSString* const ThemeServiceRemoteThemeCountKey = @"found";

@implementation ThemeServiceRemote

#pragma mark - Getting themes

- (NSOperation *)getActiveThemeForBlogId:(NSNumber *)blogId
                                 success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                                 failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);

    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                       if (success) {
                                           RemoteTheme *theme = [self themeFromDictionary:themeDictionary];
                                           theme.active = @YES;
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
                                     success:(ThemeServiceRemoteThemeIdentifiersRequestSuccessBlock)success
                                     failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/themes/purchased", blogId];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:nil
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray *themes = [self themeIdentifiersFromPurchasedThemesRequestResponse:response];
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
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
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

- (NSOperation *)getThemesPage:(NSInteger)page
                       success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                       failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert(page > 0);

    static NSString* const path = @"themes";
    
    NSOperation *operation = [self getThemesPage:page
                                            path:path
                                         success:success
                                         failure:failure];
    
    return operation;
}

- (NSOperation *)getThemesForBlogId:(NSNumber *)blogId
                               page:(NSInteger)page
                            success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                            failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    NSParameterAssert(page > 0);

    NSString *path = [NSString stringWithFormat:@"sites/%@/themes", blogId];
    
    NSOperation *operation = [self getThemesPage:page
                                            path:path
                                         success:success
                                         failure:failure];
    
    return operation;
}

- (NSOperation *)getThemesPage:(NSInteger)page
                          path:(NSString *)path
                       success:(ThemeServiceRemoteThemesRequestSuccessBlock)success
                       failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert(page > 0);
    NSParameterAssert([path isKindOfClass:[NSString class]]);
    
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_2];
    
    static NSString* const ThemeRequestTierKey = @"tier";
    static NSString* const ThemeRequestTierAllValue = @"all";
    static NSString* const ThemeRequestNumberKey = @"number";
    static NSInteger const ThemeRequestNumberValue = 50;
    static NSString* const ThemeRequestPageKey = @"page";

    NSDictionary *parameters = @{ThemeRequestTierKey: ThemeRequestTierAllValue,
                                 ThemeRequestNumberKey: @(ThemeRequestNumberValue),
                                 ThemeRequestPageKey: @(page),
                                 };
    
    NSOperation *operation = [self.api GET:requestUrl
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, NSDictionary *response) {
                                       if (success) {
                                           NSArray<RemoteTheme *> *themes = [self themesFromMultipleThemesRequestResponse:response];
                                           NSInteger themesLoaded = (page - 1) * ThemeRequestNumberValue;
                                           for (RemoteTheme *theme in themes){
                                               theme.order = ++themesLoaded;
                                           }
                                           NSInteger themesCount = [[response numberForKey:ThemeServiceRemoteThemeCountKey] integerValue];
                                           BOOL hasMore = themesLoaded < themesCount;
                                           success(themes, hasMore);
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       if (failure) {
                                           failure(error);
                                       }
                                   }];

    return operation;
}

#pragma mark - Activating themes

- (NSOperation *)activateThemeId:(NSString *)themeId
                       forBlogId:(NSNumber *)blogId
                         success:(ThemeServiceRemoteThemeRequestSuccessBlock)success
                         failure:(ThemeServiceRemoteFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blogId isKindOfClass:[NSNumber class]]);
    
    NSString* const path = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary* parameters = @{@"theme": themeId};
    
    NSOperation *operation = [self.api POST:requestUrl
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, NSDictionary *themeDictionary) {
                                        if (success) {
                                            RemoteTheme *theme = [self themeFromDictionary:themeDictionary];
                                            theme.active = @YES;
                                            success(theme);
                                        }
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        if (failure) {
                                            failure(error);
                                        }
                                    }];
    
    return operation;
}

#pragma mark - Parsing responses

/**
 *  @brief      Parses a purchased-themes-request response.
 *
 *  @param      response        The response object.  Cannot be nil.
 */
- (NSArray *)themeIdentifiersFromPurchasedThemesRequestResponse:(id)response
{
    NSParameterAssert(response != nil);
    
    NSArray *themeIdentifiers = [response arrayForKey:ThemeServiceRemoteThemesKey];
    
    return themeIdentifiers;
}

/**
 *  @brief      Parses a generic multi-themes-request response.
 *
 *  @param      response        The response object.  Cannot be nil.
 */
- (NSArray<RemoteTheme *> *)themesFromMultipleThemesRequestResponse:(id)response
{
    NSParameterAssert(response != nil);
    
    NSArray *themeDictionaries = [response arrayForKey:ThemeServiceRemoteThemesKey];
    NSArray<RemoteTheme *> *themes = [self themesFromDictionaries:themeDictionaries];
    
    return themes;
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
    
    static NSString* const ThemeActiveKey = @"active";
    static NSString* const ThemeAuthorKey = @"author";
    static NSString* const ThemeAuthorURLKey = @"author_uri";
    static NSString* const ThemeCostPath = @"cost.number";
    static NSString* const ThemeDemoURLKey = @"demo_uri";
    static NSString* const ThemeDescriptionKey = @"description";
    static NSString* const ThemeDownloadURLKey = @"download_uri";
    static NSString* const ThemeIdKey = @"id";
    static NSString* const ThemeNameKey = @"name";
    static NSString* const ThemePreviewURLKey = @"preview_url";
    static NSString* const ThemePriceKey = @"price";
    static NSString* const ThemePurchasedKey = @"purchased";
    static NSString* const ThemePopularityRankKey = @"rank_popularity";
    static NSString* const ThemeScreenshotKey = @"screenshot";
    static NSString* const ThemeStylesheetKey = @"stylesheet";
    static NSString* const ThemeTrendingRankKey = @"rank_trending";
    static NSString* const ThemeVersionKey = @"version";
    static NSString* const ThemeDomainPublic = @"pub";
    static NSString* const ThemeDomainPremium = @"premium";
    
    RemoteTheme *theme = [RemoteTheme new];
    
    [self loadLaunchDateForTheme:theme fromDictionary:dictionary];

    theme.active = [[dictionary numberForKey:ThemeActiveKey] boolValue];
    theme.author = [dictionary stringForKey:ThemeAuthorKey];
    theme.authorUrl = [dictionary stringForKey:ThemeAuthorURLKey];
    theme.demoUrl = [dictionary stringForKey:ThemeDemoURLKey];
    theme.desc = [dictionary stringForKey:ThemeDescriptionKey];
    theme.downloadUrl = [dictionary stringForKey:ThemeDownloadURLKey];
    theme.name = [dictionary stringForKey:ThemeNameKey];
    theme.popularityRank = [dictionary numberForKey:ThemePopularityRankKey];
    theme.previewUrl = [dictionary stringForKey:ThemePreviewURLKey];
    theme.price = [dictionary stringForKey:ThemePriceKey];
    theme.purchased = [dictionary numberForKey:ThemePurchasedKey];
    theme.screenshotUrl = [dictionary stringForKey:ThemeScreenshotKey];
    theme.stylesheet = [dictionary stringForKey:ThemeStylesheetKey];
    theme.themeId = [dictionary stringForKey:ThemeIdKey];
    theme.trendingRank = [dictionary numberForKey:ThemeTrendingRankKey];
    theme.version = [dictionary stringForKey:ThemeVersionKey];

    if (!theme.stylesheet) {
        NSString *domain = [dictionary numberForKeyPath:ThemeCostPath].intValue > 0 ? ThemeDomainPremium : ThemeDomainPublic;
        theme.stylesheet = [NSString stringWithFormat:@"%@/%@", domain, theme.themeId];
    }

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
- (NSArray<RemoteTheme *> *)themesFromDictionaries:(NSArray *)dictionaries
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
    
    static NSString* const ThemeLaunchDateKey = @"date_launched";
    
    NSString *launchDateString = [dictionary stringForKey:ThemeLaunchDateKey];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-mm-dd"];
    
    theme.launchDate = [formatter dateFromString:launchDateString];
}

@end
