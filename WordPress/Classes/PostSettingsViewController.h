#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

- (id)initWithPost:(AbstractPost *)aPost;
- (void)endEditingAction:(id)sender;

@end
