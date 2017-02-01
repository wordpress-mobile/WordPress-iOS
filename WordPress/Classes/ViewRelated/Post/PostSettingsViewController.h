#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;
- (void)endEditingAction:(nullable id)sender;

@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;
@end
