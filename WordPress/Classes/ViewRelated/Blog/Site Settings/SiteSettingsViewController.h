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

/// The resolved third-party blocks capability, cached for the current reload pass.
///
/// Resolving reads the keychain, and the section list, cell, and footer each need the value while
/// the table is being built, so it is resolved once and reused. Returns a raw
/// `ThirdPartyBlocksCapabilityValue`; the caller in `SiteSettingsViewController+Swift` wraps it
/// back into the enum.
- (NSInteger)thirdPartyBlocksCapabilityValue;

// General Settings: These were made available here to help with the transition to Swift.

- (void)showLanguageSelectorForBlog:(Blog *)blog;

@end
