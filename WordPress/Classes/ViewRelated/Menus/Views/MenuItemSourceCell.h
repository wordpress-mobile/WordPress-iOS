#import <UIKit/UIKit.h>

extern NSString * const MenuItemSourceSelectionValueDidChangeNotification;

@interface MenuItemSource : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *badgeTitle;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) NSUInteger indentationLevel;

@end

@interface MenuItemSourceCell : UITableViewCell

@property (nonatomic, strong) MenuItemSource *source;

@end
