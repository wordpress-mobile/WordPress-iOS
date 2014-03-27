/*
 * PostSettingsViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "PostSettingsViewController.h"
#import "PostSettingsViewController_Internal.h"

#import "CategoriesViewController.h"
#import "EditPostViewController_Internal.h"
#import "FeaturedImageViewController.h"
#import "LocationService.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"
#import "Post.h"
#import "PostFeaturedImageCell.h"
#import "PostGeolocationCell.h"
#import "PostGeolocationViewController.h"
#import "PostSettingsSelectionViewController.h"
#import "PublishDatePickerView.h"
#import "UITableViewTextFieldCell.h"
#import "WordPressAppDelegate.h"
#import "WPAlertView.h"
#import "MediaBrowserViewController.h"
#import "WPTableViewController.h"
#import "WPTableViewActivityCell.h"
#import "WPTableViewSectionHeaderView.h"
#import "WPTableImageSource.h"

typedef enum {
    PostSettingsRowCategories = 1,
    PostSettingsRowTags,
    PostSettingsRowPublishDate,
    PostSettingsRowStatus,
    PostSettingsRowVisibility,
    PostSettingsRowPassword,
    PostSettingsRowFormat,
    PostSettingsRowFeaturedImage,
    PostSettingsRowFeaturedImageAdd,
    PostSettingsRowGeolocationAdd,
    PostSettingsRowGeolocationMap
} PostSettingsRow;

static CGFloat CellHeight = 44.0f;
static NSInteger RowIndexForDatePicker = 0;

static NSString *const TableViewActivityCellIdentifier = @"TableViewActivityCellIdentifier";

@interface PostSettingsViewController () <UITextFieldDelegate, WPTableImageSourceDelegate, WPPickerViewDelegate>

@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *tagsTextField;
@property (nonatomic, strong) NSArray *statusList;
@property (nonatomic, strong) NSArray *visibilityList;
@property (nonatomic, strong) NSArray *formatsList;
@property (nonatomic, strong) WPTableImageSource *imageSource;
@property (nonatomic, strong) UIImage *featuredImage;
@property (nonatomic, strong) PublishDatePickerView *datePicker;

@end

@implementation PostSettingsViewController

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removePostPropertiesObserver];
}

- (id)initWithPost:(AbstractPost *)aPost {
    self = [super init];
    if (self) {
        self.apost = aPost;
    }
    return self;
}

- (NSString *)statsPrefix {
    if (_statsPrefix == nil) {
        return @"Post Detail";
    } else {
        return _statsPrefix;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Options", nil);

    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    NSMutableArray *allStatuses = [NSMutableArray arrayWithArray:[self.apost availableStatuses]];
    [allStatuses removeObject:NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    self.statusList = [NSArray arrayWithArray:allStatuses];
    self.visibilityList = @[NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP."),
                           NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP."),
                           NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    self.formatsList = self.post.blog.sortedPostFormatNames;

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTagsKeyboardIfAppropriate:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;

    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self.tableView registerNib:[UINib nibWithNibName:@"WPTableViewActivityCell" bundle:nil] forCellReuseIdentifier:TableViewActivityCellIdentifier];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.apost.managedObjectContext performBlock:^{
        [self.apost.managedObjectContext save:nil];
    }];
    
    [self hideDatePicker];
}

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
}

#pragma mark - KVO

- (void)addPostPropertiesObserver {
    [self.post addObserver:self
             forKeyPath:@"post_thumbnail"
                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                context:nil];
    
    [self.post addObserver:self
             forKeyPath:@"geolocation"
                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                context:nil];
}

- (void)removePostPropertiesObserver {

    [self.post removeObserver:self forKeyPath:@"post_thumbnail"];
    [self.post removeObserver:self forKeyPath:@"geolocation"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"post_thumbnail" isEqualToString:keyPath]) {
        self.featuredImage = nil;
    }
    [self.tableView reloadData];
}

#pragma mark - Instance Methods

- (void)setApost:(AbstractPost *)apost {
    if ([apost isEqual:_apost]) {
        return;
    }
    if (_apost) {
        [self removePostPropertiesObserver];
    }
    _apost = apost;
    [self addPostPropertiesObserver];
}

- (Post *)post {
    if ([self.apost isKindOfClass:[Post class]]) {
        return (Post *)self.apost;
    } else {
        return nil;
    }
}

- (void)endEditingAction:(id)sender {
	if (self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
	}
}

- (void)endEditingForTextFieldAction:(id)sender {
    [self.passwordTextField endEditing:YES];
}

- (void)reloadData {
    self.passwordTextField.text = self.apost.password;

    [self.tableView reloadData];
}

- (void)datePickerChanged:(NSDate *)date {
    self.apost.dateCreated = date;

    if ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending && [self.apost.status isEqualToString:@"draft"]) {
        self.apost.status = @"publish";
    }
    
    [self hideDatePicker];
}

#pragma mark - TextField Delegate Methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.passwordTextField) {
        self.apost.password = textField.text;
    } else if (textField == self.tagsTextField) {
        self.post.tags = self.tagsTextField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.tagsTextField) {
        self.post.tags = [self.tagsTextField.text stringByReplacingCharactersInRange:range withString:string];
    }
    return YES;
}

#pragma mark - UITableView Delegate

- (void)configureSections {
    self.sections = [NSMutableArray array];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionTaxonomy]];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
    [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionFormat]];
    if ([self.post.blog supportsFeaturedImages]) {
        [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionFeaturedImage]];
    }
    if (self.post.blog.geolocationEnabled || self.post.geolocation) {
        [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionGeolocation]];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.sections) {
        [self configureSections];
    }
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
        
    } else if (sec == PostSettingsSectionGeolocation) {
        return 1;
    }
    
    return 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
    if (sec == PostSettingsSectionTaxonomy) {
        // No title
        
    } else if (sec == PostSettingsSectionMeta) {
        return NSLocalizedString(@"Publish", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
        
    } else if (sec == PostSettingsSectionFormat) {
        return NSLocalizedString(@"Post Format", @"For setting the format of a post.");
        
    } else if (sec == PostSettingsSectionFeaturedImage) {
        return NSLocalizedString(@"Featured Image", @"Label for the Featured Image area in post settings.");
        
    } else if (sec == PostSettingsSectionGeolocation) {
        return NSLocalizedString(@"Geolocation", @"Label for the geolocation feature (tagging posts by their physical location).");
        
    }
    return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f)];
    header.title = [self titleForHeaderInSection:section];
    header.backgroundColor = self.tableView.backgroundColor;
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (IS_IPAD && section == 0) {
        return WPTableViewTopMargin;
    }
    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = IS_IPAD ? WPTableViewFixedWidth : CGRectGetWidth(self.tableView.frame);
    if (indexPath.section == PostSettingsSectionGeolocation && [self post].geolocation) {
        return ceilf(width * 0.75f);
    }
    
    if (indexPath.section == PostSettingsSectionFeaturedImage) {
        if (self.featuredImage) {
            CGFloat cellMargins = (2 * PostFeaturedImageCellMargin);
            CGFloat imageWidth = self.featuredImage.size.width;
            CGFloat imageHeight = self.featuredImage.size.height;
            width = width - cellMargins;
            CGFloat height = ceilf((width / imageWidth) * imageHeight);
            return height + cellMargins;
        }
    }
    
    if (indexPath.section == PostSettingsSectionMeta) {
        if (indexPath.row == RowIndexForDatePicker && self.datePicker) {
            return CGRectGetHeight(self.datePicker.frame);
        }
    }
    
    return CellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
        
    } else if (sec == PostSettingsSectionGeolocation) {
        cell = [self configureGeolocationCellForIndexPath:indexPath];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell.tag == PostSettingsRowCategories) {
        [self showCategoriesSelection];
        
    } else if (cell.tag == PostSettingsRowTags) {
        // noop
        
    } else if (cell.tag == PostSettingsRowPublishDate && !self.datePicker) {
        [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedScheduleFor forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
        [self configureAndShowDatePicker];
        
    } else if (cell.tag ==  PostSettingsRowStatus) {
        [self showPostStatusSelector];
        
    } else if (cell.tag == PostSettingsRowVisibility) {
        [self showPostVisibilitySelector];
        
    } else if (cell.tag == PostSettingsRowPassword) {
        // noop
        
    } else if (cell.tag == PostSettingsRowFormat) {
        [self showPostFormatSelector];
        
    } else if (cell.tag == PostSettingsRowFeaturedImage) {
        [self showFeaturedImageSelector];
        
    } else if (cell.tag == PostSettingsRowFeaturedImageAdd) {
        [WPMobileStats trackEventForWPCom:[self formattedStatEventString:StatsPropertyPostDetailSettingsClickedSetFeaturedImage]];
        [self showFeaturedImageSelector];
        
    } else if (cell.tag == PostSettingsRowGeolocationAdd || cell.tag == PostSettingsRowGeolocationMap) {
        [self showPostGeolocationSelector];
    }
}

- (UITableViewCell *)configureTaxonomyCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        // Categories
        cell = [self getWPTableViewCell];
        cell.textLabel.text = NSLocalizedString(@"Categories", @"Label for the categories field. Should be the same as WP core.");
        cell.detailTextLabel.text = [NSString decodeXMLCharactersIn:[self.post categoriesText]];
        cell.tag = PostSettingsRowCategories;
        
    } else {
        // Tags
        UITableViewTextFieldCell *textCell = [self getTextFieldCell];
        textCell.textLabel.text = NSLocalizedString(@"Tags", @"Label for the tags field. Should be the same as WP core.");
        textCell.textField.text = self.post.tags;
        textCell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Comma separated", @"Placeholder text for the tags field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        textCell.textField.secureTextEntry = NO;
        textCell.textField.clearButtonMode = UITextFieldViewModeNever;
        cell = textCell;
        cell.tag = PostSettingsRowTags;

        self.tagsTextField = textCell.textField;
    }
    
    return cell;
}

- (UITableViewCell *)configureMetaPostMetaCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row == 0 && !self.datePicker) {
        // Publish date
        cell = [self getWPTableViewCell];
        if (self.apost.dateCreated) {
            if ([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending) {
                cell.textLabel.text = NSLocalizedString(@"Scheduled for", @"Scheduled for [date]");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Published on", @"Published on [date]");
            }
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            cell.detailTextLabel.text = [dateFormatter stringFromDate:self.apost.dateCreated];
        } else {
            cell.textLabel.text = NSLocalizedString(@"Publish", @"");
            cell.detailTextLabel.text = NSLocalizedString(@"Immediately", @"");
        }
        cell.tag = PostSettingsRowPublishDate;

    } else if (indexPath.row == 0 && self.datePicker) {
        // Date picker
        cell = [self getWPTableViewDatePickerCell];
        [cell.contentView addSubview:self.datePicker];
        
    } else if(indexPath.row == 1) {
        // Publish Status
        cell = [self getWPTableViewCell];
        cell.textLabel.text = NSLocalizedString(@"Status", @"The status of the post. Should be the same as in core WP.");
        
        if (([self.apost.dateCreated compare:[NSDate date]] == NSOrderedDescending)
            && ([self.apost.status isEqualToString:@"publish"])) {
            cell.detailTextLabel.text = NSLocalizedString(@"Scheduled", @"If a post is scheduled for later, this string is used for the post's status. Should use the same translation as core WP.");
        } else {
            cell.detailTextLabel.text = self.apost.statusTitle;
        }
        if ([self.apost.status isEqualToString:@"private"]) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
        cell.tag = PostSettingsRowStatus;
        
    } else if (indexPath.row == 2) {
        // Visibility
        cell = [self getWPTableViewCell];
        cell.textLabel.text = NSLocalizedString(@"Visibility", @"The visibility settings of the post. Should be the same as in core WP.");
        cell.detailTextLabel.text = [self titleForVisibility];
        cell.tag = PostSettingsRowVisibility;
        
    } else {
        // Password
        UITableViewTextFieldCell *textCell = [self getTextFieldCell];
        textCell.textLabel.text = NSLocalizedString(@"Password", @"Label for the tags field. Should be the same as WP core.");
        textCell.textField.text = self.apost.password;
        textCell.textField.attributedPlaceholder = nil;
        textCell.textField.placeholder = NSLocalizedString(@"Enter a password", @"");
        textCell.textField.clearButtonMode = UITextFieldViewModeWhileEditing;

        cell = textCell;
        cell.tag = PostSettingsRowPassword;
        
        self.passwordTextField = textCell.textField;
    }
    
    return cell;
}

- (UITableViewCell *)configurePostFormatCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self getWPTableViewCell];
    
    cell.textLabel.text = NSLocalizedString(@"Post Format", @"The post formats available for the post. Should be the same as in core WP.");
    cell.detailTextLabel.text = self.post.postFormatText;
    cell.tag = PostSettingsRowFormat;
    
    return cell;
}

- (UITableViewCell *)configureFeaturedImageCellForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (!self.post.post_thumbnail) {
        WPTableViewActivityCell *activityCell = [self getWPActivityTableViewCell];
        activityCell.textLabel.text = NSLocalizedString(@"Set Featured Image", @"");
        activityCell.tag = PostSettingsRowFeaturedImageAdd;
        
        cell = activityCell;
        
    } else {
        static NSString *FeaturedImageCellIdentifier = @"FeaturedImageCellIdentifier";
        PostFeaturedImageCell *featuredImageCell = [self.tableView dequeueReusableCellWithIdentifier:FeaturedImageCellIdentifier];
        if (!cell) {
            featuredImageCell = [[PostFeaturedImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FeaturedImageCellIdentifier];
        }
        
        if (self.featuredImage) {
            [featuredImageCell setImage:self.featuredImage];
        } else {
            [self loadFeaturedImage:indexPath];
            [featuredImageCell showLoadingSpinner:YES];
        }

        cell = featuredImageCell;
        cell.tag = PostSettingsRowFeaturedImage;
    }
    
    return cell;
}

- (UITableViewCell *)configureGeolocationCellForIndexPath:(NSIndexPath *)indexPath {
    WPTableViewCell *cell;
    if (self.post.geolocation == nil) {
        WPTableViewActivityCell *actCell = [self getWPActivityTableViewCell];

        actCell.tag = PostSettingsRowGeolocationAdd;
        
        if ([[LocationService sharedService] locationServiceRunning]) {
            [actCell.spinner startAnimating];
            actCell.textLabel.text = NSLocalizedString(@"Finding your location...", @"Geo-tagging posts, status message when geolocation is found.");
        } else {
            actCell.textLabel.text = NSLocalizedString(@"Set Location", @"Geolocation feature to set the location.");
            [actCell.spinner stopAnimating];
        }
        
        cell = actCell;

    } else {
        static NSString *wpPostSettingsGeoCellIdentifier = @"wpPostSettingsGeoCellIdentifier";
        PostGeolocationCell *geoCell = [self.tableView dequeueReusableCellWithIdentifier:wpPostSettingsGeoCellIdentifier];
        if (!geoCell) {
            geoCell = [[PostGeolocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:wpPostSettingsGeoCellIdentifier];
        }
        
        Coordinate *coordinate = self.post.geolocation;
        CLLocation *lastLocation = [LocationService sharedService].lastGeocodedLocation;
        CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        NSString *address;
        if(lastLocation && [lastLocation distanceFromLocation:postLocation] == 0) {
            address = [LocationService sharedService].lastGeocodedAddress;
        } else {
            address = NSLocalizedString(@"Looking up address...", @"Used with posts that are geo-tagged. Let's the user know the the app is looking up the address for the coordinates tagging the post.");
            [[LocationService sharedService] getAddressForLocation:postLocation
                                                        completion:^(CLLocation *location, NSString *address, NSError *error) {
                                                            [self.tableView reloadData];
                                                        }];

        }
        [geoCell setCoordinate:self.post.geolocation andAddress:address];
        cell = geoCell;
        cell.tag = PostSettingsRowGeolocationMap;

    }
    return cell;
}

- (WPTableViewCell *)getWPTableViewCell {
    static NSString *wpTableViewCellIdentifier = @"wpTableViewCellIdentifier";
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:wpTableViewCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:wpTableViewCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [WPStyleGuide configureTableViewCell:cell];
    }
    cell.tag = 0;
    return cell;
}

- (WPTableViewCell *)getWPTableViewDatePickerCell {
    static NSString *wpTableViewCellIdentifier = @"wpTableViewDatePickerCellIdentifier";
    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:wpTableViewCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:wpTableViewCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewCell:cell];
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.tag = 0;
    return cell;
}

- (WPTableViewActivityCell *)getWPActivityTableViewCell {
    WPTableViewActivityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TableViewActivityCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [WPStyleGuide configureTableViewActionCell:cell];

    cell.tag = 0;
    return cell;
}

- (UITableViewTextFieldCell *)getTextFieldCell {
    static NSString *textFieldCellIdentifier = @"textFieldCellIdentifier";
    UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:textFieldCellIdentifier];
    if (!cell) {
        cell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textFieldCellIdentifier];
        cell.textField.returnKeyType = UIReturnKeyDone;
        cell.textField.delegate = self;
        [WPStyleGuide configureTableViewTextCell:cell];
        cell.textField.textAlignment = NSTextAlignmentRight;
    }
    cell.tag = 0;
    return cell;
}

- (void)hideDatePicker {
    if (!self.datePicker) {
        return;
    }
    self.datePicker = nil;

    // Reload the whole section since other rows might be affected by any change.
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:[self.sections indexOfObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]]];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
}

- (void)configureAndShowDatePicker {
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
        self.datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    self.datePicker.frame = frame;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:RowIndexForDatePicker inSection:PostSettingsSectionMeta];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)showPostStatusSelector {
    if ([self.apost.status isEqualToString:@"private"]) {
        return;
    }
    
    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedStatus forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    
    NSMutableArray *titles = [NSMutableArray arrayWithArray:[self.apost availableStatuses]];
    [titles removeObject:NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.")];
    
    NSDictionary *statusDict = @{
                                 @"DefaultValue": NSLocalizedString(@"Published", @""),
                                 @"Title" : NSLocalizedString(@"Status", nil),
                                 @"Titles" : titles,
                                 @"Values" : titles,
                                 @"CurrentValue" : self.apost.statusTitle
                                 };
    PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:statusDict];
    __weak PostSettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *status) {
        [self.apost setStatusTitle:status];
        [weakVc dismiss];
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPostVisibilitySelector {
    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedVisibility forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    
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
    PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:visiblityDict];
    __weak PostSettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *visibility) {
        [weakVc dismiss];
        
        if ([visibility isEqualToString:NSLocalizedString(@"Private", @"Post privacy status in the Post Editor/Settings area (compare with WP core translations).")]) {
            self.apost.status = @"private";
            self.apost.password = nil;
        } else {
            if ([self.apost.status isEqualToString:@"private"]) {
                if ([self.apost.original.status isEqualToString:@"private"]) {
                    self.apost.status = @"publish";
                } else {
                    // restore the original status
                    self.apost.status = self.apost.original.status;
                }
            }
            if ([visibility isEqualToString:NSLocalizedString(@"Password protected", @"Post password protection in the Post Editor/Settings area (compare with WP core translations).")]) {
                NSString *password = @"";
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

- (void)showPostFormatSelector {
    if( [self.formatsList count] == 0 ) {
        return;
    }
    
    [WPMobileStats flagProperty:StatsPropertyPostDetailSettingsClickedPostFormat forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    
    NSArray *titles = self.post.blog.sortedPostFormatNames;
    NSDictionary *postFormatsDict = @{
                                      @"DefaultValue": titles[0],
                                      @"Title" : NSLocalizedString(@"Post Format", nil),
                                      @"Titles" : titles,
                                      @"Values" : titles,
                                      @"CurrentValue" : self.post.postFormatText
                                      };
    
    PostSettingsSelectionViewController *vc = [[PostSettingsSelectionViewController alloc] initWithDictionary:postFormatsDict];
    __weak PostSettingsSelectionViewController *weakVc = vc;
    vc.onItemSelected = ^(NSString *status) {
        self.post.postFormatText = status;
        [weakVc dismiss];
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPostGeolocationSelector {
    PostGeolocationViewController *controller = [[PostGeolocationViewController alloc] initWithPost:self.post];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showFeaturedImageSelector {
    UIViewController *controller;
    if (self.post.post_thumbnail) {
        controller = [[FeaturedImageViewController alloc] initWithPost:self.post];
    } else {
        controller = [[MediaBrowserViewController alloc] initWithPost:self.post selectingFeaturedImage:YES];
    }
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showCategoriesSelection {
    [WPMobileStats flagProperty:StatsPropertyPostDetailClickedShowCategories forEvent:[self formattedStatEventString:StatsEventPostDetailClosedEditor]];
    CategoriesViewController *controller = [[CategoriesViewController alloc] initWithPost:[self post] selectionMode:CategoriesSelectionModePost];
    [self.navigationController pushViewController:controller animated:YES];
}

- (NSString *)formattedStatEventString:(NSString *)event {
    return [NSString stringWithFormat:@"%@ - %@", self.statsPrefix, event];
}

- (void)loadFeaturedImage:(NSIndexPath *)indexPath {
    NSURL *url = [NSURL URLWithString:self.post.featuredImage.remoteURL];
    if (url) {
        CGFloat width = CGRectGetWidth(self.view.frame);
        if (IS_IPAD) {
            width = WPTableViewFixedWidth;
        }
        width = width - (PostFeaturedImageCellMargin * 2); // left and right cell margins
        CGFloat height = ceilf(width * 0.66);
        CGSize imageSize = CGSizeMake(width, height);

        [self.imageSource fetchImageForURL:url
                                  withSize:imageSize
                                 indexPath:indexPath
                                 isPrivate:self.post.blog.isPrivate];
        
    }
}

- (WPTableImageSource *)imageSource {
    if (!_imageSource) {
        CGFloat max = MAX(self.view.frame.size.width, self.view.frame.size.height);
        CGSize maxSize = CGSizeMake(max, max);
        _imageSource = [[WPTableImageSource alloc] initWithMaxSize:maxSize];
        _imageSource.resizesImagesSynchronously = YES;
        _imageSource.delegate = self;
    }
    return _imageSource;
}

#pragma mark - WPTableImageSourceDelegate

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath {
    self.featuredImage = image;
    [self.tableView reloadData];
}

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageFailedforIndexPath:(NSIndexPath *)indexPath error:(NSError *)error {
    DDLogError(@"Error loading featured image: %@", error);
    PostFeaturedImageCell *cell = (PostFeaturedImageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell showLoadingSpinner:NO];
    cell.textLabel.text = NSLocalizedString(@"Featured Image did not load", @"");
}

- (NSString *)titleForVisibility {
    if (self.apost.password) {
        return NSLocalizedString(@"Password protected", @"Privacy setting for posts set to 'Password protected'. Should be the same as in core WP.");
    } else if ([self.apost.status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Private", @"Privacy setting for posts set to 'Private'. Should be the same as in core WP.");
    } else {
        return NSLocalizedString(@"Public", @"Privacy setting for posts set to 'Public' (default). Should be the same as in core WP.");
    }
}

- (void)dismissTagsKeyboardIfAppropriate:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView:self.tableView];
    if (!CGRectContainsPoint(self.tagsTextField.frame, touchPoint) && [self.tagsTextField isFirstResponder]) {
        [self.tagsTextField resignFirstResponder];
    }
}

#pragma mark - WPPickerView Delegate

- (void)pickerView:(WPPickerView *)pickerView didFinishWithValue:(id)value {
    if (value == nil) {
        // Publish Immediately
        self.apost.dateCreated = nil;
        [self hideDatePicker];
        return;
    }
    
    // Compare via timeIntervalSinceDate to let us ignore subsecond variation.
    NSDate *startingDate = (NSDate *)self.datePicker.startingValue;
    NSDate *selectedDate = (NSDate *)value;
    NSTimeInterval interval = [startingDate timeIntervalSinceDate:selectedDate];
    if (abs(interval) < 1.0) {
        // Nothing changed.
        [self hideDatePicker];
        return;
    }
    
    [self datePickerChanged:selectedDate];
}

@end
