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
    SiteSettingsSectionThirdPartyBlocks,
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

/// Rebuilds the section list and reloads the table.
///
/// Editor capabilities are fetched asynchronously and decide which editor rows are shown and
/// whether they're interactive, so the table has to be rebuilt once they arrive.
- (void)reloadSections;

// General Settings: These were made available here to help with the transition to Swift.

- (void)showLanguageSelectorForBlog:(Blog *)blog;

@end
