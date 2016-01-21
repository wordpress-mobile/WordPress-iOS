#import <UIKit/UIKit.h>

extern NSString * const MenuItemSourceCellSelectionValueDidChangeNotification;

@interface MenuItemSourceCell : UITableViewCell

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *badgeTitle;
@property (nonatomic, assign) NSUInteger sourceHierarchyIndentation;

@end
