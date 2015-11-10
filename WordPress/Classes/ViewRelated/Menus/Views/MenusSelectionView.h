#import <UIKit/UIKit.h>

@class Menu;
@class MenuLocation;

extern NSString * const MenusSelectionViewItemChangedSelectedNotification;

@interface MenusSelectionViewItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic, strong) id itemObject;
@property (nonatomic, assign) BOOL selected;

+ (MenusSelectionViewItem *)itemWithMenu:(Menu *)menu;
+ (MenusSelectionViewItem *)itemWithLocation:(MenuLocation *)location;

- (BOOL)isMenu;
- (BOOL)isMenuLocation;

@end

@protocol MenusSelectionViewDelegate;

@interface MenusSelectionView : UIView

@property (nonatomic, weak) id <MenusSelectionViewDelegate> delegate;
@property (nonatomic, readonly) BOOL selectionExpanded;
@property (nonatomic, strong) NSArray <MenusSelectionViewItem *> *items;
@property (nonatomic, strong) MenusSelectionViewItem *selectedItem;

- (MenusSelectionViewItem *)itemWithItemObjectEqualTo:(id)itemObject;

- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>

// user interaction dictates the selection view should be expanded or not (closed)
- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand;
- (void)selectionView:(MenusSelectionView *)selectionView selectedItem:(MenusSelectionViewItem *)item;

@end