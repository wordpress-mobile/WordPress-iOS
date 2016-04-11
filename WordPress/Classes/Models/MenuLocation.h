#import <CoreData/CoreData.h>

@class Menu, Blog;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @brief    An object encapsulating a Location within a theme/site that a Menu can occupy.
 */
@interface MenuLocation : NSManagedObject

@property (nullable, nonatomic, strong) NSString *defaultState;
@property (nullable, nonatomic, strong) NSString *details;
@property (nullable, nonatomic, strong) NSString *name;

///---------------------
/// @name Relationships
///---------------------

@property (nullable, nonatomic, strong) Blog *blog;
@property (nullable, nonatomic, strong) Menu *menu;

///---------------------
/// @name Helper methods
///---------------------

+ (NSString *)entityName;

@end

NS_ASSUME_NONNULL_END
