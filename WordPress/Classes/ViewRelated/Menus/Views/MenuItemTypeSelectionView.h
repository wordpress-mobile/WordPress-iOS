#import <UIKit/UIKit.h>
#import "MenusDesign.h"

@interface MenuItemSelectionType : NSObject

@property (nonatomic, assign) MenuItemType itemType;
@property (nonatomic, assign) BOOL selected;

- (NSString *)title;
- (NSString *)iconImageName;

@end

@interface MenuItemTypeSelectionTableView : UITableView

@end

@protocol MenuItemTypeSelectionViewDelegate;

@interface MenuItemTypeSelectionView : UIView

@property (nonatomic, weak) id <MenuItemTypeSelectionViewDelegate> delegate;
@property (nonatomic, strong) IBOutlet MenuItemTypeSelectionTableView *tableView;

@end

@protocol MenuItemTypeSelectionViewDelegate <NSObject>

- (void)typeSelectionView:(MenuItemTypeSelectionView *)selectionView selectedType:(MenuItemType)type;

@end