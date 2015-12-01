#import "Theme.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "NSString+Helpers.h"

static NSString* const ThemeDomainPublic = @"pub";
static NSString* const ThemeDomainPremium = @"premium";
static NSString* const ThemeUrlPreview = @"%@/wp-admin/customize.php?theme=%@/%@";
static NSString* const ThemeAdminUrlCustomize = @"customize.php?hide_close=true";
static NSString* const ThemeUrlDemoParameters = @"?demo=true&iframe=true&theme_preview=true";
static NSString* const ThemeUrlSupport = @"https://theme.wordpress.com/themes/%@/support/?preview=true&iframe=true";
static NSString* const ThemeUrlDetails = @"https://wordpress.com/themes/%@/%@/?preview=true&iframe=true";
static NSString* const HomeUrlScheme = @"https://";

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
@dynamic stylesheet;
@dynamic order;
@dynamic blog;

#pragma mark - CoreData helpers

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

#pragma mark - Links

- (NSString *)customizeUrl
{
    return [self.blog adminUrlWithPath:ThemeAdminUrlCustomize];
}

- (NSString *)detailsUrl
{
    NSString *homeUrl = self.blog.homeURL.hostname;

    return [NSString stringWithFormat:ThemeUrlDetails, homeUrl, self.themeId];
}

- (NSString *)supportUrl
{
    return [NSString stringWithFormat:ThemeUrlSupport, self.themeId];
}

- (NSString *)viewUrl
{
    return [self.demoUrl stringByAppendingString:ThemeUrlDemoParameters];
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
