#import <CoreData/CoreData.h>

@class MenuItem, MenuLocation, Blog;

NS_ASSUME_NONNULL_BEGIN

extern NSInteger const MenuDefaultID;

/**
 *  @brief    An object encapsulating a Menu, the locations using it, and the items belonging to it.
 */
@interface Menu : NSManagedObject

@property (nullable, nonatomic, strong) NSString *details;
@property (nullable, nonatomic, strong) NSNumber *menuID;
@property (nullable, nonatomic, strong) NSString *name;

///---------------------
/// @name Relationships
///---------------------

@property (nullable, nonatomic, strong) NSOrderedSet<MenuItem *> *items;
@property (nullable, nonatomic, strong) NSSet<MenuLocation *> *locations;
@property (nullable, nonatomic, strong) Blog *blog;

///---------------------
/// @name Helper methods
///---------------------

+ (NSString *)entityName;

+ (Menu *)newMenu:(NSManagedObjectContext *)managedObjectContext;
+ (Menu *)defaultMenuForBlog:(Blog *)blog;
+ (Menu *)newDefaultMenu:(NSManagedObjectContext *)managedObjectContext;
+ (NSString *)defaultMenuName;

- (BOOL)isDefaultMenu;

@end

@interface Menu (CoreDataGeneratedAccessors)

- (void)insertObject:(MenuItem *)value inItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromItemsAtIndex:(NSUInteger)idx;
- (void)insertItems:(NSArray<MenuItem *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInItemsAtIndex:(NSUInteger)idx withObject:(MenuItem *)value;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray<MenuItem *> *)values;
- (void)addItemsObject:(MenuItem *)value;
- (void)removeItemsObject:(MenuItem *)value;
- (void)addItems:(NSOrderedSet<MenuItem *> *)values;
- (void)removeItems:(NSOrderedSet<MenuItem *> *)values;

- (void)addLocationsObject:(MenuLocation *)value;
- (void)removeLocationsObject:(MenuLocation *)value;
- (void)addLocations:(NSSet<MenuLocation *> *)values;
- (void)removeLocations:(NSSet<MenuLocation *> *)values;

@end

NS_ASSUME_NONNULL_END
