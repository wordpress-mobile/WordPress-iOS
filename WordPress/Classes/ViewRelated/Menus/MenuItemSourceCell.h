#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
 Visual representation of indentation for parent/child relationships.
 */
@property (nonatomic, assign) NSUInteger sourceHierarchyIndentation;

/**
 The current drawing rect of the label.
 */
- (CGRect)drawingRectForLabel;

@end

NS_ASSUME_NONNULL_END
