#import "MeViewController.h"
#import "SettingsViewController.h"
#import "SupportViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"

static NSString *const MVCCellReuseIdentifier = @"MVCCellReuseIdentifier";
static NSInteger const MVCNumberOfSections = 1;

static CGFloat const MVCTableViewRowHeight = 50.0;
static CGFloat const MVCTableViewHeaderHeight = 200.0;
static CGFloat const MVCGravatarOffset = 20.0;
static CGFloat const MVCGravatarWidth = 120.0;
static CGFloat const MVCGravatarHeight = 120.0;

static NSInteger const MVCAccountSettingsIndex = 0;
static NSInteger const MVCHelpIndex = 1;

static NSString *const MVCAccountSettingsTitle = @"Account Settings";
static NSString *const MVCHelpTitle = @"Help & Support";

@interface MeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong, readonly) NSArray *rowTitles;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *gravatarView;
@property (nonatomic, strong) UILabel *usernameLabel;

@end

@implementation MeViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = MVCTableViewRowHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MVCCellReuseIdentifier];
    [self.view addSubview:self.tableView];

    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), MVCTableViewHeaderHeight)];
    self.tableView.tableHeaderView = self.headerView;

    float x = (self.headerView.frame.size.width - MVCGravatarWidth) / 2.0;
    self.gravatarView = [[UIImageView alloc] initWithFrame:CGRectMake(x, MVCGravatarOffset, MVCGravatarWidth, MVCGravatarHeight)];
    [self.headerView addSubview:self.gravatarView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, self.gravatarView.frame.origin.y + self.gravatarView.frame.size.height + 20.0, self.headerView.frame.size.width, 20.0)];
    self.usernameLabel.font = [WPStyleGuide regularTextFont];
    self.usernameLabel.textColor = [WPStyleGuide wordPressBlue];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.usernameLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

    [self refreshDetails];
}

- (void)refreshDetails
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    [self.gravatarView setImageWithURL:[NSURL URLWithString:@"http://lorempixel.com/240/240/"] emptyCachePlaceholderImage:nil];
    self.usernameLabel.text = [NSString stringWithFormat:@"@%@", defaultAccount.username];
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

- (void)navigateToHelp
{
    SupportViewController *supportViewController = [[SupportViewController alloc] init];
    [self.navigationController pushViewController:supportViewController animated:YES];
}

#pragma mark - Accessors

- (NSArray *)rowTitles
{
    return @[MVCAccountSettingsTitle, MVCHelpTitle];
}

#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    [self refreshDetails];
}

@end
