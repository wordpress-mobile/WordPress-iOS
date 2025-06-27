#import "PostSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "SettingsSelectionViewController.h"
#import "SharingDetailViewController.h"
#import "MediaService.h"
#ifdef KEYSTONE
#import "Keystone-Swift.h"
#else
#import "WordPress-Swift.h"
#endif
@import WordPressData;

@import Gridicons;
@import WordPressShared;
@import WordPressKit;
@import WordPressUI;

typedef NS_ENUM(NSInteger, PostSettingsRow) {
    PostSettingsRowCategories = 0,
    PostSettingsRowTags,
    PostSettingsRowAuthor,
    PostSettingsRowPublishDate,
    PostSettingsRowPendingReview,
    PostSettingsRowVisibility,
    PostSettingsRowFormat,
    PostSettingsRowFeaturedImage,
    PostSettingsRowSlug,
    PostSettingsRowExcerpt,
    PostSettingsRowParentPage
};

static NSString *const PostSettingsAnalyticsTrackingSource = @"post_settings";
static NSString *const TableViewFeaturedImageCellIdentifier = @"TableViewFeaturedImageCellIdentifier";
static NSString *const TableViewToggleCellIdentifier = @"TableViewToggleCellIdentifier";
static NSString *const TableViewGenericCellIdentifier = @"TableViewGenericCellIdentifier";


@interface PostSettingsViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UIPopoverControllerDelegate,
PostCategoriesViewControllerDelegate>

@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) NSArray *postMetaSectionRows;

@property (nonatomic, strong) NSArray *publicizeConnections;
@property (nonatomic, strong) NSArray<PublicizeConnection *> *unsupportedConnections;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *enabledConnections;

@property (nonatomic, strong) NSDateFormatter *postDateFormatter;

#pragma mark - Properties: Services

@property (nonatomic, strong, readonly) SharingService *sharingService;

@end

@implementation PostSettingsViewController

#pragma mark - Initialization and dealloc

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.apost = aPost;
        self.unsupportedConnections = @[];
        self.enabledConnections = [NSMutableArray array];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self.apost isKindOfClass:[Page class]]) {
        self.title = NSLocalizedString(@"Page Settings", @"The title of the Page Settings screen.");
    } else {
        self.title = NSLocalizedString(@"Post Settings", @"The title of the Post Settings screen.");
    }

    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    [self setupPublicizeConnections];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewFeaturedImageCellIdentifier];
    [self.tableView registerClass:[SwitchTableViewCell class] forCellReuseIdentifier:TableViewToggleCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewGenericCellIdentifier];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;

    // Compensate for the first section's height of 1.0f
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
    self.tableView.accessibilityIdentifier = @"SettingsTable";

    [self setupPostDateFormatter];

    [WPAnalytics track:WPAnalyticsStatPostSettingsShown];

    [self onViewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES];

    [self setupPublicizeConnections]; // Refresh in case the user disconnects from unsupported services.
    [self configureMetaSectionRows];
    [self reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self.tableView sizeToFitFooterView];
}

- (void)didReceiveMemoryWarning
{
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark - Additional setup

- (void)setupPublicizeConnections
{
    // Separate Twitter connections if the service is unsupported.
    PublicizeService *twitterService = [PublicizeService lookupPublicizeServiceNamed:@"twitter"
                                                                           inContext:self.apost.managedObjectContext];

    if (!twitterService || [twitterService isSupported]) {
        return;
    }

    NSMutableArray<PublicizeConnection *> *supportedConnections = [NSMutableArray new];
    NSMutableArray<PublicizeConnection *> *unsupportedConnections = [NSMutableArray new];
    for (PublicizeConnection *connection in self.post.blog.sortedConnections) {
        if ([connection.service isEqualToString:twitterService.serviceID]) {
            [unsupportedConnections addObject:connection];
            continue;
        }

        [supportedConnections addObject:connection];

        if (![self.post publicizeConnectionDisabledForKeyringID:connection.keyringConnectionID]
            && ![self.enabledConnections containsObject:connection.keyringConnectionID]) {
            [self.enabledConnections addObject:connection.keyringConnectionID];
        }
    }

    self.publicizeConnections = supportedConnections;
    self.unsupportedConnections = unsupportedConnections;
}

- (void)setupPostDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.timeZone = [self.apost.blog timeZone];
    self.postDateFormatter = dateFormatter;
}

// sync the latest state of Twitter.
- (void)syncPublicizeServices
{
    __weak __typeof(self) weakSelf = self;
    [self.sharingService syncPublicizeServicesForBlog:self.apost.blog success:^{
        [weakSelf setupPublicizeConnections];
    } failure:nil];
}

#pragma mark - Instance Methods

