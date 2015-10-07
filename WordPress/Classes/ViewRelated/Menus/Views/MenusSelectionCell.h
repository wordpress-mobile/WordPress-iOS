#import "MenusCell.h"

extern CGFloat const MenusSelectionCellDefaultHeight;

@interface MenusSelectionCell : MenusCell

- (NSString *)selectionSubtitleText;
- (NSString *)selectionTitleText;
- (NSAttributedString *)attributedDisplayText;

@end
