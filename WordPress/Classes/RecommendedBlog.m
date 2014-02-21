//
//  RecommendedBlog.m
//  WordPress
//
//  Created by Eric Johnson on 1/16/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "RecommendedBlog.h"
#import "WordPressComApi.h"
#import "WPAccount.h"

NSString * const RecommendedBlogsKey = @"RecommendedBlogsKey";
NSString * const RecommendedBlogsExcludedIDsKey = @"RecommendedBlogsExcludedIDsKey";
NSInteger const RecommendedBlogsMaxExcludedIDs = 20;

@implementation RecommendedBlog

+ (void)syncRecommendedBlogs:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    // sync recommended blogs. Store the result in NSUserDefaults. Pass results to the success callback
    DDLogMethod();
    
    WordPressComApi *api;
    if ([[WPAccount defaultWordPressComAccount] restApi].authToken) {
        api = [[WPAccount defaultWordPressComAccount] restApi];
    } else {
        api = [WordPressComApi anonymousApi];
    }
    
    NSString *excludedIDsStr = @"";
    NSArray *excludedIDs = [[NSUserDefaults standardUserDefaults] arrayForKey:RecommendedBlogsExcludedIDsKey];
    if ([excludedIDs count]) {
        excludedIDsStr = [excludedIDs componentsJoinedByString:@","];
    }
    
    NSString *path = [NSString stringWithFormat:@"read/recommendations/mine/?number=%@&exclude=%@", @3, excludedIDsStr];
	[api getPath:path
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSArray *results = [responseObject arrayForKey:@"blogs"];
             if (results) {
                 [[NSUserDefaults standardUserDefaults] setObject:results forKey:RecommendedBlogsKey];
                 [[self class] updateExcludedRecommendedBlogIDs:results];
             }
             
             if (success) {
                 success([self recommendedBlogs]);
             }
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if (failure) {
                 failure(error);
             }
         }];
}

+ (NSArray *)recommendedBlogs {
    // Retrieve recommended blogs saved in NSUserDefaults
    NSArray *arr = [[NSUserDefaults standardUserDefaults] arrayForKey:RecommendedBlogsKey];
    NSMutableArray *recommendedBlogs = [NSMutableArray array];
    
    for (NSDictionary *dict in arr) {
        RecommendedBlog *recBlog = [[RecommendedBlog alloc] initWithDictionary:dict];
        [recommendedBlogs addObject:recBlog];
    }
    
    return recommendedBlogs;
}

+ (void)updateExcludedRecommendedBlogIDs:(NSArray *)array {
    NSArray *arr = [[NSUserDefaults standardUserDefaults] arrayForKey:RecommendedBlogsExcludedIDsKey];
    if (!arr) {
        arr = [NSArray array];
    }
    NSMutableArray *excludedIDs = [arr mutableCopy];
    
    for (NSDictionary *dict in array) {
        NSString *blogID = [dict stringForKey:@"blog_id"];
        // Make sure we don't (for whatever reason) add a duplicate
        if (![excludedIDs containsObject:blogID]) {
            [excludedIDs insertObject:blogID atIndex:0];
        }
    }
    
    while ([excludedIDs count] > RecommendedBlogsMaxExcludedIDs) {
        [excludedIDs removeLastObject];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:excludedIDs forKey:RecommendedBlogsExcludedIDsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self updateFromDictionary:dictionary];
    }
    return self;
}

- (NSDictionary *)dictionaryFromItem {
    return @{
             @"blog_id":[NSNumber numberWithInteger:self.siteID],
             @"image":self.imagePath,
             @"reason":self.reason,
             @"title":self.title,
             @"title_short":self.titleShort,
             @"blog_domain":self.domain,
             @"following":[NSNumber numberWithBool:self.isFollowing]
             };
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    self.siteID = [[dictionary numberForKey:@"blog_id"] integerValue];
    self.imagePath = [dictionary stringForKey:@"image"];
    self.reason = [dictionary stringForKey:@"reason"];
    self.title = [dictionary stringForKey:@"title"];
    self.titleShort = [dictionary stringForKey:@"title_short"];
    self.domain = [dictionary stringForKey:@"blog_domain"];
    self.isFollowing = [[dictionary numberForKey:@"following"] boolValue];
}

- (void)toggleFollowingWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    BOOL following = !self.isFollowing;
	self.isFollowing = following;
	
	NSString *path = nil;
	if (self.isFollowing) {
		path = [NSString stringWithFormat:@"sites/%d/follows/new", self.siteID];
	} else {
		path = [NSString stringWithFormat:@"sites/%d/follows/mine/delete", self.siteID];
	}
	
	[[[WPAccount defaultWordPressComAccount] restApi] postPath:path
                                                    parameters:nil
                                                       success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                           if(success) {
                                                               success();
                                                           }
                                                       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                           self.isFollowing = !following;
                                                           
                                                           if(failure) {
                                                               failure(error);
                                                           }
                                                       }];
}

@end
