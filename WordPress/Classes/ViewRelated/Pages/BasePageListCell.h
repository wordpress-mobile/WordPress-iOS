#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"

@class BasePageListCell;

typedef void(^BasePageListCellActionBlock)(BasePageListCell* _Nonnull  cell,
                                           UIButton* _Nonnull button,
                                           id<WPPostContentViewProvider> _Nonnull provider);

@interface BasePageListCell : UITableViewCell

@property (nonatomic, strong, readwrite, nullable) id<WPPostContentViewProvider>contentProvider;
@property (nonatomic, copy, readwrite, nullable) BasePageListCellActionBlock onAction;

- (void)configureCell:(nonnull id<WPPostContentViewProvider>)contentProvider;

@end
