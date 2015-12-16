#import <UIKit/UIKit.h>

extern NSString * const MenuItemSourceResultSelectionDidChangeNotification;

@interface MenuItemSourceResult : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *badgeTitle;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) id source;

@end

@interface MenuItemSourceResultCell : UITableViewCell

@property (nonatomic, strong) MenuItemSourceResult *result;

@end