- (void)setApost:(AbstractPost *)apost
{
    if ([apost isEqual:_apost]) {
        return;
    }
    _apost = apost;
}

- (Post *)post
{
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    }

    return nil;
}

- (void)reloadData
{
    [self configureSections];
    [self.tableView reloadData];
}

#pragma mark - UITableView Delegate

- (void)configureSections
{
    NSNumber *stickyPostSection = @(PostSettingsSectionStickyPost);
    NSMutableArray *sections = [@[ @(PostSettingsSectionMeta),
                                   @(PostSettingsSectionFeaturedImage),
                                   @(PostSettingsSectionTaxonomy),
                                   stickyPostSection,
                                   @(PostSettingsSectionMoreOptions) ] mutableCopy];
    // Remove sticky post section for self-hosted non Jetpack site
    // and non admin user
    //
    if (![self.apost.blog supports:BlogFeatureWPComRESTAPI] && !self.apost.blog.isAdmin) {
        [sections removeObject:stickyPostSection];
    }

    self.sections = [sections copy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!self.sections) {
        [self configureSections];
    }
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == PostSettingsSectionTaxonomy) {
        return 2;
    } else if (sec == PostSettingsSectionMeta) {
        return [self.postMetaSectionRows count];
    } else if (sec == PostSettingsSectionFeaturedImage) {
        return 1;
    } else if (sec == PostSettingsSectionStickyPost) {
        return 1;
    } else if (sec == PostSettingsSectionMoreOptions) {
        return 3;
    } else if (sec == PostSettingsSectionPageAttributes) {
        return 1;
    }

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == PostSettingsSectionTaxonomy) {
        return NSLocalizedString(@"Taxonomy", @"Label for the Taxonomy area (categories, keywords, ...) in post settings.");

    } else if (sec == PostSettingsSectionMeta) {
        return NSLocalizedString(@"Publish", @"Label for the publish (verb) button. Tapping publishes a draft post.");

    } else if (sec == PostSettingsSectionFeaturedImage) {
        return NSLocalizedString(@"Featured Image", @"Label for the Featured Image area in post settings.");

    } else if (sec == PostSettingsSectionStickyPost) {
        return NSLocalizedString(@"Mark as Sticky", @"Label for the Mark as Sticky option in post settings.");

    } else if (sec == PostSettingsSectionMoreOptions) {
        return NSLocalizedString(@"More Options", @"Label for the More Options area in post settings. Should use the same translation as core WP.");

    } else if (sec == PostSettingsSectionPageAttributes) {
        return NSLocalizedStringWithDefaultValue(@"postSettings.section.pageAttributes", nil, [NSBundle mainBundle], @"Page Attributes", @"Section title for Page Attributes");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return CGFLOAT_MIN;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return CGFLOAT_MIN;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];

    UITableViewCell *cell;

    if (sec == PostSettingsSectionTaxonomy) {
        cell = [self configureTaxonomyCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionMeta) {
        cell = [self configureMetaPostMetaCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionFeaturedImage) {
        cell = [self makeFeaturedImageCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionStickyPost) {
        cell = [self configureStickyPostCellForIndexPath:indexPath];
    } if (sec == PostSettingsSectionMoreOptions) {
        cell = [self configureMoreOptionsCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionPageAttributes) {
        cell = [self configurePageAttributesCellForIndexPath:indexPath];
    }

    return cell ?: [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];

    if (cell.tag == PostSettingsRowCategories) {
        [self showCategoriesSelection];
    } else if (cell.tag == PostSettingsRowTags) {
        [self showTagsPicker];
    } else if (cell.tag == PostSettingsRowPublishDate) {
        [self showPublishDatePicker];
    } else if (cell.tag == PostSettingsRowVisibility) {
        [self showPostVisibilitySelector];
    } else if (cell.tag == PostSettingsRowAuthor) {
        [self showPostAuthorSelector];
    } else if (cell.tag == PostSettingsRowFormat) {
        [self showPostFormatSelector];
    } else if (cell.tag == PostSettingsRowSlug) {
        [self showEditSlugController];
    } else if (cell.tag == PostSettingsRowExcerpt) {
        [self showEditExcerptController];
    } else if (cell.tag == PostSettingsRowParentPage) {
        [self showParentPageController];
    }
}

- (UITableViewCell *)configureTaxonomyCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self getWPTableViewDisclosureCell];

    if (indexPath.row == PostSettingsRowCategories) {
        // Categories
        cell.textLabel.text = NSLocalizedString(@"Categories", @"Label for the categories field. Should be the same as WP core.");
        cell.detailTextLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
        cell.tag = PostSettingsRowCategories;
        cell.accessibilityIdentifier = @"Categories";

    } else if (indexPath.row == PostSettingsRowTags) {
        // Tags
        cell.textLabel.text = NSLocalizedString(@"Tags", @"Label for the tags field. Should be the same as WP core.");
        cell.detailTextLabel.text = self.post.tags;
        cell.tag = PostSettingsRowTags;
        cell.accessibilityIdentifier = @"Tags";
    }

    return cell;
}

- (void)configureMetaSectionRows
{
    NSMutableArray *metaRows = [[NSMutableArray alloc] init];

    if (self.isDraftOrPending) {
        [metaRows addObject:@(PostSettingsRowPendingReview)];
    } else {
        [metaRows addObjectsFromArray:@[
            @(PostSettingsRowPublishDate),
            @(PostSettingsRowVisibility)
        ]];
    }

    self.postMetaSectionRows = [metaRows copy];
}

- (UITableViewCell *)configureMetaPostMetaCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSInteger row = [[self.postMetaSectionRows objectAtIndex:indexPath.row] integerValue];

    if (row == PostSettingsRowAuthor) {
        // Author
        cell = [self getWPTableViewDisclosureCell];
        cell.textLabel.text = NSLocalizedString(@"Author", @"The author of the post or page.");
        cell.accessibilityIdentifier = @"SetAuthor";
        cell.detailTextLabel.text = [self.apost authorNameForDisplay];
        cell.tag = PostSettingsRowAuthor;
    } else if (row == PostSettingsRowPublishDate) {
        // Publish date
        cell = [self getWPTableViewDisclosureCellWithIdentifier:@"PostSettingsRowPublishDate"];
        cell.textLabel.text = NSLocalizedString(@"Publish Date", @"Label for the publish date button.");
        if (self.apost.dateCreated) {
            cell.detailTextLabel.text = [self.postDateFormatter stringFromDate:self.apost.dateCreated];
        } else {
            // Should never happen as this field is displayed only for published/scheduled posts
            cell.detailTextLabel.text = @"";
        }

        if ([self.apost.status isEqualToString:PostStatusPrivate]) {
            [cell disable];
        } else {
            [cell enable];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        cell.tag = PostSettingsRowPublishDate;
    } else if (row == PostSettingsRowVisibility) {
        // Visibility
        cell = [self getWPTableViewDisclosureCellWithIdentifier:@"PostSettingsRowVisibility"];
        cell.textLabel.text = NSLocalizedString(@"Visibility", @"The visibility settings of the post. Should be the same as in core WP.");
        cell.detailTextLabel.text = [self.apost titleForVisibility];
        cell.tag = PostSettingsRowVisibility;
        cell.accessibilityIdentifier = @"Visibility";

    } else if (row == PostSettingsRowPendingReview) {
        // Pending Review
        __weak __typeof(self) weakSelf = self;
        SwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewToggleCellIdentifier];
        cell.name = NSLocalizedStringWithDefaultValue(@"postSettings.pendingReview", nil, [NSBundle mainBundle], @"Pending review", @"The 'Pending Review' setting of the post");
        cell.on = [self.post.status isEqualToString:PostStatusPending];
        cell.onChange = ^(BOOL newValue) {
            [WPAnalytics trackEvent:WPAnalyticsEventEditorPostPendingReviewChanged properties:@{@"via": @"settings"}];
            weakSelf.post.status = newValue ? PostStatusPending : PostStatusDraft;
        };
        return cell;
    }

    return cell;
}

