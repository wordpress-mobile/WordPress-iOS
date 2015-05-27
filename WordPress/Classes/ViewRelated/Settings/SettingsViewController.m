/*

 Settings contents:

 - Blogs list
    - Add blog
    - Edit/Delete
 - Media Settings
    - Image Resize
    - Video API
    - Video Quality
    - Video Content

 */

#import "SettingsViewController.h"
#import "WordPressComApi.h"
#import "SettingsPageViewController.h"
#import "NotificationSettingsViewController.h"
#import "SupportViewController.h"
#import "WPAccount.h"
#import "WPPostViewController.h"
#import "WPTableViewSectionHeaderView.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "NotificationsManager.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WPImageOptimizer.h"
#import "Constants.h"
#import "Mediaservice.h"
#import "WPLookbackPresenter.h"
#import <WordPress-iOS-Shared/WPTableViewCell.h>

#ifdef LOOKBACK_ENABLED
#import <Lookback/Lookback.h>
#endif

typedef enum {
    SettingsSectionMedia = 0,
    SettingsSectionEditor,
    SettingsSectionInternalBeta,
    SettingsSectionCount
} SettingsSection;

static CGFloat const HorizontalMargin = 16.0;
static CGFloat const MediaSizeControlHeight = 44.0;
static CGFloat const MediaSizeControlOffset = 12.0;
static CGFloat const SettingsRowHeight = 44.0;

@interface SettingsViewController ()

@property (nonatomic, assign) BOOL showInternalBetaSection;
@property (nonatomic, strong) UISlider *mediaSizeSlider;
@property (nonatomic, strong) UILabel *mediaCellTitleLabel;
@property (nonatomic, strong) UILabel *mediaCellSizeLabel;

@end

@implementation SettingsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", @"App Settings");
    
#ifdef LOOKBACK_ENABLED
    self.showInternalBetaSection = YES;
#else
    self.showInternalBetaSection = NO;
#endif

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
}


#pragma mark - Custom Getter

- (NSString *)textForMediaCellSize
{
    CGSize savedSize = [MediaService maxImageSizeSetting];
    if (CGSizeEqualToSize(savedSize, MediaMaxImageSize)) {
        return NSLocalizedString(@"Original", @"Label title. Indicates an image will use its original size when uploaded.");
    }

    return [NSString stringWithFormat:@"%.0fpx X %.0fpx", savedSize.width, savedSize.height];
}

