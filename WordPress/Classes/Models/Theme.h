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

#pragma mark - Creating themes

/**
 *  @brief      Creates and initializes a new theme with the specified theme Id in the specified
 *              context.
 *
 *  @param      themeId     The ID of the new theme.  Cannot be nil.
 *  @param      context     The managed object context to use for the insert operation.  Cannot be
 *                          nil.
 *
 *  @returns    The newly created and initialized object.
 */
+ (Theme *)newThemeWithId:(NSString *)themeId
   inManagedObjectContext:(NSManagedObjectContext *)context;

#pragma mark - Finding existing themes

/**
 *  @brief      Obtains the theme with the specified ID if it exists.
 *
 *  @param      themeId     The ID of the theme to retrieve.  Cannot be nil.
 *  @param      context     The managed object context to use for the find operation.  Cannot be
 *                          nil.
 *
 *  @returns    The stored theme matching the specified ID if found, or nil if it's not found.
 */
+ (Theme *)findThemeWithId:(NSString *)themeId
    inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 *  @brief      Obtains the theme with the specified ID if it exists, otherwise a new theme is
 *              created and returned.
 *
 *  @param      themeId     The ID of the theme to retrieve.  Cannot be nil.
 *  @param      context     The managed object context to use for the find operation.  Cannot be
 *                          nil.
 *
 *  @returns    The stored theme matching the specified ID if found, or nil if it's not found.
 */
+ (Theme *)findOrCreateThemeWithId:(NSString *)themeId
            inManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface Theme (WordPressComApi)

+ (void)fetchAndInsertThemesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
+ (void)fetchCurrentThemeForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)activateThemeWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
