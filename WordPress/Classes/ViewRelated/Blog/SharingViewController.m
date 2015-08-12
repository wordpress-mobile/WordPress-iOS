#import "SharingViewController.h"
#import "Blog.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "Publicizer.h"

NS_ENUM(NSInteger, SharingSection) {
    SharingPublicize = 0,
    //SharingConnections,
    //SharingButtons,
    //SharingOptions,
    SharingSectionCount,
};

static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface SharingViewController ()

@property (nonatomic, strong, readonly) Blog *blog;

@property (nonatomic, strong) NSArray *publicizeServices;

@end

@implementation SharingViewController

- (instancetype)initWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _blog = blog;
        _publicizeServices = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Sharing", @"Title for blog detail sharing screen.");

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:PublicizeCellIdentifier];

    self.publicizeServices = [self.blog.publicizers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:TRUE]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SharingSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return NSLocalizedString(@"Publicize", @"Section title for Publicize services in Sharing screen");
        default:
            return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
        header.title = title;
        return header;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SharingPublicize:
            return self.publicizeServices.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];

    switch (indexPath.section) {
        case SharingPublicize: {
            Publicizer *publicizer = self.publicizeServices[indexPath.row];
            cell.textLabel.text = publicizer.label;

            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(cellButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            NSString *title = publicizer.isConnected ? NSLocalizedString(@"Disconnect", @"Button title to disconnect a Publicize service") : NSLocalizedString(@"Connect", @"Button title to connect a Publicize service");
            [button setTitle:title forState:UIControlStateNormal];
            [button sizeToFit];
            cell.accessoryView = button;
        } break;
        default:
            break;
    }
    
    return cell;
}

- (void)cellButtonTapped:(UIButton *)sender
{
    UITableViewCell *tappedCell = (UITableViewCell *)[sender superview];
    NSIndexPath *tappedPath = [self.tableView indexPathForCell:tappedCell];
    [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:tappedPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Publicizer *publicizer = self.publicizeServices[indexPath.row];
    if (publicizer.isConnected) {
#warning implement disconnection
    } else {
#warning implement connection
    }
}

@end
