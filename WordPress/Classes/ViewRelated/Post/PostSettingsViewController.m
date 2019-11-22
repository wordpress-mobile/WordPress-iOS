#import "PostSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"

#import "PostCategoriesViewController.h"
#import "FeaturedImageViewController.h"
#import "LocationService.h"
#import "Media.h"
#import "PostFeaturedImageCell.h"
#import "PostGeolocationCell.h"
#import "PostGeolocationViewController.h"
#import "SettingsSelectionViewController.h"
#import "SharingDetailViewController.h"
#import "PublishDatePickerView.h"
#import "WPTableViewActivityCell.h"
#import "WPTableImageSource.h"
#import "ContextManager.h"
#import "MediaService.h"
#import "WPProgressTableViewCell.h"
#import "WPAndDeviceMediaLibraryDataSource.h"
#import <WPMediaPicker/WPMediaPicker.h>
#import <Photos/Photos.h>
#import <Reachability/Reachability.h>
#import "WPGUIConstants.h"
#import <WordPressShared/NSString+XMLExtensions.h>
#import <WordPressShared/WPTextFieldTableViewCell.h>
#import "WordPress-Swift.h"

@import Gridicons;
@import WordPressShared;
@import WordPressKit;
@import WordPressUI;

typedef NS_ENUM(NSInteger, PostSettingsRow) {
    PostSettingsRowCategories = 0,
    PostSettingsRowTags,
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
    PostSettingsRowGeolocation,
    PostSettingsRowSlug,
    PostSettingsRowExcerpt
};

static CGFloat CellHeight = 44.0f;
static CGFloat LoadingIndicatorHeight = 28.0f;

static NSInteger RowIndexForDatePicker = 0;
static NSInteger RowIndexForPassword = 3;
static CGFloat LocationCellHeightToWidthAspectRatio = 0.5f;

static NSString *const TableViewActivityCellIdentifier = @"TableViewActivityCellIdentifier";
static NSString *const TableViewProgressCellIdentifier = @"TableViewProgressCellIdentifier";
static NSString *const TableViewFeaturedImageCellIdentifier = @"TableViewFeaturedImageCellIdentifier";
static NSString *const TableViewStickyPostCellIdentifier = @"TableViewStickyPostCellIdentifier";


static void *PostGeoLocationObserverContext = &PostGeoLocationObserverContext;

@interface PostSettingsViewController () <UITextFieldDelegate, WPPickerViewDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UIPopoverControllerDelegate, WPMediaPickerViewControllerDelegate,
PostCategoriesViewControllerDelegate, PostFeaturedImageCellDelegate,
FeaturedImageViewControllerDelegate>

@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *passwordVisibilityButton;
@property (nonatomic, strong) NSArray *visibilityList;
@property (nonatomic, strong) NSArray *formatsList;
@property (nonatomic, strong) WPTableImageSource *imageSource;
@property (nonatomic, strong) UIImage *featuredImage;
@property (nonatomic, strong) NSData *animatedFeaturedImageData;

@property (nonatomic, readonly) CGSize featuredImageSize;
@property (nonatomic, strong) PublishDatePickerView *datePicker;
@property (assign) BOOL textFieldDidHaveFocusBeforeOrientationChange;

@property (nonatomic, strong) WPAndDeviceMediaLibraryDataSource *mediaDataSource;
@property (nonatomic, strong) NSArray *publicizeConnections;

@property (nonatomic, strong) PostGeolocationCell *postGeoLocationCell;
@property (nonatomic, strong) WPTableViewCell *setGeoLocationCell;

@property (nonatomic, strong) NoResultsViewController *noResultsView;
@property (nonatomic, strong) NSObject *mediaLibraryChangeObserverKey;

#pragma mark - Properties: Services

@property (nonatomic, strong, readonly) BlogService *blogService;
@property (nonatomic, strong, readonly) SharingService *sharingService;
@property (nonatomic, strong, readonly) LocationService *locationService;

#pragma mark - Properties: Reachability

@property (nonatomic, strong, readwrite) Reachability *internetReachability;

@end

@implementation PostSettingsViewController

#pragma mark - Initialization and dealloc

- (void)dealloc
{
    [self.internetReachability stopNotifier];
    
    [self removePostPropertiesObserver];
    [self removeMediaObserver];
}

- (instancetype)initWithPost:(AbstractPost *)aPost
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.apost = aPost;
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Post Settings", @"The title of the Post Settings screen.");

    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    self.visibilityList = @[NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                           NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."),
                           NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    
    [self setupFormatsList];
    [self setupPublicizeConnections];

    [self.tableView registerNib:[UINib nibWithNibName:@"WPTableViewActivityCell" bundle:nil] forCellReuseIdentifier:TableViewActivityCellIdentifier];
    [self.tableView registerClass:[WPProgressTableViewCell class] forCellReuseIdentifier:TableViewProgressCellIdentifier];
    [self.tableView registerClass:[PostFeaturedImageCell class] forCellReuseIdentifier:TableViewFeaturedImageCellIdentifier];
    [self.tableView registerClass:[SwitchTableViewCell class] forCellReuseIdentifier:TableViewStickyPostCellIdentifier];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;

    // Compensate for the first section's height of 1.0f
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
    self.tableView.accessibilityIdentifier = @"SettingsTable";
    self.isUploadingMedia = NO;

    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    _blogService = [[BlogService alloc] initWithManagedObjectContext:mainContext];
    _locationService = [LocationService sharedService];
    
    // It's recommended to keep this call near the end of the initial setup, since we don't want
    // reachability callbacks to trigger before such initial setup completes.
    //
    [self setupReachability];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:YES];
    
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.apost.managedObjectContext performBlock:^{
        [self.apost.managedObjectContext save:nil];
    }];

    [self hideDatePicker];
}

