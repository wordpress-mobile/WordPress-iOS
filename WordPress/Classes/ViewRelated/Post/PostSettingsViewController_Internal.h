#import "PostSettingsViewController.h"

typedef enum {
    PostSettingsSectionTaxonomy = 0,
    PostSettingsSectionMeta,
    PostSettingsSectionFormat,
    PostSettingsSectionFeaturedImage,
    PostSettingsSectionStickyPost,
    PostSettingsSectionShare,
    PostSettingsSectionGeolocation,
    PostSettingsSectionMoreOptions
} PostSettingsSection;

typedef NS_ENUM(NSInteger, PostSettingsRow) {
    PostSettingsRowCategories = 0,
    PostSettingsRowTags,
    PostSettingsRowAuthor,
    PostSettingsRowPublishDate,
    PostSettingsRowStatus,
    PostSettingsRowVisibility,
    PostSettingsRowPassword,
    PostSettingsRowFormat,
    PostSettingsRowFeaturedImage,
    PostSettingsRowFeaturedImageAdd,
    PostSettingsRowFeaturedImageRemove,
    PostSettingsRowFeaturedLoading,
    PostSettingsRowShareConnection,
    PostSettingsRowShareMessage,
    PostSettingsRowSlug,
    PostSettingsRowExcerpt,
    PostSettingsRowParent
};


@class WPProgressTableViewCell;

@interface PostSettingsViewController ()

@property (nonatomic, nonnull, strong) NSArray *postMetaSectionRows;

@property (nonnull, nonatomic, strong) NSArray *sections;

@property (nullable, nonatomic, strong) NSProgress *featuredImageProgress;

@property (nonatomic, assign) BOOL isUploadingMedia;

@property (nullable, nonatomic, strong) NSUUID *mediaObserverReceipt;

@property (nullable, nonatomic, strong) WPProgressTableViewCell *progressCell;

- (nonnull WPTableViewCell *)getWPTableViewDisclosureCell;
- (void)configureMetaSectionRows;
- (nonnull UITableViewCell *)configureMetaPostMetaCellForIndexPath:(nonnull NSIndexPath *)indexPath;

@end
