#import "PostSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"
#import "Media.h"
#import "SettingsSelectionViewController.h"
#import "SharingDetailViewController.h"
#import "CoreDataStack.h"
#import "MediaService.h"
#import "WordPress-Swift.h"

@import Gridicons;
@import WordPressShared;
@import WordPressKit;
@import WordPressUI;
@import Reachability;

typedef NS_ENUM(NSInteger, PostSettingsRow) {
    PostSettingsRowCategories = 0,
    PostSettingsRowTags,
    PostSettingsRowAuthor,
    PostSettingsRowPublishDate,
    PostSettingsRowPendingReview,
    PostSettingsRowVisibility,
    PostSettingsRowFormat,
    PostSettingsRowFeaturedImage,
    PostSettingsRowShareConnection,
    PostSettingsRowShareMessage,
    PostSettingsRowSlug,
    PostSettingsRowExcerpt,
    PostSettingsRowSocialNoConnections,
    PostSettingsRowSocialRemainingShares,
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
@property (nonatomic, strong) NSArray *formatsList;

@property (nonatomic, strong) NSArray *publicizeConnections;
@property (nonatomic, strong) NSArray<PublicizeConnection *> *unsupportedConnections;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *enabledConnections;

@property (nonatomic, strong) NSDateFormatter *postDateFormatter;

@property (nonatomic, strong) PostSettingsFeaturedImageViewModel *featuredImageViewModel;

#pragma mark - Properties: Services

@property (nonatomic, strong, readonly) BlogService *blogService;
@property (nonatomic, strong, readonly) SharingService *sharingService;

#pragma mark - Properties: Reachability

@property (nonatomic, strong, readwrite) Reachability *internetReachability;

@end

@implementation PostSettingsViewController

#pragma mark - Initialization and dealloc

- (void)dealloc
{
    [self.internetReachability stopNotifier];
}

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.apost = aPost;
        self.unsupportedConnections = @[];
        self.enabledConnections = [NSMutableArray array];
        self.featuredImageViewModel = [[PostSettingsFeaturedImageViewModel alloc] initWithPost:aPost];
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

    [self setupFormatsList];
    [self setupPublicizeConnections];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewFeaturedImageCellIdentifier];
    [self.tableView registerClass:[SwitchTableViewCell class] forCellReuseIdentifier:TableViewToggleCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewGenericCellIdentifier];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;

    // Compensate for the first section's height of 1.0f
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
    self.tableView.accessibilityIdentifier = @"SettingsTable";

    self.featuredImageViewModel.tableView = self.tableView;
    self.featuredImageViewModel.delegate = self.featuredImageDelegate;

    _blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];

    [self setupPostDateFormatter];

    [WPAnalytics track:WPAnalyticsStatPostSettingsShown];

    // It's recommended to keep this call near the end of the initial setup, since we don't want
    // reachability callbacks to trigger before such initial setup completes.
    //
    [self setupReachability];
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

- (void)setupFormatsList
{
    self.formatsList = self.post.blog.sortedPostFormatNames;
}

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

- (void)setupReachability
{
    self.internetReachability = [Reachability reachabilityForInternetConnection];

    __weak __typeof(self) weakSelf = self;

    self.internetReachability.reachableBlock = ^void(Reachability * __unused reachability) {
        [weakSelf internetIsReachableAgain];
    };

    [self.internetReachability startNotifier];
}

- (void)setupPostDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.timeZone = [self.apost.blog timeZone];
    self.postDateFormatter = dateFormatter;
}

#pragma mark - Reachability handling

- (void)internetIsReachableAgain
{
    [self synchUnavailableData];
}

- (void)synchUnavailableData
{
    __weak __typeof(self) weakSelf = self;

    if (self.formatsList.count == 0) {
        [self synchPostFormatsAndDo:^{
            // DRM: if we ever start synchronizing anything else that could affect the table data
            // aside from the post formats, we will need reload the table view only once all of the
            // synchronization calls complete.
            //
            [[weakSelf tableView] reloadData];
        }];
    }
}

