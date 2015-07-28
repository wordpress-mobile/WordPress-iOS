#import "Theme.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"

static NSDateFormatter *dateFormatter;

@implementation Theme

@dynamic popularityRank;
@dynamic details;
@dynamic themeId;
@dynamic premium;
@dynamic launchDate;
@dynamic screenshotUrl;
@dynamic trendingRank;
@dynamic version;
@dynamic tags;
@dynamic name;
@dynamic previewUrl;
@dynamic blog;

static NSString* const ThemeCoreDataEntityName = @"Theme";

+ (Theme *)createOrUpdateThemeFromDictionary:(NSDictionary *)themeInfo
                                    withBlog:(Blog*)blog
                                 withContext:(NSManagedObjectContext *)context
{
    Blog *contextBlog = (Blog*)[context objectWithID:blog.objectID];

    Theme *theme;
    NSSet *result = [contextBlog.themes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self.themeId == %@", themeInfo[@"id"]]];
    if (result.count > 1) {
        theme = result.allObjects[0];
    } else {
        theme = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self)
                                              inManagedObjectContext:context];
        theme.themeId = themeInfo[@"id"];
        theme.blog = contextBlog;
    }

    theme.name = themeInfo[@"name"];
    theme.details = themeInfo[@"description"];
    theme.trendingRank = themeInfo[@"trending_rank"];
    theme.popularityRank = themeInfo[@"popularity_rank"];
    theme.screenshotUrl = themeInfo[@"screenshot"];
    theme.version = themeInfo[@"version"];
    theme.premium = @([[themeInfo objectForKeyPath:@"cost.number"] integerValue] > 0);
    theme.tags = themeInfo[@"tags"];
    theme.previewUrl = themeInfo[@"preview_url"];

    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"YYYY-MM-dd";
    }
    theme.launchDate = [dateFormatter dateFromString:themeInfo[@"launch_date"]];

    return theme;
}

- (BOOL)isCurrentTheme
{
    return [self.blog.currentThemeId isEqualToString:self.themeId];
}

- (BOOL)isPremium
{
    return [self.premium isEqualToNumber:@1];
}

#pragma mark - Creating themes

+ (Theme *)newThemeWithId:(NSString *)themeId
   inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([context isKindOfClass:[NSManagedObjectContext class]]);
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:ThemeCoreDataEntityName
                                                         inManagedObjectContext:context];
    
    Theme *theme = [[Theme alloc] initWithEntity:entityDescription
                  insertIntoManagedObjectContext:context];
    
    return theme;
}

#pragma mark - Finding existing themes

+ (Theme *)findThemeWithId:(NSString *)themeId
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([context isKindOfClass:[NSManagedObjectContext class]]);

    Theme *theme = nil;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@""];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:ThemeCoreDataEntityName];

    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (results) {
        theme = (Theme *)[results firstObject];
        NSAssert([theme isKindOfClass:[Theme class]],
                 @"Expected a Theme object.");
    } else {
        NSAssert(error == nil,
                 @"We shouldn't be getting errors here.  This means something's internally broken.");
    }
    
    return theme;
}

+ (Theme *)findOrCreateThemeWithId:(NSString *)themeId
            inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert([themeId isKindOfClass:[NSString class]]);
    NSParameterAssert([context isKindOfClass:[NSManagedObjectContext class]]);
    
    Theme *theme = [self findThemeWithId:themeId inManagedObjectContext:context];
    
    if (!theme) {
        theme = [self newThemeWithId:themeId inManagedObjectContext:context];
    }
    
    return theme;
}

@end

@implementation Theme (PublicAPI)

+ (void)fetchAndInsertThemesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    [[defaultAccount restApi] fetchThemesForBlogId:blog.blogID.stringValue success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] newDerivedContext];
        [backgroundMOC performBlock:^{
            NSMutableArray *themesToKeep = [NSMutableArray array];
            for (NSDictionary *t in responseObject[@"themes"]) {
                Theme *theme = [Theme createOrUpdateThemeFromDictionary:t withBlog:blog withContext:backgroundMOC];
                [themesToKeep addObject:theme];
            }

            NSSet *existingThemes = ((Blog *)[backgroundMOC objectWithID:blog.objectID]).themes;
            for (Theme *t in existingThemes) {
                if (![themesToKeep containsObject:t]) {
                    [backgroundMOC deleteObject:t];
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

+ (void)fetchCurrentThemeForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
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

- (void)activateThemeWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure
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

@end