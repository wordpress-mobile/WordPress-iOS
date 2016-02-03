#import <Foundation/Foundation.h>
#import "Blog.h"

@interface BlogSiteVisibilityHelper : NSObject

/// @returns An array of possible SiteVisibility values for the specified blog.
+ (NSArray *)siteVisibilityValuesForBlog:(Blog *)blog;

/// @returns The associated titles for the SiteVisibility values specified.
+ (NSArray *)titlesForSiteVisibilityValues:(NSArray *)values;

/// @returns The associated hints for the SiteVisibility values specified.
+ (NSArray *)hintsForSiteVisibilityValues:(NSArray *)values;

/// @returns The associated title for the SiteVisibility value specified.
+ (NSString *)titleForSiteVisibility:(SiteVisibility)privacy;

/// @returns The title for the current visibility of the specified blog.
+ (NSString *)titleForCurrentSiteVisibilityOfBlog:(Blog *)blog;

@end
