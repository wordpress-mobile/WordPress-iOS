#import <Foundation/Foundation.h>

@class Menu;
@class MenuLocation;

extern NSString * const MenusSelectionViewItemChangedSelectedNotification;
extern NSString * const MenusSelectionViewItemUpdatedItemObjectNotification;

@interface MenusSelectionItem : NSObject

@property (nonatomic, strong) id itemObject;
@property (nonatomic, assign) BOOL selected;

+ (MenusSelectionItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionItem *)itemWithLocation:(MenuLocation *)location;

- (BOOL)isMenu;
- (BOOL)isMenuLocation;
- (NSString *)displayName;
- (void)notifyItemObjectWasUpdated;

@end

@interface MenusSelectionAddMenuItem : MenusSelectionItem

@end
