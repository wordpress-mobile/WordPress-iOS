#import <CoreData/CoreData.h>

@class Menu;

NS_ASSUME_NONNULL_BEGIN

@interface MenuItem : NSManagedObject

@property (nullable, nonatomic, retain) NSString *contentId;
@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *itemId;
@property (nullable, nonatomic, retain) NSString *linkTarget;
@property (nullable, nonatomic, retain) NSString *linkTitle;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSString *typeFamily;
@property (nullable, nonatomic, retain) NSString *typeLabel;
@property (nullable, nonatomic, retain) NSString *urlStr;
@property (nullable, nonatomic, retain) Menu *menu;
@property (nullable, nonatomic, retain) NSOrderedSet<MenuItem *> *children;
@property (nullable, nonatomic, retain) MenuItem *parent;

+ (NSString *)entityName;

@end

@interface MenuItem (CoreDataGeneratedAccessors)

- (void)insertObject:(MenuItem *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray<MenuItem *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(MenuItem *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray<MenuItem *> *)values;
- (void)addChildrenObject:(MenuItem *)value;
- (void)removeChildrenObject:(MenuItem *)value;
- (void)addChildren:(NSOrderedSet<MenuItem *> *)values;
- (void)removeChildren:(NSOrderedSet<MenuItem *> *)values;

@end

NS_ASSUME_NONNULL_END