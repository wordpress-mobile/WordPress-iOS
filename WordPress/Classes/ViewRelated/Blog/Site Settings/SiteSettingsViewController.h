#import <UIKit/UIKit.h>

@class Blog;
@class SettingTableViewCell;
@class TimeZoneObserver;

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, strong,  readonly) Blog *blog;
@property (nonatomic, strong) TimeZoneObserver *timeZoneObserver;

- (instancetype)initWithBlog:(Blog *)blog;

- (void)saveSettings;

// General Settings: These were made available here to help with the transition to Swift.
#pragma mark - General Settings Section

@property (nonatomic, strong) SettingTableViewCell *siteTitleCell;
@property (nonatomic, strong) SettingTableViewCell *siteTaglineCell;
@property (nonatomic, strong) SettingTableViewCell *addressTextCell;
@property (nonatomic, strong) SettingTableViewCell *privacyTextCell;
@property (nonatomic, strong) SettingTableViewCell *languageTextCell;
@property (nonatomic, strong) SettingTableViewCell *timezoneTextCell;

- (void)showEditSiteTitleController;
- (void)showEditSiteTaglineController;
- (void)showPrivacySelector;
- (void)showLanguageSelectorForBlog:(Blog *)blog;

@end
