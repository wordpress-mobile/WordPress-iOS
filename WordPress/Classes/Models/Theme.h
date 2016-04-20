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
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *authorUrl;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *previewUrl;
@property (nonatomic, retain) NSString *price;
@property (nonatomic, retain) NSNumber *purchased;
@property (nonatomic, retain) NSString *demoUrl;
@property (nonatomic, retain) NSString *stylesheet;
@property (nonatomic, retain) NSNumber *order;
@property (nonatomic, retain) Blog *blog;

/**
 *  @brief      Call this method to know the entity name for objects of this class.
 *  @details    Returns the same name as the class for this implementation.  If child classes
 *              have a difference in the CoreData and class name, they should override this method.
 *
 *  @returns    The entity name.
 */
+ (NSString *)entityName;

/**
 *  @brief      Link to customization page for this theme
 *
 *  @returns    The URL to present
 */
- (NSString *)customizeUrl;

/**
 *  @brief      Link to details page for this theme
 *
 *  @returns    The URL to present
 */
- (NSString *)detailsUrl;

/**
 *  @brief      Link to support page for this theme
 *
 *  @returns    The URL to present
 */
- (NSString *)supportUrl;

/**
 *  @brief      Link to demo viewing page for this theme
 *
 *  @returns    The URL to present
 */
- (NSString *)viewUrl;

- (BOOL)isCurrentTheme;
- (BOOL)isPremium;

@end
