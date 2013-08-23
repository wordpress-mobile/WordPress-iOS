/*
 * Theme.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <CoreData/CoreData.h>

@interface Theme : NSManagedObject

@property (nonatomic, retain) NSString *themeId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *details;
@property (nonatomic, retain) NSNumber *trendingRank;
@property (nonatomic, retain) NSNumber *popularityRank;
@property (nonatomic, retain) NSString *screenshotUrl;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSNumber *isPremium;
@property (nonatomic, retain) NSDate *launchDate;
@property (nonatomic, retain) NSArray *tags;

@end


@interface Theme (WordPressComApi)

+ (void)fetchAndInsertThemesForBlogId:(NSString *)blogId success:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