- (void)synchPostFormatsAndDo:(void(^)(void))completionBlock
{
    __weak __typeof(self) weakSelf = self;

    [self.blogService syncPostFormatsForBlog:self.apost.blog success:^{
        [weakSelf setupFormatsList];
        completionBlock();
    } failure:^(NSError * _Nonnull __unused error) {
        completionBlock();
    }];
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
    NSNumber *disabledTwitterSection = @(PostSettingsSectionDisabledTwitter);
    NSNumber *remainingSharesSection = @(PostSettingsSectionSharesRemaining);
    NSNumber *shareSection = @(PostSettingsSectionShare);
    NSMutableArray *sections = [@[ @(PostSettingsSectionMeta),
                                   @(PostSettingsSectionFeaturedImage),
                                   @(PostSettingsSectionTaxonomy),
                                   stickyPostSection,
                                   shareSection,
                                   disabledTwitterSection,
                                   remainingSharesSection,
                                   @(PostSettingsSectionMoreOptions) ] mutableCopy];
    // Remove sticky post section for self-hosted non Jetpack site
    // and non admin user
    //
    if (![self.apost.blog supports:BlogFeatureWPComRESTAPI] && !self.apost.blog.isAdmin) {
        [sections removeObject:stickyPostSection];
    }

    if (self.unsupportedConnections.count == 0) {
        [sections removeObject:disabledTwitterSection];
    }

    if ([self numberOfRowsForShareSection] == 0) {
        [sections removeObject:shareSection];
    }

    if (![self showRemainingShares]) {
        [sections removeObject:remainingSharesSection];
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
    } else if (sec == PostSettingsSectionShare) {
        return [self numberOfRowsForShareSection];
    } else if (sec == PostSettingsSectionDisabledTwitter) {
        return self.unsupportedConnections.count;
    } else if (sec == PostSettingsSectionSharesRemaining) {
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

    } else if (sec == PostSettingsSectionShare && [self numberOfRowsForShareSection] > 0) {
        return NSLocalizedString(@"Jetpack Social", @"Label for the Sharing section in post Settings. Should be the same as WP core.");

    } else if (sec == PostSettingsSectionDisabledTwitter) {
        return NSLocalizedStringWithDefaultValue(@"postSettings.section.disabledTwitter.header",
                                                 nil,
                                                 [NSBundle mainBundle],
                                                 @"Twitter Auto-Sharing Is No Longer Available",
                                                 @"Section title for the disabled Twitter service in the Post Settings screen");

    } else if (sec == PostSettingsSectionMoreOptions) {
        return NSLocalizedString(@"More Options", @"Label for the More Options area in post settings. Should use the same translation as core WP.");

    } else if (sec == PostSettingsSectionPageAttributes) {
        return NSLocalizedStringWithDefaultValue(@"postSettings.section.pageAttributes", nil, [NSBundle mainBundle], @"Page Attributes", @"Section title for Page Attributes");
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == PostSettingsSectionDisabledTwitter) {
        TwitterDeprecationTableFooterView *footerView = [[TwitterDeprecationTableFooterView alloc] init];
        footerView.presentingViewController = self;
        footerView.source = @"post_settings";

        return footerView;
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
    } else if (sec == PostSettingsSectionShare || sec == PostSettingsSectionDisabledTwitter) {
        cell = [self showNoConnection] ? [self configureNoConnectionCell] : [self configureShareCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionSharesRemaining) {
        cell = [self configureRemainingSharesCell];
    } else if (sec == PostSettingsSectionMoreOptions) {
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
    } else if (sec == PostSettingsSectionDisabledTwitter) {
        [self showShareDetailForIndexPath:indexPath];
    } else if (cell.tag == PostSettingsRowShareConnection) {
        [self toggleShareConnectionForIndexPath:indexPath];
    } else if (cell.tag == PostSettingsRowShareMessage) {
        [self showEditShareMessageController];
    } else if (cell.tag == PostSettingsRowSlug) {
        [self showEditSlugController];
    } else if (cell.tag == PostSettingsRowExcerpt) {
        [self showEditExcerptController];
    } else if (cell.tag == PostSettingsRowParentPage) {
        [self showParentPageController];
    }
}

- (NSInteger)numberOfRowsForShareSection
{
    if ([self.apost.status isEqualToString:@"private"]) {
        return 0;
    }

    if (self.apost.blog.supportsPublicize && self.publicizeConnections.count > 0) {
        // One row per publicize connection plus an extra row for the publicze message
        return self.publicizeConnections.count + 1;
    }
    return [self showNoConnection] ? 1 : 0;
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

    if (self.apost.isMultiAuthorBlog) {
        [metaRows addObject:@(PostSettingsRowAuthor)];
    }

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
    [self configureFeaturedImageCellWithCell:cell viewModel:self.featuredImageViewModel];
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

- (UITableViewCell *)configureSocialCellForIndexPath:(NSIndexPath *)indexPath
                                          connection:(PublicizeConnection *)connection
                                      canEditSharing:(BOOL)canEditSharing
                                             section:(NSInteger)section
{
    UITableViewCell *cell = [self getWPTableViewImageAndAccessoryCell];
    UIImage *image = [[WPStyleGuide socialIconFor:connection.service] resizedTo:CGSizeMake(28.0, 28.0) format: ScalingModeScaleAspectFill];
    [cell.imageView setImage:image];
    cell.imageView.alpha = 1.0;
    if (!canEditSharing) {
        cell.imageView.alpha = 0.36;
    }
    cell.textLabel.text = connection.externalDisplay;
    cell.textLabel.enabled = canEditSharing;
    if (connection.isBroken) {
        cell.accessoryView = section == PostSettingsSectionShare ?
        [WPStyleGuide sharingCellWarningAccessoryImageView] :
        [WPStyleGuide sharingCellErrorAccessoryImageView];
    } else {
        UISwitch *switchAccessory = [[UISwitch alloc] initWithFrame:CGRectZero];
        // This interaction is handled at a cell level
        switchAccessory.userInteractionEnabled = NO;
        switchAccessory.on = ![self.post publicizeConnectionDisabledForKeyringID:connection.keyringConnectionID];
        switchAccessory.enabled = canEditSharing;
        cell.accessoryView = switchAccessory;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.tag = PostSettingsRowShareConnection;
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"%@ %@", connection.service, connection.externalDisplay];
    return cell;
}

- (UITableViewCell *)configureDisclosureCellWithSharing:(BOOL)canEditSharing
{
    UITableViewCell *cell = [self getWPTableViewDisclosureCell];
    cell.textLabel.text = NSLocalizedString(@"Message", @"Label for the share message field on the post settings.");
    cell.textLabel.enabled = canEditSharing;
    cell.detailTextLabel.text = self.post.publicizeMessage ? self.post.publicizeMessage : self.post.titleForDisplay;
    cell.detailTextLabel.enabled = canEditSharing;
    cell.tag = PostSettingsRowShareMessage;
    cell.accessibilityIdentifier = @"Customize the message";
    return cell;
}

- (UITableViewCell *)configureShareCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BOOL canEditSharing = [self userCanEditSharing];
    NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];
    NSArray<PublicizeConnection *> *connections = sec == PostSettingsSectionShare ? self.publicizeConnections : self.unsupportedConnections;

    if (indexPath.row < connections.count) {
        PublicizeConnection *connection = connections[indexPath.row];
        if ([RemoteFeature enabled:RemoteFeatureFlagJetpackSocialImprovements]) {
            BOOL hasRemainingShares = self.enabledConnections.count < [self remainingSocialShares];
            BOOL isSwitchOn = ![self.post publicizeConnectionDisabledForKeyringID:connection.keyringConnectionID];
            canEditSharing = canEditSharing && (hasRemainingShares || isSwitchOn);
        }
        cell = [self configureSocialCellForIndexPath:indexPath
                                          connection:connection
                                      canEditSharing:canEditSharing
                                             section:sec];
    } else {
        cell = [self configureDisclosureCellWithSharing:canEditSharing];
    }
    cell.userInteractionEnabled = canEditSharing;
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

- (WPTableViewCell *)getWPTableViewImageAndAccessoryCell
{
    static NSString *WPTableViewImageAndAccesoryCellIdentifier = @"WPTableViewImageAndAccesoryCellIdentifier";
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WPTableViewImageAndAccesoryCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:WPTableViewImageAndAccesoryCellIdentifier];
        [WPStyleGuide configureTableViewCell:cell];
    }
    cell.accessoryView = nil;
    cell.imageView.image = nil;
    cell.tag = 0;
    return cell;
}

