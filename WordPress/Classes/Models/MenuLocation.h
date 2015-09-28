#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Menu, Blog;

NS_ASSUME_NONNULL_BEGIN

@interface MenuLocation : NSManagedObject

@property (nullable, nonatomic, retain) NSString *defaultState;
@property (nullable, nonatomic, retain) NSString *details;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet<Menu *> *menus;
@property (nonatomic, strong, readwrite) Blog *blog;

@end

@interface MenuLocation (CoreDataGeneratedAccessors)

- (void)addMenusObject:(Menu *)value;
- (void)removeMenusObject:(Menu *)value;
- (void)addMenus:(NSSet<Menu *> *)values;
- (void)removeMenus:(NSSet<Menu *> *)values;

@end

NS_ASSUME_NONNULL_END