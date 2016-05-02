#import <UIKit/UIKit.h>
#import "WPPostContentViewProvider.h"


@protocol BasePageListCellDelegate <NSObject>
@optional
- (void)cell:(nonnull UITableViewCell *)cell receivedMenuActionFromButton:(nonnull UIButton *)button forProvider:(nonnull id<WPPostContentViewProvider>)contentProvider;
- (void)cell:(nonnull UITableViewCell *)cell receivedRestoreActionForProvider:(nonnull id<WPPostContentViewProvider>)contentProvider;
@end


@interface BasePageListCell : UITableViewCell

@property (nonatomic, strong, readwrite, nullable) id<WPPostContentViewProvider>contentProvider;
@property (nonatomic, assign, readwrite, nullable) id<BasePageListCellDelegate> delegate;

- (void)configureCell:(nonnull id<WPPostContentViewProvider>)contentProvider;

@end
