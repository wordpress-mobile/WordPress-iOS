#import <UIKit/UIKit.h>

@interface MenuItemSourceCell : UITableViewCell

/**
 Selected state of the cell.
 */
@property (nonatomic, assign) BOOL sourceSelected;

/**
 Title for displaying within the cell.
 */
@property (nonatomic, copy) NSString *title;

/**
 A secondary title for displaying alongside the primary title.
 */
@property (nonatomic, copy) NSString *badgeTitle;

/**
 Visual representation of indentation for parent/child relationships.
 */
@property (nonatomic, assign) NSUInteger sourceHierarchyIndentation;

/**
 The current drawing rect of the label.
 */
- (CGRect)drawingRectForLabel;

@end
