#import "ThemeService.h"

#import "Blog.h"
#import "Theme.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
@import WordPressKit;

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
    
    return [blog supports:BlogFeatureWPComRESTAPI];
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

- (NSProgress *)getActiveThemeForBlog:(Blog *)blog
                               success:(ThemeServiceThemeRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    
    NSProgress *progress = [remote getActiveThemeForBlogId:[blog dotComID]
                                                     success:^(RemoteTheme *remoteTheme) {
                                                         remoteTheme = [self removeWPComSuffixIfNeeded:remoteTheme
                                                                                               forBlog:blog];
                                                         Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                                                         forBlog:blog];
                                                         
                                                         [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                             if (success) {
                                                                 success(theme);
                                                             }
                                                         }];
                                                     } failure:failure];
    
    return progress;
}

- (NSProgress *)getPurchasedThemesForBlog:(Blog *)blog
                                   success:(ThemeServiceThemesRequestSuccessBlock)success
                                   failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    
    NSProgress *progress = [remote getPurchasedThemesForBlogId:[blog dotComID]
                                                         success:^(NSArray *remoteThemes) {
                                                             NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                                                    forBlog:blog];
                                                             
                                                             [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                                 if (success) {
                                                                     success(themes, NO, themes.count);
                                                                 }
                                                             }];
                                                         } failure:failure];
    
    return progress;
}

- (NSProgress *)getThemeId:(NSString*)themeId
                 forAccount:(WPAccount *)account
                    success:(ThemeServiceThemeRequestSuccessBlock)success
                    failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert(account.wordPressComRestApi != nil);

    if (account.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:account.wordPressComRestApi];
    
    NSProgress *progress = [remote getThemeId:themeId
                                        success:^(RemoteTheme *remoteTheme) {
                                            Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                                                              forBlog:nil];
                                            
                                            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                if (success) {
                                                    success(theme);
                                                }
                                            }];
                                        } failure:failure];
    
    return progress;
}

- (NSProgress *)getThemesForAccount:(WPAccount *)account
                                page:(NSInteger)page
                             success:(ThemeServiceThemesRequestSuccessBlock)success
                             failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([account isKindOfClass:[WPAccount class]]);

    if (account.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:account.wordPressComRestApi];
    
    NSProgress *progress = [remote getWPThemesPage:page
                                          freeOnly:false
                                           success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore, NSInteger totalThemeCount) {
                                                NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                                       forBlog:nil];

                                                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                                    if (success) {
                                                        success(themes, hasMore, totalThemeCount);
                                                    }
                                                }];
                                            } failure:failure];
    
    return progress;
}

- (NSProgress *)getThemesForBlog:(Blog *)blog
                             page:(NSInteger)page
                             sync:(BOOL)sync
                          success:(ThemeServiceThemesRequestSuccessBlock)success
                          failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];
    NSMutableSet *unsyncedThemes = sync ? [NSMutableSet setWithSet:blog.themes] : nil;

    if ([blog supports:BlogFeatureCustomThemes]) {
        return [remote getWPThemesPage:page
                              freeOnly:![blog supports:BlogFeaturePremiumThemes]
                               success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore, NSInteger totalThemeCount) {
                                   NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                          forBlog:blog];
                                   if (sync) {
                                       // We don't want to touch custom themes here, only WP.com themes
                                       NSMutableSet *unsyncedWPThemes = [unsyncedThemes mutableCopy];
                                       for (Theme *theme in unsyncedThemes) {
                                           if (theme.custom) {
                                               [unsyncedWPThemes removeObject:theme];
                                           }
                                       }
                                       [unsyncedWPThemes minusSet:[NSSet setWithArray:themes]];
                                       for (Theme *deleteTheme in unsyncedWPThemes) {
                                           if (![blog.currentThemeId isEqualToString:deleteTheme.themeId]) {
                                               [self.managedObjectContext deleteObject:deleteTheme];
                                           }
                                       }
                                   }

                                   [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                       if (success) {
                                           success(themes, hasMore, totalThemeCount);
                                       }
                                   }];
                               } failure:failure];
    } else {
        return [remote getThemesForBlogId:[blog dotComID]
                                     page:page
                                  success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore, NSInteger totalThemeCount) {
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
                                              success(themes, hasMore, totalThemeCount);
                                          }
                                      }];
                                  } failure:failure];
    }
}

