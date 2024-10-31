#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Menu;
@class MenuLocation;

extern NSString * const MenusSelectionViewItemChangedSelectedNotification;
extern NSString * const MenusSelectionViewItemUpdatedItemObjectNotification;

/**
 An abstract object class for representing a Menu or MenuLocation.
 */
@interface MenusSelectionItem : NSObject

/**
 The associated object the item represents.
 */
@property (nonatomic, strong, nullable) id itemObject;

/**
 Tracker for the selected state of the item.
 */
@property (nonatomic, assign) BOOL selected;

/**
 Helper for creating an item with a Menu.
 */
+ (MenusSelectionItem *)itemWithMenu:(Menu *)menu;

/**
 Helper for creating an item with a MenuLocation.
 */
+ (MenusSelectionItem *)itemWithLocation:(MenuLocation *)location;

/**
 Helper for detecting whether an item is a Menu.
 */
- (BOOL)isMenu;

/**
 Helper for detecting whether an item is a MenuLocation.
 */
- (BOOL)isMenuLocation;

/**
 Get the displayName of the item for the UI.
 */
- (nullable NSString *)displayName;

/**
 Helper for posting the MenusSelectionViewItemUpdatedItemObjectNotification notification.
 */
- (void)notifyItemObjectWasUpdated;

@end

/**
 Convienience class for an item that only represents creating a new item in the UI.
 */
@interface MenusSelectionAddMenuItem : MenusSelectionItem

@end

NS_ASSUME_NONNULL_END
