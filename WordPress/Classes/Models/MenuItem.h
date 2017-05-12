#import <CoreData/CoreData.h>

@class Menu;
@class Blog;

NS_ASSUME_NONNULL_BEGIN

/**
 The majority of MenuItems are set as pages.
 */
extern NSString * const MenuItemTypePage;

/** 
 API data returns type as "custom" for MenuItems that were set with specific URL sources.
 Locally, the UI identifies interacting with custom MenuItems as "Links" with URL sources to edit.
 */
extern NSString * const MenuItemTypeCustom;

/**
 Taxonomy MenuItems
 */
extern NSString * const MenuItemTypeCategory;
extern NSString * const MenuItemTypeTag;

/**
 MenuItem to a specific post.
 The post could be considered a custom content post on a wp.org site, and may not be considered a "blog" post by the user.
 */
extern NSString * const MenuItemTypePost;

/**
 Custom Jetpack MenuItems that link to specific a post with a custom content type managed by Jetpack.
 */
extern NSString * const MenuItemTypeJetpackTestimonial;
extern NSString * const MenuItemTypeJetpackPortfolio;
extern NSString * const MenuItemTypeJetpackComic;

/**
 The string value for an item link target opening a new window or tab.
 */
extern NSString * const MenuItemLinkTargetBlank;

/**
 *  @brief    An object encapsulating an individual Menu item and it's API data.
 */
@interface MenuItem : NSManagedObject

@property (nullable, nonatomic, strong) NSNumber *contentID;
@property (nullable, nonatomic, strong) NSString *details;
@property (nullable, nonatomic, strong) NSNumber *itemID;
@property (nullable, nonatomic, strong) NSString *linkTarget;
@property (nullable, nonatomic, strong) NSString *linkTitle;
@property (nullable, nonatomic, strong) NSString *name;
@property (nullable, nonatomic, strong) NSString *type;
@property (nullable, nonatomic, strong) NSString *typeFamily;
@property (nullable, nonatomic, strong) NSString *typeLabel;
@property (nullable, nonatomic, strong) NSString *urlStr;
@property (nullable, nonatomic, strong) NSArray<NSString *> *classes;

///---------------------
/// @name Relationships
///---------------------

/**
 The Menu the item belongs to.
 */
@property (nullable, nonatomic, strong) Menu *menu;

/**
 Direct children of the item.
 NOTE: Does not include any descendents of this item's children.
 See method isDescendantOfItem: for detecting ancestry.
 */
@property (nullable, nonatomic, strong) NSSet<MenuItem *> *children;

/**
 The parent of the item, if the item has one.
 */
@property (nullable, nonatomic, strong) MenuItem *parent;

///---------------------
/// @name Helper methods
///---------------------
+ (NSString *)entityName;

/**
 The display label text for a MenuItemType string.
 */
+ (NSString *)labelForType:(NSString *)itemType blog:(nullable Blog *)blog;

/**
 The localized default title text (name) to use with a newly created MenuItem.
 */
+ (NSString *)defaultItemNameLocalized;

/**
 Call this method to know whether an item is a descendent of this item.
 @returns YES if the item is a descendent, NO if not.
 */
- (BOOL)isDescendantOfItem:(MenuItem *)item;

/**
 Search an ordered set for the last occurring descendant of self.
 Useful for detecting the end of a list of related parent/child items for additions and ordering.
 @param orderedItems an ordered set of items nested top-down as a parent followed by children. (as returned from the Menus API)
 @returns MenuItem the last child of self to occur in the ordered set.
 */
- (MenuItem *)lastDescendantInOrderedItems:(NSOrderedSet *)orderedItems;

/**
 The item's name is nil, empty, or the default string.
 */
- (BOOL)nameIsEmptyOrDefault;

@end

@interface MenuItem (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(MenuItem *)value;
- (void)removeChildrenObject:(MenuItem *)value;
- (void)addChildren:(NSSet<MenuItem *> *)values;
- (void)removeChildren:(NSSet<MenuItem *> *)values;

@end

NS_ASSUME_NONNULL_END
