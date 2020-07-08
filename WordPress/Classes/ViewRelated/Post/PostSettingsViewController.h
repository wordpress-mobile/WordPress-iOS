#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;
- (void)endEditingAction:(nullable id)sender;

@property (nonatomic, assign) BOOL isBVOrder;
@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;

@end