- (NSProgress *)getCustomThemesForBlog:(Blog *)blog
                                  sync:(BOOL)sync
                               success:(ThemeServiceThemesRequestSuccessBlock)success
                               failure:(ThemeServiceFailureBlock)failure {
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");

    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];

    return [remote getCustomThemesForBlogId:[blog dotComID]
                                    success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore, NSInteger totalThemeCount) {
                                        NSMutableArray *validRemoteThemes = [NSMutableArray array];
                                        // We need to filter out themes with an id ending in -wpcom to match Calypso
                                        for (RemoteTheme *remoteTheme in remoteThemes) {
                                            if (![ThemeIdHelper themeIdHasWPComSuffix:remoteTheme.themeId]) {
                                                [validRemoteThemes addObject:remoteTheme];
                                            }
                                        }

                                        NSArray *themes = [self customThemesFromRemoteThemes:validRemoteThemes
                                                                                     forBlog:blog];
                                        if (sync) {
                                            // We don't want to touch WP.com themes here, only custom themes
                                            NSMutableSet *unsyncedThemes = [NSMutableSet setWithSet:blog.themes];
                                            NSMutableSet *unsyncedCustomThemes = [unsyncedThemes mutableCopy];
                                            for (Theme *theme in unsyncedThemes) {
                                                if (!theme.custom) {
                                                    [unsyncedCustomThemes removeObject:theme];
                                                }
                                            }
                                            [unsyncedCustomThemes minusSet:[NSSet setWithArray:themes]];
                                            for (Theme *deleteTheme in unsyncedCustomThemes) {
                                                if (![blog.currentThemeId isEqualToString:deleteTheme.themeId]) {
                                                    [self.managedObjectContext deleteObject:deleteTheme];
                                                }
                                            }
                                        }

                                        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                            if (success) {
                                                success(themes, hasMore, themes.count);
                                            }
                                        }];
                                    } failure:failure];
}

- (void)getStartingThemesForCategory:(NSString *)category
                                        page:(NSInteger)page
                                     success:(ThemeServiceThemesRequestSuccessBlock)success
                                     failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert(page > 0);
    NSParameterAssert([category isKindOfClass:[NSString class]]);
    
    WordPressComRestApi *api = [WordPressComRestApi defaultApiWithOAuthToken:nil userAgent:nil localeKey:[WordPressComRestApi LocaleKeyDefault]];
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api];
    
    [remote getStartingThemesForCategory:category
                                    page:page
                                 success:^(NSArray<RemoteTheme *> *remoteThemes, BOOL hasMore, NSInteger totalThemeCount) {
                                     NSArray *themes = [self themesFromRemoteThemes:remoteThemes
                                                                            forBlog:nil];
                                     [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                         if (success) {
                                             success(themes, hasMore, themes.count);
                                         }
                                     }];
                                 } failure:failure];
}

#pragma mark - Remote queries: Activating themes

- (NSProgress *)activateTheme:(Theme *)theme
                      forBlog:(Blog *)blog
                      success:(ThemeServiceThemeRequestSuccessBlock)success
                      failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([theme isKindOfClass:[Theme class]]);
    NSParameterAssert([theme.themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");
    
    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];

    if ([blog supports:BlogFeatureCustomThemes] &&
        !theme.custom) {
        NSString *themeIdWithWPComSuffix = [ThemeIdHelper themeIdWithWPComSuffix:theme.themeId];
        return [remote installThemeId:themeIdWithWPComSuffix
                            forBlogId:[blog dotComID]
                              success:^(RemoteTheme *remoteTheme) {
                                  [self activateThemeId:themeIdWithWPComSuffix
                                                forBlog:blog
                                                success:^(){
                                                    [self themeActivatedSuccessfully:theme
                                                                             forBlog:blog
                                                                             success:success];
                                                }
                                                failure:failure];
                              } failure:^(NSError *error) {
                                  // There's no way to know from the WP.com theme list if the theme was already
                                  // installed, BUT trying to install an already installed theme returns an error,
                                  // so regardless we are trying to activate. Calypso does this same thing.
                                  [self activateThemeId:themeIdWithWPComSuffix
                                                forBlog:blog
                                                success:^(){
                                                    [self themeActivatedSuccessfully:theme
                                                                             forBlog:blog
                                                                             success:success];
                                                } failure:failure];
                              }];
    } else {
        return [self activateThemeId:theme.themeId
                             forBlog:blog
                             success:^(){
                                 [self themeActivatedSuccessfully:theme
                                                          forBlog:blog
                                                          success:success];
                             } failure:failure];
    }
}

