#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, MenuItemType) {
    MenuItemTypeUnknown = 0,
    
    /* The majority of MenuItems are set as pages.
     */
    MenuItemTypePage,
    
    /*  API data returns type as "custom" for MenuItems that were set with specific URL sources.
     Locally, the UI identifies interacting with custom MenuItems as "Links" with URL sources to edit.
     */
    MenuItemTypeCustom,
    MenuItemTypeLink = MenuItemTypeCustom,
    
    /* Taxonomy MenuItems
     */
    MenuItemTypeCategory,
    MenuItemTypeTag,
    
    /* MenuItem to a specific post.
     The post could be considered a custom content post on a wp.org site, and may not be considered a "blog" post by the user.
     */
    MenuItemTypePost,
    
    /* Custom Jetpack MenuItems that link to specific a post with a custom content type managed by Jetpack.
     */
    MenuItemTypeJetpackTestimonial,
    MenuItemTypeJetpackPortfolio
};

@class Menu;

NS_ASSUME_NONNULL_BEGIN

/* API identifier values for specific MenuItem types.
 */
extern NSString * const MenuItemTypeIdentifierPage;
extern NSString * const MenuItemTypeIdentifierCategory;
extern NSString * const MenuItemTypeIdentifierCustom;
extern NSString * const MenuItemTypeIdentifierTag;
extern NSString * const MenuItemTypeIdentifierPost;
extern NSString * const MenuItemTypeIdentifierJetpackTestimonial;
extern NSString * const MenuItemTypeIdentifierJetpackPortfolio;

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

/* The Menu the item belongs to.
 */
@property (nullable, nonatomic, retain) Menu *menu;

/* Direct children of the item.
 NOTE: Does not include any descendents of this item's children.
 See method isDescendantOfItem: for detecting ancestry.
 */
@property (nullable, nonatomic, retain) NSSet<MenuItem *> *children;

/* The parent of the item, if the item has one.
 */
@property (nullable, nonatomic, retain) MenuItem *parent;

///---------------------
/// @name Helper methods
///---------------------

+ (NSString *)entityName;

/**
 *  @brief      Call this method to know whether an item is a descendent of this item.
 *
 *  @returns    YES if the item is a descendent, NO if not.
 */
- (BOOL)isDescendantOfItem:(MenuItem *)item;

/**
 *  @brief      Call this method to detect the itemType of the item for handling the item in UIs.
 *
 *  @returns    MenuItemType of the item as detected by the self.type identifier value.
 */
- (MenuItemType)itemType;

@end

@interface MenuItem (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(MenuItem *)value;
- (void)removeChildrenObject:(MenuItem *)value;
- (void)addChildren:(NSSet<MenuItem *> *)values;
- (void)removeChildren:(NSSet<MenuItem *> *)values;

@end

NS_ASSUME_NONNULL_END
