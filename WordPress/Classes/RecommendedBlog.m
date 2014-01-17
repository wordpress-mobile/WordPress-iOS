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
    
	[api getPath:@"read/recommendations/mine/"
      parameters:@{@"number":@3}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSArray *results = [responseObject arrayForKey:@"blogs"];
             if (results) {
                 [[NSUserDefaults standardUserDefaults] setObject:results forKey:RecommendedBlogsKey];
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
             @"blog_domain":self.domain
             };
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {
    self.siteID = [[dictionary numberForKey:@"blog_id"] integerValue];
    self.imagePath = [dictionary stringForKey:@"image"];
    self.reason = [dictionary stringForKey:@"reason"];
    self.title = [dictionary stringForKey:@"title"];
    self.titleShort = [dictionary stringForKey:@"title_short"];
    self.domain = [dictionary stringForKey:@"blog_domain"];
}

@end
