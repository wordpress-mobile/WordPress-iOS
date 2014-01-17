//
//  RecommendedBlog.h
//  WordPress
//
//  Created by Eric Johnson on 1/16/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecommendedBlog : NSObject

@property (nonatomic, assign) NSInteger siteID;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *reason;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *titleShort;
@property (nonatomic, strong) NSString *domain;

+ (void)syncRecommendedBlogs:(void (^)(NSArray *recommendedBlogs))success failure:(void (^)(NSError *error))failure;
+ (NSArray *)recommendedBlogs;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryFromItem;
- (void)updateFromDictionary:(NSDictionary *)dictionary;

@end