- (void)didReceiveMemoryWarning
{
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if ([self.passwordTextField isFirstResponder]) {
        self.textFieldDidHaveFocusBeforeOrientationChange = YES;
    }
}

#pragma mark - Password Field

- (void)togglePasswordVisibility
{
    NSAssert(_passwordTextField, @"The password text field should be set here.");
    
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    [self refreshPasswordVisibilityButton];
}

- (void)refreshPasswordVisibilityButton
{
    NSAssert(_passwordTextField, @"The password text field should be set here.");
    NSAssert(_passwordVisibilityButton, @"The password visibility button should be set here.");
    
    UIImage *icon;
    BOOL passwordIsVisible = !self.passwordTextField.secureTextEntry;
    
    if (passwordIsVisible) {
        icon = [Gridicon iconOfType:GridiconTypeVisible];
    } else {
        icon = [Gridicon iconOfType:GridiconTypeNotVisible];
    }
    
    [self.passwordVisibilityButton setImage:icon forState:UIControlStateNormal];
    [self.passwordVisibilityButton sizeToFit];
}

#pragma mark - Additional setup

- (void)setupFormatsList
{
    self.formatsList = self.post.blog.sortedPostFormatNames;
}

- (void)setupPublicizeConnections
{
    self.publicizeConnections = self.post.blog.sortedConnections;
}

- (void)setupReachability
{
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    
    __weak __typeof(self) weakSelf = self;
    
    self.internetReachability.reachableBlock = ^void(Reachability * reachability) {
        [weakSelf internetIsReachableAgain];
    };
    
    [self.internetReachability startNotifier];
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
    } failure:^(NSError * _Nonnull error) {
        completionBlock();
    }];
}

#pragma mark - KVO

- (void)addPostPropertiesObserver
{
    [self.post addObserver:self
             forKeyPath:NSStringFromSelector(@selector(geolocation))
                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                context:PostGeoLocationObserverContext];
}

- (void)removePostPropertiesObserver
{
    [self.post removeObserver:self forKeyPath:NSStringFromSelector(@selector(geolocation))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == PostGeoLocationObserverContext && object == self.post) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }    
}

#pragma mark - Instance Methods

- (void)setApost:(AbstractPost *)apost
{
    if ([apost isEqual:_apost]) {
        return;
    }
    if (_apost) {
        [self removePostPropertiesObserver];
    }
    _apost = apost;
    [self addPostPropertiesObserver];
}

- (Post *)post
{
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    }

    return nil;
}

- (void)endEditingAction:(id)sender
{
    if (self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
    }
}

- (void)endEditingForTextFieldAction:(id)sender
{
    [self.passwordTextField endEditing:YES];
}

- (void)reloadData
{
    self.passwordTextField.text = self.apost.password;

    [self.tableView reloadData];
}


