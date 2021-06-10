#import <UIKit/UIKit.h>

@class Blog;
@class SettingTableViewCell;
@class TimeZoneObserver;

typedef NS_ENUM(NSInteger, SiteSettingsSection) {
    SiteSettingsSectionGeneral = 0,
    SiteSettingsSectionHomepage,
    SiteSettingsSectionAccount,
    SiteSettingsSectionEditor,
    SiteSettingsSectionWriting,
    SiteSettingsSectionMedia,
    SiteSettingsSectionDiscussion,
    SiteSettingsSectionTraffic,
    SiteSettingsSectionJetpackSettings,
    SiteSettingsSectionAdvanced,
};

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, strong,  readonly) Blog *blog;
@property (nonatomic, strong) TimeZoneObserver *timeZoneObserver;

- (instancetype)initWithBlog:(Blog *)blog;

- (void)saveSettings;

// General Settings: These were made available here to help with the transition to Swift.

- (void)showPrivacySelector;
- (void)showLanguageSelectorForBlog:(Blog *)blog;

@end
