/*

 Settings contents:

 - Image Resize
 - Visual Editor
 - Shake to Feedback (Internal Beta only)

 */

#import "SettingsViewController.h"
#import "WordPressComApi.h"
#import "SupportViewController.h"
#import "WPAccount.h"
#import "WPPostViewController.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "Constants.h"
#import "Mediaservice.h"
#import "WPLookbackPresenter.h"
#import "WordPress-Swift.h"
#import <WordPressShared/WPTableViewCell.h>

#ifdef LOOKBACK_ENABLED
#import <Lookback/Lookback.h>
#endif

typedef enum {
    SettingsSectionMedia = 0,
    SettingsSectionEditor,
    SettingsSectionInternalBeta,
    SettingsSectionCount
} SettingsSection;

static NSString * const WPSettingsRestorationID = @"WPSettingsRestorationID";
static NSString * const SwitchTableViewCellIdentifier = @"SwitchTableViewCell";
static NSString * const MediaSizeSliderCellIdentifier = @"MediaSizeSliderCell";

static CGFloat const SettingsRowHeight = 44.0;

static NSInteger const MediaSizeSliderStep = 50;

@interface SettingsViewController () <UIViewControllerRestoration>

@property (nonatomic, assign) BOOL showInternalBetaSection;

@end

@implementation SettingsViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.restorationIdentifier = WPSettingsRestorationID;
        self.restorationClass = [self class];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"App Settings");

#ifdef LOOKBACK_ENABLED
    self.showInternalBetaSection = YES;
#else
    self.showInternalBetaSection = NO;
#endif

    [self.tableView registerNib:[UINib nibWithNibName:@"MediaSizeSliderCell" bundle:nil] forCellReuseIdentifier:MediaSizeSliderCellIdentifier];
    [self.tableView registerClass:[SwitchTableViewCell class] forCellReuseIdentifier:SwitchTableViewCellIdentifier];

    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.tableView reloadData];
}


#pragma mark - Cell Actions

- (void)handleImageSizeChanged:(NSInteger)value
{
    [MediaService setMaxImageSizeSetting:CGSizeMake(value, value)];
}

- (void)handleEditorChanged:(BOOL)value
{
    if (value) {
        [WPAnalytics track:WPAnalyticsStatEditorToggledOn];
    } else {
        [WPAnalytics track:WPAnalyticsStatEditorToggledOff];
    }
    [WPPostViewController setNewEditorEnabled:value];
}

- (void)handleShakeToPullUpFeedbackChanged:(BOOL)value
{
#ifdef LOOKBACK_ENABLED
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:WPLookbackPresenterShakeToPullUpFeedbackKey];
    [Lookback lookback].shakeToRecord = value;
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
    }

    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = [self titleForHeaderInSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SettingsSectionEditor && ![WPPostViewController isNewEditorAvailable]) {
        return 1;
    }

    NSString *title = [self titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
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
        return [MediaSizeSliderCell height];
    }
    return SettingsRowHeight;
}

- (UITableViewCell *)cellForMediaSizeInTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    MediaSizeSliderCell *cell = [tableView dequeueReusableCellWithIdentifier:MediaSizeSliderCellIdentifier forIndexPath:indexPath];
    cell.title = NSLocalizedString(@"Max Image Upload Size", @"Title for the image size settings option.");
    cell.minValue = MediaMinImageSizeDimension;
    cell.maxValue = MediaMaxImageSizeDimension;
    cell.step = MediaSizeSliderStep;
    cell.value = [MediaService maxImageSizeSetting].width;

    __weak SettingsViewController *weakSelf = self;
    cell.onChange = ^(NSInteger value) {
        [weakSelf handleImageSizeChanged:value];
    };

    return cell;
}

- (UITableViewCell *)cellForVisualEditorInTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    SwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SwitchTableViewCellIdentifier forIndexPath:indexPath];
    cell.name = NSLocalizedString(@"Visual Editor", @"Option to enable the visual editor");
    cell.on = [WPPostViewController isNewEditorEnabled];

    __weak SettingsViewController *weakSelf = self;
    cell.onChange = ^(BOOL value) {
        [weakSelf handleEditorChanged:value];
    };

    return cell;
}

- (UITableViewCell *)cellForFeedbackInTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
#ifndef LOOKBACK_ENABLED
        NSAssert(NO, @"Should never execute this when Lookback is disabled.");
#endif
    SwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SwitchTableViewCellIdentifier forIndexPath:indexPath];
    cell.name = NSLocalizedString(@"Shake for Feedback", @"Option to allow the user to shake the device to pull up the feedback mechanism");
    cell.on = [[NSUserDefaults standardUserDefaults] boolForKey:WPLookbackPresenterShakeToPullUpFeedbackKey];

    __weak SettingsViewController *weakSelf = self;
    cell.onChange = ^(BOOL value) {
        [weakSelf handleShakeToPullUpFeedbackChanged:value];
    };
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case SettingsSectionMedia:
            cell = [self cellForMediaSizeInTableView:tableView indexPath:indexPath];
            break;
        case SettingsSectionEditor:
            cell = [self cellForVisualEditorInTableView:tableView indexPath:indexPath];
            break;
        case SettingsSectionInternalBeta:
            cell = [self cellForFeedbackInTableView:tableView indexPath:indexPath];
            break;
    }
    NSAssert(cell != nil, @"We should have a cell by now");

    [WPStyleGuide configureTableViewCell:cell];

    return cell;
}

@end
