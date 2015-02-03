#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

- (instancetype)initWithPost:(AbstractPost *)aPost shouldHideStatusBar:(BOOL)shouldHideStatusBar;
- (void)endEditingAction:(id)sender;

@property (nonatomic, strong, readonly) AbstractPost *apost;
@end
