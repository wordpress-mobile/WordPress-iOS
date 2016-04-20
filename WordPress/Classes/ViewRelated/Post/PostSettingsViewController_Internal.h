#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFormat,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionGeolocation
} PostSettingsSection;


@interface PostSettingsViewController ()

@property (nonatomic, strong) NSArray *sections;

@end