#pragma mark - TextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self hideDatePicker];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.textFieldDidHaveFocusBeforeOrientationChange) {
        self.textFieldDidHaveFocusBeforeOrientationChange = NO;
        return NO;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.passwordTextField) {
        self.apost.password = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITableView Delegate

- (void)configureSections
{
    NSNumber *stickyPostSection = @(PostSettingsSectionStickyPost);
    NSMutableArray *sections = [@[ @(PostSettingsSectionTaxonomy),
                                  @(PostSettingsSectionMeta),
                                  @(PostSettingsSectionFormat),
                                  @(PostSettingsSectionFeaturedImage),
                                  stickyPostSection,
                                  @(PostSettingsSectionShare),
                                  @(PostSettingsSectionGeolocation),
                                  @(PostSettingsSectionMoreOptions) ] mutableCopy];
    // Remove sticky post section for self-hosted non JetPack site
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
        if (self.apost.password) {
            return 4;
        }
        return 3;

    } else if (sec == PostSettingsSectionFormat) {
        return 1;

    } else if (sec == PostSettingsSectionFeaturedImage) {
        return 1;

    } else if (sec == PostSettingsSectionStickyPost) {
        return 1;
        
    } else if (sec == PostSettingsSectionShare) {
        return [self numberOfRowsForShareSection];

    } else if (sec == PostSettingsSectionGeolocation) {
        return 1;

    } else if (sec == PostSettingsSectionMoreOptions) {
        return 2;

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

    } else if (sec == PostSettingsSectionFormat) {
        return NSLocalizedString(@"Post Format", @"For setting the format of a post.");

    } else if (sec == PostSettingsSectionFeaturedImage) {
        return NSLocalizedString(@"Featured Image", @"Label for the Featured Image area in post settings.");

    } else if (sec == PostSettingsSectionStickyPost) {
        return NSLocalizedString(@"Mark as Sticky", @"Label for the Mark as Sticky option in post settings.");
        
    } else if (sec == PostSettingsSectionShare && [self numberOfRowsForShareSection] > 0) {
        return NSLocalizedString(@"Sharing", @"Label for the Sharing section in post Settings. Should be the same as WP core.");

    } else if (sec == PostSettingsSectionGeolocation) {
        return NSLocalizedString(@"Location", @"Label for the geolocation feature (tagging posts by their physical location).");
        
    } else if (sec == PostSettingsSectionMoreOptions) {
        return NSLocalizedString(@"More Options", @"Label for the More Options area in post settings. Should use the same translation as core WP.");

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
    CGFloat width = CGRectGetWidth(self.tableView.frame);
    NSInteger sectionId = [[self.sections objectAtIndex:indexPath.section] integerValue];

    if (sectionId == PostSettingsSectionGeolocation && self.post.geolocation != nil) {
        return ceilf(width * LocationCellHeightToWidthAspectRatio);
    }

    if (sectionId == PostSettingsSectionFeaturedImage) {
        if ([self isUploadingMedia]) {
            return CellHeight + (2.f * PostFeaturedImageCellMargin);
        } else if (self.featuredImage) {
            return self.featuredImageSize.height + 2.f * PostFeaturedImageCellMargin;
        } else {
            return LoadingIndicatorHeight + 2.f * PostFeaturedImageCellMargin;
        }
    }

    if (sectionId == PostSettingsSectionMeta) {
        if (indexPath.row == RowIndexForDatePicker && self.datePicker) {
            return CGRectGetHeight(self.datePicker.frame);
        } else if (indexPath.row == RowIndexForPassword) {
            return CellHeight;
        }
    }

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
    } else if (sec == PostSettingsSectionFormat) {
        cell = [self configurePostFormatCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionFeaturedImage) {
        cell = [self configureFeaturedImageCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionStickyPost) {
        cell = [self configureStickyPostCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionShare) {
        cell = [self configureShareCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionGeolocation) {
        cell = [self configureGeolocationCellForIndexPath:indexPath];
    } else if (sec == PostSettingsSectionMoreOptions) {
        cell = [self configureMoreOptionsCellForIndexPath:indexPath];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if (cell.tag == PostSettingsRowCategories) {
        [self showCategoriesSelection];
    } else if (cell.tag == PostSettingsRowTags) {
        [self showTagsPicker];
    } else if (cell.tag == PostSettingsRowPublishDate && !self.datePicker) {
        if ([Feature enabled:FeatureFlagPostScheduling]) {
            [self showPublishSchedulingController];
        } else {
            [self configureAndShowDatePicker];
        }
    } else if (cell.tag == PostSettingsRowStatus) {
        [self showPostStatusSelector];
    } else if (cell.tag == PostSettingsRowVisibility) {
        [self showPostVisibilitySelector];
    } else if (cell.tag == PostSettingsRowFormat) {
        [self showPostFormatSelector];
    } else if (cell.tag == PostSettingsRowFeaturedImage) {
        [self showFeaturedImageSelector];
    } else if (cell.tag == PostSettingsRowFeaturedImageAdd) {
        [self showFeaturedImageSelector];
    } else if (cell.tag == PostSettingsRowFeaturedImageRemove) {
        [self showFeaturedImageRemoveOrRetryActionAtIndexPath:indexPath];
    } else if (cell.tag == PostSettingsRowShareConnection) {
        [self toggleShareConnectionForIndexPath:indexPath];
    } else if (cell.tag == PostSettingsRowShareMessage) {
        [self showEditShareMessageController];
    } else if (cell.tag == PostSettingsRowGeolocation) {
        [self showPostGeolocationSelector];
    } else if (cell.tag == PostSettingsRowSlug) {
        [self showEditSlugController];
    } else if (cell.tag == PostSettingsRowExcerpt) {
        [self showEditExcerptController];
    }
}

- (NSInteger)numberOfRowsForShareSection
{
    if (self.apost.blog.supportsPublicize && self.publicizeConnections.count > 0) {
        // One row per publicize connection plus an extra row for the publicze message
        return self.publicizeConnections.count + 1;
    }
    return 0;
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

- (UITableViewCell *)configureMetaPostMetaCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == 0 && !self.datePicker) {
        // Publish date
        cell = [self getWPTableViewDisclosureCell];
        if (self.apost.dateCreated && ![self.apost shouldPublishImmediately]) {
            if ([self.apost hasFuturePublishDate]) {
                cell.textLabel.text = NSLocalizedString(@"Scheduled for", @"Scheduled for [date]");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Published on", @"Published on [date]");
            }

            cell.detailTextLabel.text = [self.apost.dateCreated shortStringWithTime];
        } else {
            cell.textLabel.text = NSLocalizedString(@"Publish", @"Label for the publish (verb) button. Tapping publishes a draft post.");
            cell.detailTextLabel.text = NSLocalizedString(@"Immediately", @"");
        }
        cell.tag = PostSettingsRowPublishDate;
    } else if (indexPath.row == 0 && self.datePicker) {
        // Date picker
        cell = [self getWPTableViewDatePickerCell];
    } else if (indexPath.row == 1) {
        // Publish Status
        cell = [self getWPTableViewDisclosureCell];
        cell.textLabel.text = NSLocalizedString(@"Status", @"The status of the post. Should be the same as in core WP.");
        cell.accessibilityIdentifier = @"Status";
        cell.detailTextLabel.text = self.apost.statusTitle;

        if ([self.apost.status isEqualToString:PostStatusPrivate]) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }

        cell.tag = PostSettingsRowStatus;

    } else if (indexPath.row == 2) {
        // Visibility
        cell = [self getWPTableViewDisclosureCell];
        cell.textLabel.text = NSLocalizedString(@"Visibility", @"The visibility settings of the post. Should be the same as in core WP.");
        cell.detailTextLabel.text = [self titleForVisibility];
        cell.tag = PostSettingsRowVisibility;
        cell.accessibilityIdentifier = @"Visibility";

    } else {
        cell = [self configurePasswordCell];
    }

    return cell;
}

- (UITableViewCell *)configurePasswordCell
{
    // Password
    WPTextFieldTableViewCell *textCell = [self getWPTableViewTextFieldCell];
    textCell.textLabel.text = NSLocalizedString(@"Password", @"Label for the password field. Should be the same as WP core.");
    textCell.textField.text = self.apost.password;
    textCell.textField.attributedPlaceholder = nil;
    textCell.textField.placeholder = NSLocalizedString(@"Enter a password", @"");
    textCell.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textCell.textField.secureTextEntry = YES;
    
    textCell.tag = PostSettingsRowPassword;
    
    self.passwordTextField = textCell.textField;
    self.passwordTextField.accessibilityIdentifier = @"Password Value";
    
    [self configureVisibilityButtonForPasswordCell:textCell];
    
    return textCell;
}

- (void)configureVisibilityButtonForPasswordCell:(WPTextFieldTableViewCell *)textCell
{
    self.passwordVisibilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.passwordVisibilityButton.tintColor = [UIColor murielNeutral20];
    [self.passwordVisibilityButton addTarget:self action:@selector(togglePasswordVisibility) forControlEvents:UIControlEventTouchUpInside];
    
    [self refreshPasswordVisibilityButton];
    
    textCell.accessoryView = self.passwordVisibilityButton;
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

- (UITableViewCell *)configureFeaturedImageCellForIndexPath:(NSIndexPath *)indexPath
{
    if (!self.apost.featuredImage && !self.isUploadingMedia) {
        return [self cellForSetFeaturedImage];

    } else if (self.isUploadingMedia || self.apost.featuredImage.remoteStatus == MediaRemoteStatusPushing) {
        // Is featured Image set on the post and it's being pushed to the server?
        if (!self.isUploadingMedia) {
            self.isUploadingMedia = YES;
            [self setupObservingOfMedia:self.apost.featuredImage];
        }
        self.featuredImage = nil;
        return [self cellForFeaturedImageUploadProgressAtIndexPath:indexPath];

    } else if (self.apost.featuredImage && self.apost.featuredImage.remoteStatus == MediaRemoteStatusFailed) {
        // Do we have an feature image set and for some reason the upload failed?
        return [self cellForFeaturedImageError];
    } else {
        NSURL *featuredURL = [self urlForFeaturedImage];
        if (!featuredURL) {
            return [self cellForSetFeaturedImage];
        }

        return [self cellForFeaturedImageWithURL:featuredURL atIndexPath:indexPath];
    }
}

- (UITableViewCell *)configureStickyPostCellForIndexPath:(NSIndexPath *)indexPath
{
    __weak __typeof(self) weakSelf = self;
    
    SwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewStickyPostCellIdentifier];
    cell.name = NSLocalizedString(@"Stick post to the front page", @"This is the cell title.");
    cell.on = self.post.isStickyPost;
    cell.onChange = ^(BOOL newValue) {
        weakSelf.post.isStickyPost = newValue;
    };
    return cell;
}

- (UITableViewCell *)cellForSetFeaturedImage
{
    WPTableViewActivityCell *activityCell = [self getWPTableViewActivityCell];
    activityCell.textLabel.text = NSLocalizedString(@"Set Featured Image", @"");
    activityCell.accessibilityIdentifier = @"SetFeaturedImage";
    activityCell.tag = PostSettingsRowFeaturedImageAdd;

    return activityCell;
}

- (UITableViewCell *)cellForFeaturedImageError
{
    WPTableViewActivityCell *activityCell = [self getWPTableViewActivityCell];
    activityCell.textLabel.text = NSLocalizedString(@"Upload failed. Tap for options.", @"Description to show on post setting for a featured image that failed to upload.");
    activityCell.tag = PostSettingsRowFeaturedImageRemove;
    return activityCell;
}

- (UITableViewCell *)cellForFeaturedImageUploadProgressAtIndexPath:(NSIndexPath *)indexPath
{
    self.progressCell = [self.tableView dequeueReusableCellWithIdentifier:TableViewProgressCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:self.progressCell];
    [self.progressCell setProgress:self.featuredImageProgress];
    self.progressCell.tag = PostSettingsRowFeaturedLoading;
    return self.progressCell;
}

- (UITableViewCell *)cellForFeaturedImageWithURL:(nonnull NSURL *)featuredURL atIndexPath:(NSIndexPath *)indexPath
{
    PostFeaturedImageCell *featuredImageCell = [self.tableView dequeueReusableCellWithIdentifier:TableViewFeaturedImageCellIdentifier forIndexPath:indexPath];
    featuredImageCell.delegate = self;
    [WPStyleGuide configureTableViewCell:featuredImageCell];

    [featuredImageCell setImageWithURL:featuredURL inPost:self.apost withSize:self.featuredImageSize];
    featuredImageCell.tag = PostSettingsRowFeaturedImage;
    return featuredImageCell;
}

- (nullable NSURL *)urlForFeaturedImage {
    NSURL *featuredURL = self.apost.featuredImage.absoluteLocalURL;

    if (!featuredURL || ![featuredURL checkResourceIsReachableAndReturnError:nil]) {
        featuredURL = [NSURL URLWithString:self.apost.featuredImage.remoteURL];
    }

    if (!featuredURL) {
        featuredURL = self.apost.featuredImageURLForDisplay;
    }
    return featuredURL;
}

- (UITableViewCell *)configureShareCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BOOL canEditSharing = [self.post canEditPublicizeSettings];

    if (indexPath.row < self.publicizeConnections.count) {
        cell = [self getWPTableViewImageAndAccessoryCell];
        PublicizeConnection *connection = self.publicizeConnections[indexPath.row];
        UIImage *image = [WPStyleGuide iconForService: connection.service];
        [cell.imageView setImage:image];
        if (canEditSharing) {
            cell.imageView.tintColor = [WPStyleGuide tintColorForConnectedService: connection.service];
        }
        cell.textLabel.text = connection.externalDisplay;
        cell.textLabel.enabled = canEditSharing;
        if (connection.isBroken) {
            cell.accessoryView = [WPStyleGuide sharingCellWarningAccessoryImageView];
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
    } else {
        cell = [self getWPTableViewDisclosureCell];
        cell.textLabel.text = NSLocalizedString(@"Message", @"Label for the share message field on the post settings.");
        cell.textLabel.enabled = canEditSharing;
        cell.detailTextLabel.text = self.post.publicizeMessage ? self.post.publicizeMessage : self.post.titleForDisplay;
        cell.detailTextLabel.enabled = canEditSharing;
        cell.tag = PostSettingsRowShareMessage;
        cell.accessibilityIdentifier = @"Customize the message";
    }
    cell.userInteractionEnabled = canEditSharing;
    return cell;
}

- (PostGeolocationCell *)postGeoLocationCell {
    if (!_postGeoLocationCell) {
        _postGeoLocationCell = [[PostGeolocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            _postGeoLocationCell.tag = PostSettingsRowGeolocation;
    }
    Coordinate *coordinate = self.post.geolocation;
    NSString *address = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");
    if (coordinate) {
        CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        if ([self.locationService hasAddressForLocation:postLocation]) {
            address = self.locationService.lastGeocodedAddress;
        } else {
            address = NSLocalizedString(@"Looking up address...", @"Used with posts that are geo-tagged. Let's the user know the the app is looking up the address for the coordinates tagging the post.");
            __weak __typeof__(self) weakSelf = self;
            [self.locationService getAddressForLocation:postLocation
                                                        completion:^(CLLocation *location, NSString *address, NSError *error) {
                                                            [weakSelf.tableView reloadData];
                                                        }];
            
        }
    }
    [_postGeoLocationCell setCoordinate:coordinate andAddress:address];
    return _postGeoLocationCell;
}

- (WPTableViewCell *)setGeoLocationCell {
    if (!_setGeoLocationCell) {
        _setGeoLocationCell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        _setGeoLocationCell.accessoryType = UITableViewCellAccessoryNone;
        _setGeoLocationCell.textLabel.text = NSLocalizedString(@"Set Location", @"Label for cell that allow users to set the location of a post");
        _setGeoLocationCell.tag = PostSettingsRowGeolocation;
        _setGeoLocationCell.textLabel.textAlignment = NSTextAlignmentCenter;
        [WPStyleGuide configureTableViewActionCell:_setGeoLocationCell];
    }
    return _setGeoLocationCell;
}

- (UITableViewCell *)configureGeolocationCellForIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell;
    if (self.post.geolocation == nil) {
        return self.setGeoLocationCell;
    } else {
        return self.postGeoLocationCell;
    }
    return cell;
}

- (UITableViewCell *)configureMoreOptionsCellForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
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

- (WPTableViewCell *)getWPTableViewDisclosureCell
{
    static NSString *WPTableViewDisclosureCellIdentifier = @"WPTableViewDisclosureCellIdentifier";
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WPTableViewDisclosureCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:WPTableViewDisclosureCellIdentifier];
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

- (WPTableViewCell *)getWPTableViewDatePickerCell
{
    static NSString *WPTableViewDatePickerCellIdentifier = @"WPTableViewDatePickerCellIdentifier";
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WPTableViewDatePickerCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:WPTableViewDatePickerCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [WPStyleGuide configureTableViewCell:cell];
        CGRect frame = self.datePicker.frame;
        frame.size.width = cell.contentView.frame.size.width;
        self.datePicker.frame = frame;
        [cell.contentView addSubview:self.datePicker];
    }
    cell.tag = PostSettingsRowPublishDate;
    return cell;
}

- (WPTableViewActivityCell *)getWPTableViewActivityCell
{
    WPTableViewActivityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewActivityCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [WPStyleGuide configureTableViewActionCell:cell];

    cell.tag = 0;
    return cell;
}

- (WPTextFieldTableViewCell *)getWPTableViewTextFieldCell
{
    static NSString *WPTextFieldCellIdentifier = @"WPTextFieldCellIdentifier";
    WPTextFieldTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:WPTextFieldCellIdentifier];
    if (!cell) {
        cell = [[WPTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:WPTextFieldCellIdentifier];
        cell.textField.returnKeyType = UIReturnKeyDone;
        cell.textField.delegate = self;
        [WPStyleGuide configureTableViewTextCell:cell];
        if ([self.view userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight) {
            cell.textField.textAlignment = NSTextAlignmentRight;
        } else {
            cell.textField.textAlignment = NSTextAlignmentLeft;
        }
    }
    cell.tag = 0;
    return cell;
}

- (void)hideDatePicker
{
    if (!self.datePicker) {
        return;
    }
    self.datePicker = nil;

    // Reload the whole section since other rows might be affected by any change.
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:[self.sections indexOfObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]]];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
}

- (void)configureAndShowDatePicker
{
    NSDate *date;
    if (self.apost.dateCreated) {
        date = self.apost.dateCreated;
    } else {
        date = [NSDate date];
    }

    self.datePicker = [[PublishDatePickerView alloc] initWithDate:date];
    self.datePicker.delegate = self;
    CGRect frame = self.datePicker.frame;
    if (IS_IPAD) {
        frame.size.width = WPTableViewFixedWidth;
    } else {
        frame.size.width = CGRectGetWidth(self.tableView.bounds);
    }
    self.datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.datePicker.frame = frame;

    NSUInteger sec = [self.sections indexOfObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:RowIndexForDatePicker inSection:sec];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showPublishSchedulingController
{
    ImmuTableViewController *vc = [PublishSettingsController viewControllerWithPost:self.apost];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPostStatusSelector
{
    if ([self.apost.status isEqualToString:PostStatusPrivate]) {
        return;
    }

    NSArray *statuses = [self.apost availableStatusesForEditing];
    NSArray *titles = [statuses wp_map:^id(NSString *status) {
        return [AbstractPost titleForStatus:status];
    }];

    NSDictionary *statusDict = @{
                                 @"DefaultValue": [self.apost availableStatusForPublishOrScheduled],
                                 @"Title" : NSLocalizedString(@"Status", nil),
                                 @"Titles" : titles,
                                 @"Values" : statuses,
                                 @"CurrentValue" : self.apost.status
                                 };
    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:statusDict];
    __weak SettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *status) {
        self.apost.status = status;
        [weakVc dismiss];
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPostVisibilitySelector
{
    NSArray *titles = @[
                        NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                        NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."),
                        NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")
                        ];
    NSDictionary *visiblityDict = @{
                                    @"DefaultValue": NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                                    @"Title" : NSLocalizedString(@"Visibility", nil),
                                    @"Titles" : titles,
                                    @"Values" : titles,
                                    @"CurrentValue" : [self titleForVisibility]};
    SettingsSelectionViewController *vc = [[SettingsSelectionViewController alloc] initWithDictionary:visiblityDict];
    __weak SettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *visibility) {
        [weakVc dismiss];
        
        NSAssert(self.apost != nil, @"The post should not be nil here.");
        NSAssert(!self.apost.isFault, @"The post should not be a fault here here.");
        NSAssert(self.apost.managedObjectContext != nil, @"The post's MOC should not be nil here.");

        if ([visibility isEqualToString:NSLocalizedString(@"Private", @"Post privacy status in the Post Editor/Settings area (compare with WP core translations).")]) {
            self.apost.status = PostStatusPrivate;
            self.apost.password = nil;
        } else {
            if ([self.apost.status isEqualToString:PostStatusPrivate]) {
                if ([self.apost.original.status isEqualToString:PostStatusPrivate]) {
                    self.apost.status = PostStatusPublish;
                } else {
                    // restore the original status
                    self.apost.status = self.apost.original.status;
                }
            }
            if ([visibility isEqualToString:NSLocalizedString(@"Password protected", @"Post password protection in the Post Editor/Settings area (compare with WP core translations).")]) {
                
                NSString *password = @"";
                
                NSAssert(self.apost.original != nil,
                         @"We're expecting to have a reference to the original post here.");
                NSAssert(!self.apost.original.isFault,
                         @"The original post should not be a fault here here.");
                NSAssert(self.apost.original.managedObjectContext != nil,
                         @"The original post's MOC should not be nil here.");
                
                if (self.apost.original.password) {
                    // restore the original password
                    password = self.apost.original.password;
                }
                self.apost.password = password;
            } else {
                self.apost.password = nil;
            }
        }

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
            } else {
                [self.post disablePublicizeConnectionWithKeyringID:connection.keyringConnectionID];
            }
        }
    }
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

- (void)showPostGeolocationSelector
{
    PostGeolocationViewController *controller = [[PostGeolocationViewController alloc] initWithPost:self.post locationService:self.locationService];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showFeaturedImageSelector
{
    if (self.apost.featuredImage) {
        // Check if the featured image is set, otherwise we don't want to do anything while it's still loading.
        if (self.featuredImage) {
            FeaturedImageViewController *featuredImageVC;
            if (self.animatedFeaturedImageData) {
                featuredImageVC = [[FeaturedImageViewController alloc] initWithGifData:self.animatedFeaturedImageData];
            } else {
                featuredImageVC = [[FeaturedImageViewController alloc] initWithImage:self.featuredImage];
            }

            featuredImageVC.delegate = self;

            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:featuredImageVC];
            [self presentViewController:navigationController animated:YES completion:nil];
        } else if ([self urlForFeaturedImage] == nil) {
            //If we don't have a featured image url, the image won't be loaded.
            [self showMediaPicker];
        }
    } else {
        if (!self.isUploadingMedia) {
            [self showMediaPicker];
        }
    }
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
        self.apost.mt_excerpt = value;
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMediaPicker
{
    WPMediaPickerOptions *options = [WPMediaPickerOptions new];
    options.showMostRecentFirst = YES;
    options.allowMultipleSelection = NO;
    options.filter = WPMediaTypeImage;
    options.showSearchBar = YES;
    options.badgedUTTypes = [NSSet setWithObject: (__bridge NSString *)kUTTypeGIF];
    options.preferredStatusBarStyle = UIStatusBarStyleLightContent;
    WPNavigationMediaPickerViewController *picker = [[WPNavigationMediaPickerViewController alloc] initWithOptions:options];

    WPAndDeviceMediaLibraryDataSource *mediaDataSource = [[WPAndDeviceMediaLibraryDataSource alloc] initWithPost:self.apost
                                                                                           initialDataSourceType:MediaPickerDataSourceTypeMediaLibrary];

    picker.dataSource = mediaDataSource;
    picker.delegate = self;
    [self registerChangeObserverForPicker:picker.mediaPicker];

    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:picker animated:YES completion:nil];

    self.mediaDataSource = mediaDataSource;
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
        self.post.tags = value;
    };
    [self.navigationController pushViewController:tagsPicker animated:YES];
}

- (CGSize)featuredImageSize
{
    CGFloat width = CGRectGetWidth(self.view.frame);
    width = width - (PostFeaturedImageCellMargin * 2); // left and right cell margins
    CGFloat height = ceilf(width * 0.66);
    return CGSizeMake(width, height);
}

- (void)featuredImageFailedLoading:(NSIndexPath *)indexPath withError:(NSError *)error
{
    DDLogError(@"Error loading featured image: %@", error);
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.text = NSLocalizedString(@"Featured Image did not load", @"");
}

- (NSString *)titleForVisibility
{
    if (self.apost.password) {
        return NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP.");
    } else if ([self.apost.status isEqualToString:PostStatusPrivate]) {
        return NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.");
    }

    return NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP.");
}

- (NoResultsViewController *)noResultsView
{
    if (!_noResultsView) {
        _noResultsView = [NoResultsViewController controller];
    }
    return _noResultsView;
}

- (void)registerChangeObserverForPicker:(WPMediaPickerViewController *)picker
{
    NSAssert(self.mediaLibraryChangeObserverKey == nil, nil);
    __weak PostSettingsViewController * weakSelf = self;
    self.mediaLibraryChangeObserverKey = [self.mediaDataSource registerChangeObserverBlock:^(BOOL incrementalChanges, NSIndexSet * _Nonnull removed, NSIndexSet * _Nonnull inserted, NSIndexSet * _Nonnull changed, NSArray<id<WPMediaMove>> * _Nonnull moves) {

        [weakSelf updateSearchBarForPicker:picker];
        BOOL isNotSearching = [weakSelf.mediaDataSource.searchQuery isEmpty];
        BOOL hasNoAsset = [weakSelf.mediaDataSource numberOfAssets] == 0;

        if (hasNoAsset && isNotSearching) {
            [weakSelf.noResultsView removeFromView];
            [weakSelf.noResultsView configureForNoAssetsWithUserCanUploadMedia:NO];
        }
    }];
}

- (void)unregisterChangeObserver
{
    if (self.mediaLibraryChangeObserverKey) {
        [self.mediaDataSource unregisterChangeObserver:self.mediaLibraryChangeObserverKey];
        self.mediaLibraryChangeObserverKey = nil;
    }
}

- (void)updateSearchBarForPicker:(WPMediaPickerViewController *)picker
{
    if (self.mediaDataSource.dataSourceType != MediaPickerDataSourceTypeMediaLibrary) {
        [picker hideSearchBar];
        return;
    }

    NSString *searchQuery = self.mediaDataSource.searchQuery;
    BOOL isSearching = (searchQuery != nil) && ![searchQuery isEmpty];
    BOOL hasAsset = [self.mediaDataSource numberOfAssets] > 0;

    if (hasAsset || isSearching) {
        [picker showSearchBar];
        if (self.mediaDataSource.dataSourceType == MediaPickerDataSourceTypeMediaLibrary) {
            [WPStyleGuide configureSearchBar:picker.searchBar];
        }
    } else {
        [picker hideSearchBar];
    }
}

#pragma mark - WPPickerView Delegate

- (void)pickerView:(WPPickerView *)pickerView didChangeValue:(id)value
{
    [self handleDateChange:value];
}

- (void)pickerView:(WPPickerView *)pickerView didFinishWithValue:(id)value
{
    [self handleDateChange:value];
    [self hideDatePicker];
}

- (void)handleDateChange:(id)value
{
    if (value == nil) {
        // Publish Immediately
        [self.apost publishImmediately];
    } else {
        // Compare via timeIntervalSinceDate to let us ignore subsecond variation.
        NSDate *startingDate = (NSDate *)self.datePicker.startingValue;
        NSDate *selectedDate = (NSDate *)value;
        NSTimeInterval interval = [startingDate timeIntervalSinceDate:selectedDate];
        if (fabs(interval) < 1.0) {
            return;
        }
        
        self.apost.dateCreated = selectedDate;
        
        if ([self isFutureDated:selectedDate]) {
            self.apost.status = PostStatusScheduled;
        }
    }
}

- (BOOL)isFutureDated:(NSDate *)date {
    
    if (date == nil) {
        return NO;
    }
    
    NSComparisonResult comparison = [NSCalendar.currentCalendar compareDate:[NSDate date] toDate:date toUnitGranularity:NSCalendarUnitMinute];
    
    return comparison == NSOrderedAscending;
}

#pragma mark - WPMediaPickerViewControllerDelegate methods

- (UIViewController *)emptyViewControllerForMediaPickerController:(WPMediaPickerViewController *)picker
{
    return self.noResultsView;
}

- (void)mediaPickerControllerWillBeginLoadingData:(WPMediaPickerViewController *)picker
{
    [self updateSearchBarForPicker:picker];
    [self.noResultsView configureForFetching];
}

- (void)mediaPickerControllerDidEndLoadingData:(WPMediaPickerViewController *)picker
{
    [self updateSearchBarForPicker:picker];
    [self.noResultsView removeFromView];
    [self.noResultsView configureForNoAssetsWithUserCanUploadMedia:NO];
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didUpdateSearchWithAssetCount:(NSInteger)assetCount
{
    [self.noResultsView removeFromView];
  
    if (self.mediaDataSource.searchQuery.wordCount > 0) {
        [self.noResultsView configureForNoSearchResult];
    }
}

- (void)mediaPickerController:(WPMediaPickerViewController *)picker didFinishPickingAssets:(NSArray *)assets
{
    if (assets.count == 0 ){
        return;
    }

    [self unregisterChangeObserver];
    [self.mediaDataSource searchCancelled];

    if ([[assets firstObject] isKindOfClass:[PHAsset class]]){
        PHAsset *asset = [assets firstObject];
        self.isUploadingMedia = YES;
        [self setFeaturedImageWithAsset:asset];
    } else if ([[assets firstObject] isKindOfClass:[Media class]]){
        Media *media = [assets firstObject];
        [self setFeaturedImageWithMedia:media];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];

    // Reload the featured image row so that way the activity indicator will be displayed.
    NSIndexPath *featureImageCellPath = [NSIndexPath indexPathForRow:0 inSection:[self.sections indexOfObject:@(PostSettingsSectionFeaturedImage)]];
    [self.tableView reloadRowsAtIndexPaths:@[featureImageCellPath]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)mediaPickerControllerDidCancel:(WPMediaPickerViewController *)picker {
    [self unregisterChangeObserver];
    [self.mediaDataSource searchCancelled];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PostCategoriesViewControllerDelegate

- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didUpdateSelectedCategories:(NSSet *)categories
{
    // Save changes.
    self.post.categories = [categories mutableCopy];
    [self.post save];
}

#pragma mark - PostFeaturedImageCellDelegate

- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingAnimatedImageWithData:(NSData *)animationData
{
    if (self.animatedFeaturedImageData == nil) {
        self.animatedFeaturedImageData = animationData;
        [self updateFeaturedImageCell:cell];
    }
}

- (void)postFeatureImageCellDidFinishLoadingImage:(PostFeaturedImageCell *)cell
{
    self.animatedFeaturedImageData = nil;
    if (!self.featuredImage) {
        [self updateFeaturedImageCell:cell];
    }
}

- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingImageWithError:(NSError *)error
{
    self.featuredImage = nil;
    if (error) {
        NSIndexPath *featureImageCellPath = [NSIndexPath indexPathForRow:0 inSection:[self.sections indexOfObject:@(PostSettingsSectionFeaturedImage)]];
        [self featuredImageFailedLoading:featureImageCellPath withError:error];
    }
}

- (void)updateFeaturedImageCell:(PostFeaturedImageCell *)cell
{
    self.featuredImage = cell.image;
    cell.accessibilityIdentifier = @"Current Featured Image";
    NSInteger featuredImageSection = [self.sections indexOfObject:@(PostSettingsSectionFeaturedImage)];
    NSIndexSet *featuredImageSectionSet = [NSIndexSet indexSetWithIndex:featuredImageSection];
    [self.tableView reloadSections:featuredImageSectionSet withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - FeaturedImageViewControllerDelegate

- (void)FeaturedImageViewControllerOnRemoveImageButtonPressed:(FeaturedImageViewController *)controller
{
    self.featuredImage = nil;
    self.animatedFeaturedImageData = nil;
    [self.apost setFeaturedImage:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
