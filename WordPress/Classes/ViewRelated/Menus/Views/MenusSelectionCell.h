#import <UIKit/UIKit.h>

extern CGFloat const MenusSelectionCellDefaultHeight;

@interface MenusSelectionCell : UITableViewCell

- (NSString *)selectionSubtitleText;
- (NSString *)selectionTitleText;
- (NSAttributedString *)attributedDisplayText;

@end