- (NSProgress *)activateThemeId:(NSString *)themeId
                        forBlog:(Blog *)blog
                        success:(ThemeServiceSuccessBlock)success
                        failure:(ThemeServiceFailureBlock)failure
{
    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];

    return [remote activateThemeId:themeId
                         forBlogId:[blog dotComID]
                           success:^(RemoteTheme *remoteTheme) {
                               if (success) {
                                   success();
                               }
                           } failure:failure];
}

- (void)themeActivatedSuccessfully:(Theme *)theme
                           forBlog:(Blog *)blog
                           success:(ThemeServiceThemeRequestSuccessBlock)success
{
    blog.currentThemeId = theme.themeId;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
        if (success) {
            success(theme);
        }
    }];
}

- (RemoteTheme *)removeWPComSuffixIfNeeded:(RemoteTheme *)remoteTheme
                                   forBlog:(Blog *)blog
{
    remoteTheme.themeId = [ThemeIdHelper themeIdWithWPComSuffixRemoved:remoteTheme.themeId
                                                               forBlog:blog];
    return remoteTheme;
}

#pragma mark - Remote queries: Installing themes

/**
 *  @brief      Installs the specified theme for the specified blog.
 *
 *  @param      themeId     The theme to install.  Cannot be nil.
 *  @param      blogId      The target blog.  Cannot be nil.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 *
 *  @returns    The progress object.
 */
- (NSProgress *)installTheme:(Theme *)theme
                     forBlog:(Blog *)blog
                     success:(ThemeServiceSuccessBlock)success
                     failure:(ThemeServiceFailureBlock)failure
{
    NSParameterAssert([theme isKindOfClass:[Theme class]]);
    NSParameterAssert([theme.themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSAssert([self blogSupportsThemeServices:blog],
             @"Do not call this method on unsupported blogs, check with blogSupportsThemeServices first.");

    if (blog.wordPressComRestApi == nil) {
        return nil;
    }

    ThemeServiceRemote *remote = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:blog.wordPressComRestApi];

    NSString *themeIdWithWPComSuffix = [ThemeIdHelper themeIdWithWPComSuffix:theme.themeId];
    return [remote installThemeId:themeIdWithWPComSuffix
                        forBlogId:[blog dotComID]
                          success:^(RemoteTheme *remoteTheme) {
                              if (success) {
                                  success();
                              }
                          } failure:^(NSError *error) {
                              // Since installing a previously installed theme will fail, but there is no
                              // way of knowing if it failed because of that or if the theme was previously installed,
                              // I'm going to go ahead and call success. Calypso does this same thing. I'm sorry.
                              if (success) {
                                  success();
                              }
                          }];
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
    theme.themeUrl = remoteTheme.themeUrl;
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
    return [self themesFromRemoteThemes:remoteThemes custom:NO forBlog:blog];
}

/**
 *  @brief      Updates our local themes matching the specified remote themes.
 *  @details    If the local themes do not exist, they are created.
 *
 *  @param      remoteThemes    An array with the remote custom themes containing the data to update
 *                              locally.  Cannot be nil.
 *  @param      blog            Blog being updated. May be nil for account.
 *  @param      ordered         Whether to update displayed order
 *
 *  @returns    An array with the updated and matching local themes.
 */
- (NSArray<Theme *> *)customThemesFromRemoteThemes:(NSArray<RemoteTheme *> *)remoteThemes
                                           forBlog:(nullable Blog *)blog
{
    return [self themesFromRemoteThemes:remoteThemes custom:YES forBlog:blog];
}

- (NSArray<Theme *> *)themesFromRemoteThemes:(NSArray<RemoteTheme *> *)remoteThemes
                                      custom:(BOOL)custom
                                     forBlog:(nullable Blog *)blog
{
    NSParameterAssert([remoteThemes isKindOfClass:[NSArray class]]);

    NSMutableArray *themes = [[NSMutableArray alloc] initWithCapacity:remoteThemes.count];

    [remoteThemes enumerateObjectsUsingBlock:^(RemoteTheme *remoteTheme, NSUInteger idx, BOOL *stop) {
        NSAssert([remoteTheme isKindOfClass:[RemoteTheme class]],
                 @"Expected a remote theme.");

        Theme *theme = [self themeFromRemoteTheme:remoteTheme
                                          forBlog:blog];
        theme.custom = custom;
        [themes addObject:theme];
    }];

    return [NSArray arrayWithArray:themes];
}

@end
