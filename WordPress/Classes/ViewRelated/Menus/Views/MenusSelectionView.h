#import <UIKit/UIKit.h>

@class Menu;
@class MenuLocation;

extern NSString * const MenusSelectionViewItemChangedSelectedNotification;
extern NSString * const MenusSelectionViewItemUpdatedItemObjectNotification;

@interface MenusSelectionViewItem : NSObject

@property (nonatomic, strong) id itemObject;
@property (nonatomic, assign) BOOL selected;

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location;

- (BOOL)isMenu;
- (BOOL)isMenuLocation;
- (NSString *)displayName;
- (void)notifyItemObjectWasUpdated;

@end

typedef NS_ENUM(NSUInteger, MenusSelectionViewType) {
    MenusSelectionViewTypeMenus,
    MenusSelectionViewTypeLocations
};

@protocol MenusSelectionViewDelegate;

@interface MenusSelectionView : UIView

@property (nonatomic, assign) MenusSelectionViewType selectionType;
@property (nonatomic, weak) id <MenusSelectionViewDelegate> delegate;
@property (nonatomic, readonly) BOOL selectionExpanded;
@property (nonatomic, strong) MenusSelectionViewItem *selectedItem;

- (void)addSelectionViewItem:(MenusSelectionViewItem *)selectionItem;
- (MenusSelectionViewItem *)itemWithItemObjectEqualTo:(id)itemObject;
- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>

// user interaction dictates the selection view should be expanded or not (closed)
- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand;
- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionViewItem *)item;
- (void)selectionViewSelectedOptionForCreatingNewMenu:(MenusSelectionView *)selectionView;

@end