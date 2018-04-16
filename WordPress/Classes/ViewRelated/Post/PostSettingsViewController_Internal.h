#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFormat,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionShare,
    PostSettingsSectionGeolocation,
    PostSettingsSectionMoreOptions
} PostSettingsSection;


@interface PostSettingsViewController ()

@property (nonnull, nonatomic, strong) NSArray *sections;

@property (nullable, nonatomic, strong) NSProgress *featuredImageProgress;

@property (nonatomic, assign) BOOL isUploadingMedia;

@end
