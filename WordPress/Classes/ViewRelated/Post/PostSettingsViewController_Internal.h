#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionStickyPost,
    PostSettingsSectionGeolocation,
    PostSettingsSectionMoreOptions,
    PostSettingsSectionPageAttributes
} PostSettingsSection;

@interface PostSettingsViewController ()

@property (nonnull, nonatomic, strong) NSArray *sections;

@end
