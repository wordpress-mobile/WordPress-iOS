#import <CoreData/CoreData.h>

@class MenuItem, MenuLocation, Blog;

NS_ASSUME_NONNULL_BEGIN

/**
 *  @brief    An object encapsulating a Menu, the locations using it, and the items belonging to it.
 */
@interface Menu : NSManagedObject

@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *menuId;
@property (nullable, nonatomic, retain) NSString *name;

///---------------------
/// @name Relationships
///---------------------

@property (nullable, nonatomic, retain) NSOrderedSet<MenuItem *> *items;
@property (nullable, nonatomic, retain) NSSet<MenuLocation *> *locations;
@property (nullable, nonatomic, retain) Blog *blog;

///---------------------
/// @name Helper methods
///---------------------

+ (NSString *)entityName;

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
