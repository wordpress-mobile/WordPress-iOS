#import "WPTableViewCell.h"

@class WPContentViewBase;

@interface AbstractPostTableViewCell : WPTableViewCell

@property(nonatomic, strong) WPContentViewBase *postView;

- (WPContentViewBase *)configurePostView;

@end
