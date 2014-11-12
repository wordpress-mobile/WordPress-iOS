#import "MeViewController.h"
#import "SettingsViewController.h"
#import "SupportViewController.h"

static NSString *const MVCCellReuseIdentifier = @"MVCCellReuseIdentifier";
static NSInteger const MVCNumberOfSections = 1;

static CGFloat const MVCTableViewRowHeight = 50.0;

static NSInteger const MVCAccountSettingsIndex = 0;
static NSInteger const MVCBillingIndex = 1;
static NSInteger const MVCHelpIndex = 2;

static NSString *const MVCAccountSettingsTitle = @"Account Settings";
static NSString *const MVCBillingTitle = @"Billing";
static NSString *const MVCHelpTitle = @"Help & Support";

@interface MeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong, readonly) NSArray *rowTitles;

@end

@implementation MeViewController

- (void)loadView
{
    [super loadView];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = MVCTableViewRowHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MVCCellReuseIdentifier];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MVCNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rowTitles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MVCCellReuseIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [WPStyleGuide configureTableViewActionCell:cell];
    cell.textLabel.text = self.rowTitles[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case MVCAccountSettingsIndex:
            [self navigateToSettings];
            break;
        case MVCBillingIndex:
            [self navigateToBilling];
            break;
        case MVCHelpIndex:
            [self navigateToHelp];
        default:
            break;
    }
}

#pragma mark - Actions

- (void)navigateToSettings
{
    [WPAnalytics track:WPAnalyticsStatOpenedSettings];

    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)navigateToBilling
{

}

- (void)navigateToHelp
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
}

#pragma mark - Accessors

- (NSArray *)rowTitles
{
    return @[MVCAccountSettingsTitle, MVCBillingTitle, MVCHelpTitle];
}

@end
