/*
 * Theme.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "Theme.h"
#import "Blog.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"

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

+ (Theme *)themeFromDictionary:(NSDictionary *)themeInfo {
    NSManagedObjectContext *context = [WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext;
    Theme *newTheme = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self)
                                                    inManagedObjectContext:context];
    newTheme.themeId = themeInfo[@"id"];
    newTheme.name = themeInfo[@"name"];
    newTheme.details = themeInfo[@"description"];
    newTheme.trendingRank = themeInfo[@"trending_rank"];
    newTheme.popularityRank = themeInfo[@"popularity_rank"];
    newTheme.screenshotUrl = themeInfo[@"screenshot"];
    newTheme.version = themeInfo[@"version"];
    
    newTheme.premium = @([[themeInfo objectForKeyPath:@"cost.number"] integerValue] > 0);
    newTheme.tags = themeInfo[@"tags"];
    newTheme.previewUrl = themeInfo[@"preview_url"];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"YYYY-MM-dd";
    }
    newTheme.launchDate = [dateFormatter dateFromString:themeInfo[@"launch_date"]];
    
    return newTheme;
}

+ (void)removeAllThemesWithContext:(NSManagedObjectContext*)context {
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self)];
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        WPLog(@"Error executing fetch request for removal of all themes: %@", error);
        return;
    }
    for (Theme *theme in results) {
        [context deleteObject:theme];
    }
    [context save:&error];
    if (error) {
        WPLog(@"Error saving context after deletion of all themes: %@", error);
    }
}

- (BOOL)isCurrentTheme {
    return [self.blog.currentThemeId isEqualToString:self.themeId];
}

- (BOOL)isPremium {
    return [self.premium isEqualToNumber:@(1)];
}

@end

@implementation Theme (PublicAPI)

+ (void)fetchAndInsertThemesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[WordPressComApi sharedApi] fetchThemesForBlogId:blog.blogID.stringValue success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self removeAllThemesWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext];
        for (NSDictionary *t in responseObject[@"themes"]) {
            Theme *theme = [self themeFromDictionary:t];
            theme.blog = blog;
        }
        dateFormatter = nil;
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (void)fetchCurrentThemeForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[WordPressComApi sharedApi] fetchCurrentThemeForBlogId:blog.blogID.stringValue success:^(AFHTTPRequestOperation *operation, id responseObject) {
        blog.currentThemeId = responseObject[@"id"];
        [[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext save:nil];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)activateThemeWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [[WordPressComApi sharedApi] activateThemeForBlogId:self.blog.blogID.stringValue themeId:self.themeId success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end