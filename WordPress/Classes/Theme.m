/*
 * Theme.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "Theme.h"
#import "WordPressAppDelegate.h"

NSString *const WordPressPublicAPI = @"http://public-api.wordpress.com/rest/v1";
static NSDateFormatter *dateFormatter;

@implementation Theme

@dynamic themeId;
@dynamic name;
@dynamic details;
@dynamic trendingRank;
@dynamic popularityRank;
@dynamic screenshotUrl;
@dynamic version;
@dynamic isPremium;
@dynamic launchDate;
@dynamic tags;

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
    newTheme.isPremium = @(NO); // TODO change based on themeInfo[@"cost"][@"number"] > 0
    newTheme.tags = themeInfo[@"tags"];
    
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

@end

@implementation Theme (PublicAPI)

+ (void)fetchAndInsertThemesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFHTTPClient *publicApiClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:WordPressPublicAPI]];
    
    NSURLRequest *request = [publicApiClient requestWithMethod:@"GET" path:@"themes" parameters:nil];
    AFJSONRequestOperation *getThemes = [AFJSONRequestOperation
                                         JSONRequestOperationWithRequest:(NSURLRequest *)request
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                             // Two strategies for uniqueness: destroy all themes and repopulate
                                             // or find existing and only add new ones:
                                             // Clear all existing themes and insert new ones
                                             [self removeAllThemesWithContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext];
                                             for (NSDictionary *t in JSON[@"themes"]) {
                                                 [self themeFromDictionary:t];
                                             }
                                             dateFormatter = nil;
                                             if (success) {
                                                 success();
                                             }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];
    [publicApiClient enqueueHTTPRequestOperation:getThemes];
}

@end