#import <UIKit/UIKit.h>

@class Blog;
@class SettingTableViewCell;
@class BlogSettingsChanges;

typedef NS_ENUM(NSInteger, SiteSettingsSection) {
    SiteSettingsSectionGeneral = 0,
    SiteSettingsSectionBlogging,
    SiteSettingsSectionHomepage,
    SiteSettingsSectionAccount,
    SiteSettingsSectionBlockEditor,
    SiteSettingsSectionThemeStyles,
    SiteSettingsSectionWriting,
    SiteSettingsSectionMedia,
    SiteSettingsSectionDiscussion,
    SiteSettingsSectionTraffic,
    SiteSettingsSectionJetpackSettings,
    SiteSettingsSectionAdvanced,
};

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, strong,  readonly) Blog *blog;

- (instancetype)initWithBlog:(Blog *)blog;

- (void)saveSettingsWithChanges:(BlogSettingsChanges *)changes;

// General Settings: These were made available here to help with the transition to Swift.

- (void)showLanguageSelectorForBlog:(Blog *)blog;

@end
