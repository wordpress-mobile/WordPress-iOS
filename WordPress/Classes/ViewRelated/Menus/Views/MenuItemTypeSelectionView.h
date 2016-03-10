#import <UIKit/UIKit.h>
#import "MenuItem.h"

@class Blog;

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;
@property (nonatomic, strong) NSString *selectedItemType;

- (void)loadPostTypesForBlog:(Blog *)blog;
- (void)updateDesignForLayoutChangeIfNeeded;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

- (void)itemTypeSelectionViewChanged:(MenuItemTypeSelectionView *)typeSelectionView type:(NSString *)itemType;
- (BOOL)itemTypeSelectionViewRequiresFullSizedLayout:(MenuItemTypeSelectionView *)typeSelectionView;

@end