- (UITableViewCell *)configurePostFormatCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self getWPTableViewDisclosureCell];

    cell.textLabel.text = NSLocalizedString(@"Post Format", @"The post formats available for the post. Should be the same as in core WP.");

    if (self.post.postFormatText.length > 0) {
        cell.detailTextLabel.text = self.post.postFormatText;
    } else {
        cell.detailTextLabel.text = NSLocalizedString(@"Unavailable",
                                                      @"Message to show in the post-format cell when the post format is not available");
    }

    cell.tag = PostSettingsRowFormat;
    cell.accessibilityIdentifier = @"Post Format";
    return cell;
}

- (UITableViewCell *)makeFeaturedImageCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewFeaturedImageCellIdentifier forIndexPath:indexPath];
    // [self configureFeaturedImageCellWithCell:cell viewModel:self.featuredImageViewModel];
    cell.tag = PostSettingsRowFeaturedImage;
    return cell;
}

- (UITableViewCell *)configureStickyPostCellForIndexPath:(NSIndexPath *)indexPath
{
    __weak __typeof(self) weakSelf = self;

    SwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewToggleCellIdentifier];
    cell.name = NSLocalizedString(@"Stick post to the front page", @"This is the cell title.");
    cell.on = self.post.isStickyPost;
    cell.onChange = ^(BOOL newValue) {
        [WPAnalytics trackEvent:WPAnalyticsEventEditorPostStickyChanged properties:@{@"via": @"settings"}];
        weakSelf.post.isStickyPost = newValue;
    };
    return cell;
}

