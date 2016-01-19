#import <CoreData/CoreData.h>

@class Menu, Blog;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @brief    An object encapsulating a Location within a theme/site that a Menu can occupy.
 */
@interface MenuLocation : NSManagedObject

@property (nullable, nonatomic, retain) NSString *defaultState;
@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *name;

///---------------------
/// @name Relationships
///---------------------

@property (nullable, nonatomic, retain) Blog *blog;
@property (nullable, nonatomic, retain) Menu *menu;

///---------------------
/// @name Helper methods
///---------------------

+ (NSString *)entityName;

@end

NS_ASSUME_NONNULL_END
