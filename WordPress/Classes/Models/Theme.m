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

#pragma mark - CoreData helpers

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

#pragma mark - Misc

- (BOOL)isCurrentTheme
{
    return [self.blog.currentThemeId isEqualToString:self.themeId];
}

- (BOOL)isPremium
{
    return [self.premium isEqualToNumber:@1];
}

@end