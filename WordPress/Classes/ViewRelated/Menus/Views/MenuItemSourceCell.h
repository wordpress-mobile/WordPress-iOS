#import <UIKit/UIKit.h>

@interface MenuItemSourceCell : UITableViewCell

@property (nonatomic, assign) BOOL sourceSelected;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *badgeTitle;
@property (nonatomic, assign) NSUInteger sourceHierarchyIndentation;

- (CGRect)drawingRectForLabel;

@end
