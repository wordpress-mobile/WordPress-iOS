#import <UIKit/UIKit.h>
@import WordPressData;

@interface PostSettingsViewController : UITableViewController

- (nonnull instancetype)initWithPost:(nonnull AbstractPost *)aPost;

@property (nonnull, nonatomic, strong, readonly) AbstractPost *apost;
@property (nonatomic) BOOL isStandalone;
@property (nonnull, nonatomic, strong, readonly) NSArray *publicizeConnections;
@property (nonnull, nonatomic, strong, readonly) NSArray *unsupportedConnections;

- (void)reloadData;

@end
