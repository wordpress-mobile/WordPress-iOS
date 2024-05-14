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

@property (nullable, nonatomic, strong) NSProgress *featuredImageProgress;

@property (nonatomic, assign) BOOL isUploadingMedia;

@property (nullable, nonatomic, strong) NSUUID *mediaObserverReceipt;

@property (nullable, nonatomic, strong) WPProgressTableViewCell *progressCell;

@end
