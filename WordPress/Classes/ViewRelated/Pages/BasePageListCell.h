#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"

@class AbstractPost;
@class BasePageListCell;

typedef void(^BasePageListCellActionBlock)(BasePageListCell* _Nonnull  cell,
                                           UIButton* _Nonnull button,
                                           AbstractPost* _Nonnull post);

@interface BasePageListCell : UITableViewCell

@property (nonatomic, strong, readwrite, nullable) AbstractPost *post;
@property (nonatomic, copy, readwrite, nullable) BasePageListCellActionBlock onAction;

- (void)configureCell:(nonnull AbstractPost *)post;

@end
