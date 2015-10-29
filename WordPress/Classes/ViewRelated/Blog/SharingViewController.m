#import "SharingViewController.h"
#import "Blog.h"
#import "BlogService.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "Publicizer.h"
#import "SVProgressHUD.h"
#import "SharingAuthorizationWebViewController.h"
#import "RemotePublicizeExternal.h"
#import "UIActionSheet+Helpers.h"

typedef NS_ENUM(NSInteger, SharingSection){
    SharingPublicize = 0,
    //SharingConnections,
    //SharingButtons,
    //SharingOptions,
    SharingSectionCount,
};

static NSString *const PublicizeCellIdentifier = @"PublicizeCell";

@interface PublicizeCell : WPTableViewCell
@end

@implementation PublicizeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end

@interface SharingViewController () <SharingAuthorizationDelegate>

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong) NSArray *publicizeServices;
@property (nonatomic, strong) Publicizer *connectingService;
@property (nonatomic, strong) Publicizer *disconnectingService;

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

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[PublicizeCell class] forCellReuseIdentifier:PublicizeCellIdentifier];
    
    [self refreshPublicizers];
    
}

- (void)refreshPublicizers
{
    self.connectingService = nil;
    self.disconnectingService = nil;
    self.publicizeServices = [self.blog.publicizers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:TRUE]]];
    [self.tableView reloadData];
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
    PublicizeCell *cell = [tableView dequeueReusableCellWithIdentifier:PublicizeCellIdentifier forIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];
    
    switch (indexPath.section) {
        case SharingPublicize: {
            Publicizer *publicizer = self.publicizeServices[indexPath.row];
            cell.textLabel.text = publicizer.label;
            NSString *title = nil;
            if ([self.connectingService.service isEqualToString:publicizer.service]) {
                title = NSLocalizedString(@"Connecting…", @"Button title while a Publicize service is connecting");
            } else if ([self.disconnectingService.service isEqualToString:publicizer.service]) {
                title = NSLocalizedString(@"Disconnecting…", @"Button title while a Publicize service is disconnecting");
            } else if (publicizer.isConnected) {
                title = NSLocalizedString(@"Disconnect", @"Button title to disconnect a Publicize service");
            } else {
                title = NSLocalizedString(@"Connect", @"Button title to connect a Publicize service");
            }
            cell.detailTextLabel.text = title;
        } break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.connectingService || self.disconnectingService) {
        return;
    }
    
    Publicizer *publicizer = self.publicizeServices[indexPath.row];
    if (publicizer.isConnected) {
        self.disconnectingService = publicizer;
        [self disconnectPublicizer:publicizer];

    } else {
        self.connectingService = publicizer;
        [self updateAuthorizationForPublicizer:publicizer];
    }

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Publicizer management

- (void)syncConnections
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    __weak __typeof__(self) weakSelf = self;
    [blogService syncConnectionsForBlog:self.blog success:^{
        [weakSelf refreshPublicizers];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Synchronization failed", @"Message to show when Publicize connection synchronization failed")];
        [weakSelf refreshPublicizers];
    }];
}

- (void)connectPublicizer:(Publicizer *)publicizer
        withAuthorization:(NSNumber *)keyring
               andAccount:(NSString *)account
{
    NSParameterAssert(publicizer);
    NSParameterAssert(keyring);
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];

    __weak __typeof__(self) weakSelf = self;
    [blogService connectPublicizer:publicizer
                 withAuthorization:keyring
                        andAccount:account
                           success:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Connect failed", @"Message to show when Publicize connect failed")];
        [weakSelf syncConnections];
    }];
}

- (void)selectAccountFrom:(NSArray *)accounts
            forPublicizer:(Publicizer *)publicizer
{
    NSParameterAssert([[accounts firstObject] isKindOfClass:[RemotePublicizeExternal class]]);
    NSParameterAssert(publicizer);

    __weak __typeof__(self) weakSelf = self;
    NSArray *accountNames = [accounts valueForKeyPath:@"name"];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect account:", @"Title of Publicize account selection")
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:accountNames
                                                           completion:^(NSString *buttonTitle){
                                                               __typeof__(self) strongSelf = weakSelf;
                                                               if (!strongSelf) {
                                                                   return;
                                                               }
                                                               [strongSelf handleSelectedAccountWithName:buttonTitle
                                                                                                    from:accounts
                                                                                           forPublicizer:publicizer];
                                                           }];
    [actionSheet showInView:self.view];
}


- (void)handleSelectedAccountWithName:(NSString *)accountName
                                 from:(NSArray *)accounts
                        forPublicizer:(Publicizer *)publicizer
{
    NSArray *accountNames = [accounts valueForKeyPath:@"name"];
    for (NSUInteger accountIndex = 0; accountIndex < accounts.count; accountIndex++) {
        if ([accountNames[accountIndex] isEqualToString:accountName]) {
            RemotePublicizeExternal *account = (RemotePublicizeExternal *)accounts[accountIndex];
            NSString *secondaryAccount = accountIndex > 0 ? account.account : nil;
            [self connectPublicizer:publicizer
                  withAuthorization:account.keyring
                         andAccount:secondaryAccount];
            return;
        }
    }
    [self refreshPublicizers];
}

- (void)checkAuthorizationForPublicizer:(Publicizer *)publicizer
{
    NSParameterAssert(publicizer);

    __weak __typeof__(self) weakSelf = self;
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService checkAuthorizationForPublicizer:publicizer success:^(NSArray *accounts) {
        [weakSelf selectAccountFrom:accounts
                      forPublicizer:publicizer];
    } failure:^(NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Authorization failed", @"Message to show when Publicize authorization failed")];
        }
        [weakSelf refreshPublicizers];
    }];
}

- (void)authorizePublicizer:(Publicizer *)publicizer
                withRefresh:(NSString *)refresh
{
    NSParameterAssert(publicizer);
    
    SharingAuthorizationWebViewController *webViewController = [SharingAuthorizationWebViewController controllerWithPublicizer:publicizer
                                                                                                                    andRefresh:refresh
                                                                                                                       forBlog:self.blog];
    webViewController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)authorizeDidSucceed:(Publicizer *)publicizer
{
    [self checkAuthorizationForPublicizer:publicizer];
}

- (void)authorize:(Publicizer *)publicizer didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Authorization failed", @"Message to show when Publicize authorization failed")];
    [self syncConnections];
}

- (void)authorizeDidCancel:(Publicizer *)publicizer
{
    // called in response to user dismissal
    [self refreshPublicizers];
}

- (void)updateAuthorizationForPublicizer:(Publicizer *)publicizer
{
    NSParameterAssert(publicizer);
    
    __weak __typeof__(self) weakSelf = self;
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService checkAuthorizationForPublicizer:publicizer success:^(NSArray *accounts) {
        RemotePublicizeExternal *account = (RemotePublicizeExternal *)accounts.firstObject;
        [weakSelf authorizePublicizer:publicizer
                          withRefresh:account.refresh];
    } failure:^(NSError *error) {
        [weakSelf authorizePublicizer:publicizer
                          withRefresh:nil];
    }];
}

- (void)disconnectPublicizer:(Publicizer *)publicizer
{
    NSParameterAssert(publicizer);
    
    __weak __typeof__(self) weakSelf = self;
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService disconnectPublicizer:publicizer success:^{
        [weakSelf syncConnections];
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Disconnect failed", @"Message to show when Publicize disconnect failed")];
        [weakSelf syncConnections];
    }];
}

@end