- (UITableViewCell *)configureMoreOptionsCellForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return [self configurePostFormatCellForIndexPath:indexPath];
    } else if (indexPath.row == 1) {
        return [self configureSlugCellForIndexPath:indexPath];
    } else {
        return [self configureExcerptCellForIndexPath:indexPath];
    }
}

- (UITableViewCell *)configureSlugCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [self getWPTableViewDisclosureCell];
    cell.textLabel.text = NSLocalizedString(@"Slug", @"Label for the slug field. Should be the same as WP core.");
    cell.detailTextLabel.text = self.apost.slugForDisplay;
    cell.tag = PostSettingsRowSlug;
    cell.accessibilityIdentifier = @"Slug";
    return cell;
}

- (UITableViewCell *)configureExcerptCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [self getWPTableViewDisclosureCell];
    cell.textLabel.text = NSLocalizedString(@"Excerpt", @"Label for the excerpt field. Should be the same as WP core.");
    cell.detailTextLabel.text = self.apost.mt_excerpt;
    cell.tag = PostSettingsRowExcerpt;
    cell.accessibilityIdentifier = @"Excerpt";
    return cell;
}

- (WPTableViewCell *)getWPTableViewDisclosureCell {
    return [self getWPTableViewDisclosureCellWithIdentifier:@"WPTableViewDisclosureCellIdentifier"];
}

- (WPTableViewCell *)getWPTableViewDisclosureCellWithIdentifier:(NSString *)identifier
{
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [WPStyleGuide configureTableViewCell:cell];
    }
    cell.tag = 0;
    return cell;
}

- (void)showEditSlugController
{
    SettingsMultiTextViewController *vc = [[SettingsMultiTextViewController alloc] initWithText:self.apost.slugForDisplay
                                                                                    placeholder:nil
                                                                                           hint:NSLocalizedString(@"The slug is the URL-friendly version of the post title.", @"Should be the same as the text displayed if the user clicks the (i) in Slug in Calypso.")
                                                                                     isPassword:NO];
    vc.title = NSLocalizedString(@"Slug", @"Label for the slug field. Should be the same as WP core.");
    vc.autocapitalizationType = UITextAutocapitalizationTypeNone;
    vc.onValueChanged = ^(NSString *value) {
        [WPAnalytics trackEvent:WPAnalyticsEventEditorPostSlugChanged properties:@{@"via": @"settings"}];
        self.apost.wp_slug = value;
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showEditExcerptController
{
    SettingsMultiTextViewController *vc = [[SettingsMultiTextViewController alloc] initWithText:self.apost.mt_excerpt
                                                                                    placeholder:nil
                                                                                           hint:NSLocalizedString(@"Excerpts are optional hand-crafted summaries of your content.", @"Should be the same as the text displayed if the user clicks the (i) in Calypso.")
                                                                                     isPassword:NO];
    vc.title = NSLocalizedString(@"Excerpt", @"Label for the excerpt field. Should be the same as WP core.");
    vc.onValueChanged = ^(NSString *value) {
        if (self.apost.mt_excerpt != value) {
            [WPAnalytics trackEvent:WPAnalyticsEventEditorPostExcerptChanged properties:@{@"via": @"settings"}];
        }

        self.apost.mt_excerpt = value;
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showCategoriesSelection
{
    PostCategoriesViewController *controller = [[PostCategoriesViewController alloc] initWithBlog:self.post.blog
                                                                                 currentSelection:[self.post.categories allObjects]
                                                                                    selectionMode:CategoriesSelectionModePost];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

// MARK: - Page Attributes

- (UITableViewCell *)configurePageAttributesCellForIndexPath:(NSIndexPath *)indexPath
{
    return [self configureParentPageCell];
}

- (UITableViewCell *)configureParentPageCell
{
    UITableViewCell *cell = [self getWPTableViewDisclosureCell];
    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"postSettings.parentPage", nil, [NSBundle mainBundle], @"Parent page", @"The 'Parent Page' setting of the post");
    cell.detailTextLabel.text = [self getParentPageTitle];
    cell.tag = PostSettingsRowParentPage;
    cell.accessibilityIdentifier = @"Parent";
    return cell;
}

#pragma mark - PostCategoriesViewControllerDelegate

- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didUpdateSelectedCategories:(NSSet *)categories
{
    [WPAnalytics trackEvent:WPAnalyticsEventEditorPostCategoryChanged properties:@{@"via": @"settings"}];

    // Save changes.
    self.post.categories = [categories mutableCopy];
    if (!self.isStandalone) {
        [self.post save];
    }
}

@end
