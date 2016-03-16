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

///---------------------
/// @name Relationships
///---------------------

/**
 The Menu the item belongs to.
 */
@property (nullable, nonatomic, retain) Menu *menu;

/**
 Direct children of the item.
 NOTE: Does not include any descendents of this item's children.
 See method isDescendantOfItem: for detecting ancestry.
 */
@property (nullable, nonatomic, retain) NSSet<MenuItem *> *children;

/**
 The parent of the item, if the item has one.
 */
@property (nullable, nonatomic, retain) MenuItem *parent;

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
 *  @brief      Call this method to know whether an item is a descendent of this item.
 *
 *  @returns    YES if the item is a descendent, NO if not.
 */
- (BOOL)isDescendantOfItem:(MenuItem *)item;

@end

@interface MenuItem (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(MenuItem *)value;
- (void)removeChildrenObject:(MenuItem *)value;
- (void)addChildren:(NSSet<MenuItem *> *)values;
- (void)removeChildren:(NSSet<MenuItem *> *)values;

@end

NS_ASSUME_NONNULL_END
