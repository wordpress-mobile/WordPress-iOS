#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger) {
    MenuItemTypeUnknown = 0,
    MenuItemTypePage,
    MenuItemTypeLink,
    MenuItemTypeCategory,
    MenuItemTypeTag,
    MenuItemTypePost,
    MenuItemTypeCustom
    
}MenuItemType;

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
@property (nullable, nonatomic, retain) NSSet<MenuItem *> *children;
@property (nullable, nonatomic, retain) MenuItem *parent;

+ (NSString *)entityName;
- (BOOL)isDescendantOfItem:(MenuItem *)item;
- (MenuItemType)itemType;

@end

@interface MenuItem (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(MenuItem *)value;
- (void)removeChildrenObject:(MenuItem *)value;
- (void)addChildren:(NSSet<MenuItem *> *)values;
- (void)removeChildren:(NSSet<MenuItem *> *)values;

@end

NS_ASSUME_NONNULL_END