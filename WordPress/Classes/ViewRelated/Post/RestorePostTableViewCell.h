#import <UIKit/UIKit.h>
#import "ConfigurablePostView.h"
#import "WordPress-Swift.h"

@protocol ConfigurablePostView;

@interface RestorePostTableViewCell : UITableViewCell <ConfigurablePostView, InteractivePostView>

@end
