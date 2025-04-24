#import <Foundation/Foundation.h>

@class WPTableViewCell;
@class WPTextFieldTableViewCell;

@protocol WPTextFieldTableViewCellDelegate <NSObject>

- (void)cellWantsToSelectNextField:(WPTextFieldTableViewCell *)cell;
@optional
- (void)cellTextDidChange:(WPTextFieldTableViewCell *)cell;

@end

@interface WPTextFieldTableViewCell : WPTableViewCell

@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, assign) BOOL shouldDismissOnReturn;
@property (nonatomic, weak) id<WPTextFieldTableViewCellDelegate> delegate;

@end
