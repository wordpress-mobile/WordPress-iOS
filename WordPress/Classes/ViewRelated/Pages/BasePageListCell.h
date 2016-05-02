#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"

@class AbstractPost;
@class BasePageListCell;

/// A block that represents an action triggered by tapping on a button in a cell.
///
/// @param      cell        The cell that contains the button that was tapped.
/// @param      button      The button that was tapped.
/// @param      post        The post represented by the cell that was tapped.
///
typedef void(^BasePageListCellActionBlock)(BasePageListCell* _Nonnull cell,
                                           UIButton* _Nonnull button,
                                           AbstractPost* _Nonnull post);

/// A base cell to represent a page object.
///
@interface BasePageListCell : UITableViewCell

/// The post represented by this cell.
///
@property (nonatomic, strong, readwrite, nullable) AbstractPost *post;

/// The block that will be executed when the main button inside this cell is tapped.
///
@property (nonatomic, copy, readwrite, nullable) BasePageListCellActionBlock onAction;

/// Configure the cell to represent the specified post.
///
- (void)configureCell:(nonnull AbstractPost *)post;

@end