- (UILabel *)mediaCellTitleLabel
{
    if (_mediaCellTitleLabel) {
        return _mediaCellTitleLabel;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds) - (HorizontalMargin * 2);
    CGRect frame = CGRectMake(HorizontalMargin, 0.0, width, MediaSizeControlHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [WPStyleGuide tableviewTextFont];
    label.textColor = [WPStyleGuide whisperGrey];
    label.text = NSLocalizedString(@"Max Image Upload Size", @"Title for the image size settings option.");
    self.mediaCellTitleLabel = label;

    return _mediaCellTitleLabel;
}

- (UISlider *)mediaSizeSlider
{
    if (_mediaSizeSlider) {
        return _mediaSizeSlider;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds) - (HorizontalMargin * 2);
    CGFloat y = CGRectGetHeight(self.mediaCellTitleLabel.frame) - MediaSizeControlOffset;
    CGRect frame = CGRectMake(HorizontalMargin, y, width, MediaSizeControlHeight);
    UISlider *slider = [[UISlider alloc] initWithFrame:frame];
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    slider.continuous = YES;
    slider.minimumTrackTintColor = [WPStyleGuide whisperGrey];
    slider.maximumTrackTintColor = [WPStyleGuide whisperGrey];
    slider.minimumValue = MediaMinImageSizeDimension;
    slider.maximumValue = MediaMaxImageSizeDimension;
    slider.value = [MediaService maxImageSizeSetting].width;
    [slider addTarget:self action:@selector(handleImageSizeChanged:) forControlEvents:UIControlEventValueChanged];
    self.mediaSizeSlider = slider;

    return _mediaSizeSlider;
}

- (UILabel *)mediaCellSizeLabel
{
    if (_mediaCellSizeLabel) {
        return _mediaCellSizeLabel;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds) - (HorizontalMargin * 2);
    CGFloat y = CGRectGetMaxY(self.mediaSizeSlider.frame) - MediaSizeControlOffset;
    CGRect frame = CGRectMake(HorizontalMargin, y, width, MediaSizeControlHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [WPStyleGuide tableviewSubtitleFont];
    label.textColor = [WPStyleGuide whisperGrey];
    label.text = [self textForMediaCellSize];
    label.textAlignment = NSTextAlignmentCenter;
    self.mediaCellSizeLabel = label;

    return _mediaCellSizeLabel;
}

- (void)handleImageSizeChanged:(id)sender
{
    NSInteger value = self.mediaSizeSlider.value;
    value = value - (value % 50); // steps of 50

    [MediaService setMaxImageSizeSetting:CGSizeMake(value, value)];

    [self.mediaSizeSlider setValue:value animated:NO];
    self.mediaCellSizeLabel.text = [self textForMediaCellSize];
}

- (void)handleEditorChanged:(id)sender
{
    UISwitch *aSwitch = (UISwitch *)sender;
    if (aSwitch.on) {
        [WPAnalytics track:WPAnalyticsStatEditorToggledOn];
    } else {
        [WPAnalytics track:WPAnalyticsStatEditorToggledOff];
    }
    [WPPostViewController setNewEditorEnabled:aSwitch.on];
}

- (void)handleShakeToPullUpFeedbackChanged:(id)sender
{
#ifdef LOOKBACK_ENABLED
    UISwitch *aSwitch = (UISwitch *)sender;
    BOOL shakeForFeedback = aSwitch.on;
    [[NSUserDefaults standardUserDefaults] setBool:shakeForFeedback forKey:WPLookbackPresenterShakeToPullUpFeedbackKey];
    [Lookback lookback].shakeToRecord = shakeForFeedback;
#endif
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableView isEditing] ? 1 : SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SettingsSectionMedia:
            return 1;
        
		case SettingsSectionEditor: {
			if (![WPPostViewController isNewEditorAvailable]) {
				return 0;
			} else {
				return 1;
			}
		}

        case SettingsSectionInternalBeta:
            if (self.showInternalBetaSection) {
                return 1;
            }
            else {
                return 0;
            }
        default:
            return 0;

    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return nil;
	} else {
		WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
		header.title = [self titleForHeaderInSection:section];
		return header;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return 1;
	} else {
		NSString *title = [self titleForHeaderInSection:section];
		return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	static const CGFloat kDefaultFooterHeight = 16.0f;
	
	if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
		return 1;
	} else {
		return kDefaultFooterHeight;
	}
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (section == SettingsSectionMedia) {
        return NSLocalizedString(@"Media", @"Title label for the media settings section in the app settings");

    } else if (section == SettingsSectionEditor) {
        return NSLocalizedString(@"Editor", @"Title label for the editor settings section in the app settings");
		
    } else if (section == SettingsSectionInternalBeta) {
        if (self.showInternalBetaSection) {
            return NSLocalizedString(@"Internal Beta", @"");
        } else {
            return @"";
        }
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==  SettingsSectionMedia) {
        return CGRectGetMaxY(self.mediaCellSizeLabel.frame);
    }
    return SettingsRowHeight;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (indexPath.section == SettingsSectionMedia) {
        cell.textLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    } else if (indexPath.section == SettingsSectionEditor){
        cell.textLabel.text = NSLocalizedString(@"Visual Editor", @"Option to enable the visual editor");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
        aSwitch.on = [WPPostViewController isNewEditorEnabled];
        
    } else if (indexPath.section == SettingsSectionInternalBeta) {
#ifndef LOOKBACK_ENABLED
        NSAssert(NO, @"Should never execute this when Lookback is disabled.");
#else
        cell.textLabel.text = NSLocalizedString(@"Shake for Feedback", @"Option to allow the user to shake the device to pull up the feedback mechanism");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *aSwitch = (UISwitch *)cell.accessoryView;
        aSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:WPLookbackPresenterShakeToPullUpFeedbackKey];
#endif
    }
}

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;

    if (indexPath.section == SettingsSectionMedia) {
            cellIdentifier = @"Media";
            cellStyle = UITableViewCellStyleDefault;
    } else if (indexPath.section == SettingsSectionEditor) {
            cellIdentifier = @"Editor";
            cellStyle = UITableViewCellStyleDefault;
    }

    WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[WPTableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
    }

    if (indexPath.section == SettingsSectionMedia) {
        CGFloat width = CGRectGetWidth(cell.bounds) - 32.0;
        CGRect frame = self.mediaCellTitleLabel.frame;
        frame.size.width = width;
        self.mediaCellTitleLabel.frame = frame;
        [cell.contentView addSubview:self.mediaCellTitleLabel];

        frame = self.mediaSizeSlider.frame;
        frame.size.width = width;
        self.mediaSizeSlider.frame = frame;
        [cell.contentView addSubview:self.mediaSizeSlider];

        frame = self.mediaCellSizeLabel.frame;
        frame.size.width = width;
        self.mediaCellSizeLabel.frame = frame;
        [cell.contentView addSubview:self.mediaCellSizeLabel];

        // make sure labels do not clip the slider shadow. 
        [cell.contentView bringSubviewToFront:self.mediaSizeSlider];
    }

    if (indexPath.section == SettingsSectionEditor) {
        UISwitch *optimizeImagesSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [optimizeImagesSwitch addTarget:self action:@selector(handleEditorChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = optimizeImagesSwitch;
    }
    
    if (indexPath.section == SettingsSectionInternalBeta) {
        UISwitch *toggleShakeToPullUpFeedbackSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [toggleShakeToPullUpFeedbackSwitch addTarget:self action:@selector(handleShakeToPullUpFeedbackChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggleShakeToPullUpFeedbackSwitch;
    }

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

@end
