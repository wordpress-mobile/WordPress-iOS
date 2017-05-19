#import <UIKit/UIKit.h>

extern CGFloat const WPTableViewFixedWidth;

@interface WPTableViewCell : UITableViewCell

/**
 Temporary flag for enabling the margins hack on cells, while views adopt readable margins.
 Note: Defaults to NO.
 */
@property (nonatomic, assign) BOOL forceCustomCellMargins;

@end
