#import <UIKit/UIKit.h>

@interface NotificationSettingsViewController : UITableViewController

@property (nonatomic, strong) NSMutableDictionary *notificationPreferences;
@property (nonatomic, strong) NSMutableDictionary *notificationMutePreferences;
@property (nonatomic, strong) NSMutableArray *notificationPrefArray;
@property (nonatomic, strong) NSMutableArray *mutedBlogsArray;
@property (nonatomic, assign) BOOL showCloseButton;
@property (nonatomic, strong) UIBarButtonItem *muteUnmuteBarButton;

- (void)notificationSettingChanged:(id)sender;
- (void)muteBlogSettingChanged:(id)sender;
- (void)getNotificationSettings;
- (void)reloadNotificationSettings;

@end
