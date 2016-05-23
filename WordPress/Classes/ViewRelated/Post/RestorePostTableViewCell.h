#import <UIKit/UIKit.h>
#import "ConfigurablePostView.h"
#import "InteractivePostView.h"

@protocol ConfigurablePostView;

@interface RestorePostTableViewCell : UITableViewCell <ConfigurablePostView, InteractivePostView>

@end
