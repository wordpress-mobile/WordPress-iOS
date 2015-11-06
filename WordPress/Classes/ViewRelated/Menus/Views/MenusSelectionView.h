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
@property (nonatomic, readonly) BOOL selectionExpanded;

- (void)updateItems:(NSArray <MenusSelectionViewItem *> *)items selectedItem:(MenusSelectionViewItem *)selectedItem;
- (void)setSelectionItemsExpanded:(BOOL)selectionItemsExpanded animated:(BOOL)animated;

@end

@protocol MenusSelectionViewDelegate <NSObject>
@optional

// user interaction dictates the selection view should be expanded or not (closed)
- (void)userInteractionDetectedForTogglingSelectionView:(MenusSelectionView *)selectionView expand:(BOOL)expand;

@end