- (void)showPostAuthorSelector
{
    PostAuthorSelectorViewController *vc = [[PostAuthorSelectorViewController alloc] init:self.apost];
    __weak PostAuthorSelectorViewController *weakVc = vc;
    vc.completion = ^{
        [WPAnalytics trackEvent:WPAnalyticsEventEditorPostAuthorChanged properties:@{@"via": @"settings"}];
        [weakVc dismiss];
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPostFormatSelector
{
    Post *post      = self.post;
    NSArray *titles = post.blog.sortedPostFormatNames;

    if (![self.internetReachability isReachable] && self.formatsList.count == 0) {
        [self showCantShowPostFormatsAlert];
        return;
    }

    if (post == nil || titles.count == 0 || post.postFormatText == nil || self.formatsList.count == 0) {
        return;
    }
    NSDictionary *(^postFormatsDictionary)(NSArray *) = ^NSDictionary *(NSArray *titles) {
        return @{
                 SettingsSelectionDefaultValueKey   : [titles firstObject],
                 SettingsSelectionTitleKey          : NSLocalizedString(@"Post Format", nil),
                 SettingsSelectionTitlesKey         : titles,
                 SettingsSelectionValuesKey         : titles,
                 SettingsSelectionCurrentValueKey   : post.postFormatText
                 };;
    };

    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:postFormatsDictionary(titles)];
    __weak SettingsSelectionViewController *weakVc = vc;
    __weak __typeof(self) weakSelf = self;
    __weak Post *weakPost = post;
    vc.onItemSelected = ^(NSString *status) {
        // Check if the object passed is indeed an NSString, otherwise we don't want to try to set it as the post format
        if ([status isKindOfClass:[NSString class]]) {
            [WPAnalytics trackEvent:WPAnalyticsEventEditorPostFormatChanged properties:@{@"via": @"settings"}];
            post.postFormatText = status;
            [weakVc dismiss];
            [self.tableView reloadData];
        }
    };
    vc.onRefresh = ^(UIRefreshControl *refreshControl) {
        [weakSelf synchPostFormatsAndDo:^{
            NSArray *titles = weakPost.blog.sortedPostFormatNames;
            if (titles.count) {
                [weakVc reloadWithDictionary:postFormatsDictionary(titles)];
            }
            [refreshControl endRefreshing];
        }];
    };
    vc.invokesRefreshOnViewWillAppear = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showCantShowPostFormatsAlert
{
    NSString *title = NSLocalizedString(@"Connection not available",
                                        @"Title of a prompt saying the app needs an internet connection before it can load post formats");

    NSString *message = NSLocalizedString(@"Please check your internet connection and try again.",
                                          @"Politely asks the user to check their internet connection before trying again. ");

    NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Title of a button that dismisses a prompt");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addCancelActionWithTitle:cancelButtonTitle handler:nil];

    [alertController presentFromRootViewController];
}

- (void)toggleShareConnectionForIndexPath:(NSIndexPath *) indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BOOL isJetpackSocialEnabled = [RemoteFeature enabled:RemoteFeatureFlagJetpackSocialImprovements];
    if (indexPath.row < self.publicizeConnections.count) {
        PublicizeConnection *connection = self.publicizeConnections[indexPath.row];
        if (connection.isBroken) {
            SharingDetailViewController *controller = [[SharingDetailViewController alloc] initWithBlog:self.post.blog
                                                                                    publicizeConnection:connection];
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
            [cellSwitch setOn:!cellSwitch.on animated:YES];
            if (cellSwitch.on) {
                [self.post enablePublicizeConnectionWithKeyringID:connection.keyringConnectionID];

                if (isJetpackSocialEnabled) {
                    [self.enabledConnections addObject:connection.keyringConnectionID];
                    [self reloadSocialSectionComparingValue:[self remainingSocialShares]];
                }
            } else {
                [self.post disablePublicizeConnectionWithKeyringID:connection.keyringConnectionID];

                if (isJetpackSocialEnabled) {
                    [self.enabledConnections removeObject:connection.keyringConnectionID];
                    [self reloadSocialSectionComparingValue:[self remainingSocialShares] - 1];
                }
            }
            if (isJetpackSocialEnabled) {
                [WPAnalytics trackEvent:WPAnalyticsEventJetpackSocialConnectionToggled
                             properties:@{@"source": PostSettingsAnalyticsTrackingSource,
                                          @"value": cellSwitch.on ? @"true" : @"false"}];
            }
        }
    }
}

- (void)showShareDetailForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.unsupportedConnections.count) {
        return;
    }

    PublicizeConnection *connection = self.unsupportedConnections[indexPath.row];
    SharingDetailViewController *controller = [[SharingDetailViewController alloc] initWithBlog:self.apost.blog
                                                                            publicizeConnection:connection];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showEditShareMessageController
{
    NSString *text = !self.post.publicizeMessage ? self.post.titleForDisplay : self.post.publicizeMessage;

    SettingsMultiTextViewController *vc = [[SettingsMultiTextViewController alloc] initWithText:text
                                                                                    placeholder:nil
                                                                                           hint:NSLocalizedString(@"Customize the message you want to share.\nIf you don't add your own text here, we'll use the post's title as the message.", @"Hint displayed when the user is customizing the share message.")
                                                                                     isPassword:NO];
    vc.title = NSLocalizedString(@"Customize the message", @"Title for the edition of the share message.");
    vc.onValueChanged = ^(NSString *value) {
        if (value.length) {
            self.post.publicizeMessage = value;
        } else {
            self.post.publicizeMessage = nil;
        }
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
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


- (void)showTagsPicker
{
    PostTagPickerViewController *tagsPicker = [[PostTagPickerViewController alloc] initWithTags:self.post.tags blog:self.post.blog];

    tagsPicker.onValueChanged = ^(NSString * _Nonnull value) {
        [WPAnalytics trackEvent:WPAnalyticsEventEditorPostTagsChanged properties:@{@"via": @"settings"}];

        self.post.tags = value;
    };

    [WPAnalytics track:WPAnalyticsStatPostSettingsAddTagsShown];

    [self.navigationController pushViewController:tagsPicker animated:YES];
}

#pragma mark - Jetpack Social

- (UITableViewCell *)configureGenericCellWith:(UIView *)view {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewGenericCellIdentifier];
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    [cell.contentView addSubview:view];
    [cell.contentView pinSubviewToAllEdges:view];
    return cell;
}

- (UITableViewCell *)configureNoConnectionCell
{
    UITableViewCell *cell = [self configureGenericCellWith:[self createNoConnectionView]];
    cell.tag = PostSettingsRowSocialNoConnections;
    return cell;
}

- (UITableViewCell *)configureRemainingSharesCell
{
    UITableViewCell *cell = [self configureGenericCellWith:[self createRemainingSharesView]];
    cell.tag = PostSettingsRowSocialRemainingShares;
    return cell;
}

- (void)reloadSocialSectionComparingValue:(NSUInteger)value
{
    if (self.enabledConnections.count == value) {
        NSUInteger sharingSection = [self.sections indexOfObject:@(PostSettingsSectionShare)];
        NSIndexSet *sharingSectionSet = [NSIndexSet indexSetWithIndex:sharingSection];
        [self.tableView reloadSections:sharingSectionSet withRowAnimation:UITableViewRowAnimationNone];
    }
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
