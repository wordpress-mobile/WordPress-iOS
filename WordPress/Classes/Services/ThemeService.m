#import "ThemeService.h"

#import "Blog.h"
#import "RemoteTheme.h"
#import "Theme.h"
#import "ThemeServiceRemote.h"
#import "WPAccount.h"
#import "ContextManager.h"

/**
 *  @brief      Place unordered themes after loaded pages
 */
const NSInteger ThemeOrderUnspecified = 0;
const NSInteger ThemeOrderTrailing = 9999;

@implementation ThemeService

#pragma mark - Themes availability

- (BOOL)blogSupportsThemeServices:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    
    return blog.restApi && [blog dotComID];
}

#pragma mark - Local queries: Creating themes

/**
 *  @brief      Creates and initializes a new theme with the specified theme Id in the specified
 *              context.
 *  @details    You should probably not call this method directly.  Please read the documentation
 *              for findOrCreateThemeWithId: first.
 *
 *  @param      themeId     The ID of the new theme.  Cannot be nil.
 *  @param      blog        Blog being updated. May be nil for account.
 *
 *  @returns    The newly created and initialized object.
 */
- (Theme *)newThemeWithId:(NSString *)themeId
                  forBlog:(nullable Blog *)blog
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[Theme entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    __block Theme *theme = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        theme = [[Theme alloc] initWithEntity:entityDescription
               insertIntoManagedObjectContext:self.managedObjectContext];
        if (blog) {
            theme.blog = blog;
        }
    }];
    
    return theme;
}

/**
 *  @brief      Obtains the theme with the specified ID if it exists, otherwise a new theme is
 *              created and returned.
 *
 *  @param      themeId     The ID of the theme to retrieve.  Cannot be nil.
 *  @param      blog        Blog being updated. May be nil for account.
 *
 *  @returns    The stored theme matching the specified ID if found, or nil if it's not found.
 */
- (Theme *)findOrCreateThemeWithId:(NSString *)themeId
                           forBlog:(nullable Blog *)blog
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    
    Theme *theme = [self findThemeWithId:themeId
                                 forBlog:blog];
    
    if (!theme) {
        theme = [self newThemeWithId:themeId
                             forBlog:blog];
    }
    
    return theme;
}

#pragma mark - Local queries: finding themes

- (Theme *)findThemeWithId:(NSString *)themeId
                   forBlog:(nullable Blog *)blog
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    
    Theme *theme = nil;
    
    NSPredicate *predicate = nil;
    if (blog) {
        predicate = [NSPredicate predicateWithFormat:@"themeId == %@ AND blog == %@", themeId, blog];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"themeId == %@ AND blog.@count == 0", themeId, blog];
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Theme entityName]];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (results.count > 0) {
        theme = (Theme *)[results firstObject];
        NSAssert([theme isKindOfClass:[Theme class]],
                 @"Expected a Theme object.");
    } else {
        NSAssert(error == nil,
                 @"We shouldn't be getting errors here.  This means something's internally broken.");
    }
    
    return theme;
}

- (NSArray *)findAccountThemes
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog.@count == 0"];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Theme entityName]];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    return results;
}

#pragma mark - Remote queries: Getting theme info

- (NSOperation *)getActiveThemeForBlog:(Blog *)blog
                               success:(ThemeServiceThemeRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    
    NSOperation *operation = [remote getActiveThemeForBlogId:[blog dotComID]
                                                     success:^(RemoteTheme *remoteTheme) {
                                                         Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                                                         forBlog:blog];
                                                         
                                                         [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                             if (success) {
                                                                 success(theme);
                                                             }
                                                         }];
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
                                                         success:^(NSArray *remoteThemes) {
                                                             NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                                                    forBlog:blog];
                                                             
                                                             [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                                 if (success) {
                                                                     success(themes, NO);
                                                                 }
                                                             }];
                                                         } failure:failure];
    
    return operation;
}

- (NSOperation *)getThemeId:(NSString*)themeId
                 forAccount:(WPAccount *)account
                    success:(ThemeServiceThemeRequestSuccessBlock)success
                    failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:account.restApi];
    
    NSOperation *operation = [remote getThemeId:themeId
                                        success:^(RemoteTheme *remoteTheme) {
                                            Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                                                              forBlog:nil];
                                            
                                            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                if (success) {
                                                    success(theme);
                                                }
                                            }];
                                        } failure:failure];
    
    return operation;
}

- (NSOperation *)getThemesForAccount:(WPAccount *)account
                                page:(NSInteger)page
                             success:(ThemeServiceThemesRequestSuccessBlock)success
                             failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([account isKindOfClass:[WPAccount class]]);

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:account.restApi];
    
    NSOperation *operation = [remote getThemesPage:page
                                           success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore) {
                                                NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                                       forBlog:nil];

                                                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                    if (success) {
                                                        success(themes, hasMore);
                                                    }
                                                }];
                                            } failure:failure];
    
    return operation;
}

