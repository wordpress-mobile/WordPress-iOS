#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

@property (nonatomic, strong) NSString *statsPrefix;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)endEditingAction:(id)sender;

@end
