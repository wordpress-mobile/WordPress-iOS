#import <UIKit/UIKit.h>

@class AbstractPost;
@class BasePageListCell;

NS_ASSUME_NONNULL_BEGIN

/// A block that represents an action triggered by tapping on a button in a cell.
///
/// @param      cell        The cell that contains the button that was tapped.
/// @param      button      The button that was tapped.
/// @param      post        The post represented by the cell that was tapped.
///
typedef void(^BasePageListCellActionBlock)(BasePageListCell* cell,
                                           UIButton* button,
                                           AbstractPost* post);

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
- (void)configureCell:(AbstractPost *)post;

@end

NS_ASSUME_NONNULL_END
