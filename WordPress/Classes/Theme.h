#import <CoreData/CoreData.h>

@class Blog;

@interface Theme : NSManagedObject

@property (nonatomic, retain) NSNumber *popularityRank;
@property (nonatomic, retain) NSString *details;
@property (nonatomic, retain) NSString *themeId;
@property (nonatomic, retain) NSNumber *premium;
@property (nonatomic, retain) NSDate *launchDate;
@property (nonatomic, retain) NSString *screenshotUrl;
@property (nonatomic, retain) NSNumber *trendingRank;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *previewUrl;
@property (nonatomic, retain) Blog *blog;

- (BOOL)isCurrentTheme;
- (BOOL)isPremium;

@end

@interface Theme (WordPressComApi)

+ (void)fetchAndInsertThemesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
+ (void)fetchCurrentThemeForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)activateThemeWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
