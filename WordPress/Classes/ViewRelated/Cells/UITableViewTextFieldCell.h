#import <Foundation/Foundation.h>
#import "WPTableViewCell.h"

@class UITableViewTextFieldCell;

@protocol UITableViewTextFieldCellDelegate <NSObject>
- (void)cellWantsToSelectNextField:(UITableViewTextFieldCell *)cell;
@optional
- (void)cellTextDidChange:(UITableViewTextFieldCell *)cell;
@end

@interface UITableViewTextFieldCell : WPTableViewCell
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) BOOL shouldDismissOnReturn;
@property (nonatomic, weak) id<UITableViewTextFieldCellDelegate> delegate;
@property (nonatomic, assign) CGFloat minimumLabelWidth;
@end
