#import <UIKit/UIKit.h>
#import "MenusSelectionDetailView.h"
#import "MenusSelectionItemView.h"

typedef NS_ENUM(NSUInteger)
{
    MenuSelectionViewTypeLocations,
    MenuSelectionViewTypeMenus
    
}MenuSelectionViewType;

@protocol MenusSelectionViewDelegate;

@interface MenusSelectionView : UIView

@property (nonatomic, assign) MenuSelectionViewType selectionType;
@property (nonatomic, weak) id <MenusSelectionViewDelegate> delegate;
@property (nonatomic, readonly) BOOL selectionItemsExpanded;

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem;
- (void)toggleSelectionExpansionIfNeeded:(BOOL)expanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>
@optional



@end