#import "Theme.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"

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
@dynamic price;
@dynamic demoUrl;
@dynamic blog;

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
    return [self.premium boolValue];
}

@end