- (NSOperation *)getThemesForBlog:(Blog *)blog
                             page:(NSInteger)page
                             sync:(BOOL)sync
                          success:(ThemeServiceThemesRequestSuccessBlock)success
                          failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithApi:blog.restApi];
    NSMutableSet *unsyncedThemes = sync ? [NSMutableSet setWithSet:blog.themes] : nil;
    
    NSOperation *operation = [remote getThemesForBlogId:[blog dotComID]
                                                   page:page
                                                success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore) {
                                                    NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                                           forBlog:blog];
                                                    if (sync) {
                                                        [unsyncedThemes minusSet:[NSSet setWithArray:themes]];
                                                        for (Theme *deleteTheme in unsyncedThemes) {
                                                            if (![blog.currentThemeId isEqualToString:deleteTheme.themeId]) {
                                                                [self.managedObjectContext deleteObject:deleteTheme];
                                                            }
                                                        }
                                                    }
                                                    
                                                    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                        if (success) {
                                                            success(themes, hasMore);
                                                        }
                                                    }];
                                                } failure:failure];
    
    return operation;
}

#pragma mark - Remote queries: Activating themes

- (NSOperation *)activateTheme:(Theme *)theme
                       forBlog:(Blog *)blog
                       success:(ThemeServiceThemeRequestSuccessBlock)success
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
                                             success:^(RemoteTheme *remoteTheme) {
                                                 Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                                                                   forBlog:blog];
                                                 
                                                 [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                     if (success) {
                                                         success(theme);
                                                     }
                                                 }];
                                             } failure:failure];
    
    return operation;
}

#pragma mark - Parsing the dictionary replies

/**
 *  @brief      Updates our local theme matching the specified remote theme.
 *  @details    If the local theme does not exist, it is created.
 *
 *  @param      remoteTheme     The remote theme containing the data to update locally.
 *                              Cannot be nil.
 *  @param      blog            Blog being updated. May be nil for account.
 *
 *  @returns    The updated and matching local theme.
 */
- (Theme *)themeFromRemoteTheme:(RemoteTheme *)remoteTheme
                        forBlog:(nullable Blog *)blog
{
    NSParameterAssert([remoteTheme isKindOfClass:[RemoteTheme class]]);
    
    Theme *theme = [self findOrCreateThemeWithId:remoteTheme.themeId
                                         forBlog:blog];
    
    if (remoteTheme.author) {
        theme.author = remoteTheme.author;
        theme.authorUrl = remoteTheme.authorUrl;
    }
    theme.demoUrl = remoteTheme.demoUrl;
    theme.details = remoteTheme.desc;
    theme.launchDate = remoteTheme.launchDate;
    theme.name = remoteTheme.name;
    if (remoteTheme.order != ThemeOrderUnspecified) {
        theme.order = @(remoteTheme.order);
    } else if (theme.order.integerValue == ThemeOrderUnspecified) {
        theme.order = @(ThemeOrderTrailing);
    }
    theme.popularityRank = remoteTheme.popularityRank;
    theme.previewUrl = remoteTheme.previewUrl;
    BOOL availableFree = remoteTheme.purchased.boolValue || remoteTheme.price.length == 0;
    theme.premium = @(!availableFree);
    theme.price = remoteTheme.price;
    theme.purchased = remoteTheme.purchased;
    theme.screenshotUrl = remoteTheme.screenshotUrl;
    theme.stylesheet = remoteTheme.stylesheet;
    theme.themeId = remoteTheme.themeId;
    theme.trendingRank = remoteTheme.trendingRank;
    theme.version = remoteTheme.version;
    
    if (blog && remoteTheme.active) {
        blog.currentThemeId = theme.themeId;
    }
    
    return theme;
}


/**
 *  @brief      Updates our local themes matching the specified remote themes.
 *  @details    If the local themes do not exist, they are created.
 *
 *  @param      remoteThemes    An array with the remote themes containing the data to update
 *                              locally.  Cannot be nil.
 *  @param      blog            Blog being updated. May be nil for account.
 *  @param      ordered         Whether to update displayed order
 *
 *  @returns    An array with the updated and matching local themes.
 */
- (NSArray<Theme *> *)themesFromRemoteThemes:(NSArray<RemoteTheme *> *)remoteThemes
                                     forBlog:(nullable Blog *)blog
{
    NSParameterAssert([remoteThemes isKindOfClass:[NSArray class]]);
    
    NSMutableArray *themes = [[NSMutableArray alloc] initWithCapacity:remoteThemes.count];
    
    [remoteThemes enumerateObjectsUsingBlock:^(RemoteTheme *remoteTheme, NSUInteger idx, BOOL *stop) {
        NSAssert([remoteTheme isKindOfClass:[RemoteTheme class]],
                 @"Expected a remote theme.");
        
        Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                          forBlog:blog];
        [themes addObject:theme];
    }];
    
    return [NSArray arrayWithArray:themes];
}

@end
