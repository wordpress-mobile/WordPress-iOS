#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionShare,
    PostSettingsSectionStickyPost,
    PostSettingsSectionDisabledTwitter, // NOTE: Clean up when Twitter has been removed from Publicize services.
    PostSettingsSectionSharesRemaining,
    PostSettingsSectionGeolocation,
    PostSettingsSectionMoreOptions,
    PostSettingsSectionPageAttributes
} PostSettingsSection;


@class WPProgressTableViewCell;

@interface PostSettingsViewController ()

@property (nonnull, nonatomic, strong) NSArray *sections;

@end
