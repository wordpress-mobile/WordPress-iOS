//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"
#import "AddUsersBlogsViewController.h"
#import "WordPressComApi.h"
#import "JetpackSettingsViewController.h"
#import "WPAccount.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface EditSiteViewController (PrivateMethods)
- (void)validationDidFail:(id)wrong;
@end

@implementation AddSiteViewController

CGSize const AddSiteLogoSize = { 320.0, 70.0 };

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, AddSiteLogoSize.width, AddSiteLogoSize.height);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    tableView.tableHeaderView = logoImage;
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    self.navigationItem.title = NSLocalizedString(@"Add Blog", @"");
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)validationSuccess:(NSString *)xmlrpc {
    WPFLog(@"hasSubsites: %@", subsites);

    if ([subsites count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install, 
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([subsites count] > 1) {
            if (_blogId) {
                subsite = [[subsites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"blogid = %@", _blogId]] lastObject];
            }
            if (!subsite) {
                subsite = [[subsites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlrpc]] lastObject];
            }
        }
        
        if (subsite == nil) {
            subsite = [subsites objectAtIndex:0];
        }

        if ([subsites count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            [self displayAddUsersBlogsForXmlRpc:xmlrpc];
        } else {
            if (_isSiteDotCom) {
                xmlrpc = [subsite objectForKey:@"xmlrpc"];
            }
            [self createBlogWithXmlRpc:xmlrpc andBlogDetails:subsite];
            [self synchronizeNewlyAddedBlog];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", @"")}];
        [self validationDidFail:error];
    }
	[self.navigationItem setHidesBackButton:NO animated:NO];
    saveButton.enabled = YES;            
}

- (void)displayAddUsersBlogsForXmlRpc:(NSString *)xmlrpc
{
    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:self.username andPassword:self.password];

    AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithAccount:account];
    addUsersBlogsView.isWPcom = NO;
    addUsersBlogsView.usersBlogs = subsites;
    addUsersBlogsView.url = xmlrpc;
    addUsersBlogsView.username = self.username;
    addUsersBlogsView.password = self.password;
    addUsersBlogsView.geolocationEnabled = self.geolocationEnabled;
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlrpc andBlogDetails:(NSDictionary *)blogDetails
{
    NSAssert(blogDetails != nil, nil);

    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:self.username andPassword:self.password];

    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:xmlrpc forKey:@"xmlrpc"];
 
    self.blog = [account findOrCreateBlogFromDictionary:newBlog];
    self.blog.geolocationEnabled = self.geolocationEnabled;
    [self.blog dataSave];
}

- (void)synchronizeNewlyAddedBlog
{
    void (^successBlock)() = ^{
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
        if (![self.blog isWPcom] && [self.blog hasJetpack]) {
            [self connectToJetpack];
        } else {
            [self dismiss];
        }        
    };
    void (^failureBlock)(NSError*) = ^(NSError * error) {
        [SVProgressHUD dismiss];
    };
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", @"") maskType:SVProgressHUDMaskTypeBlack];
    [self.blog syncBlogWithSuccess:successBlock failure:failureBlock];
}

- (void)connectToJetpack
{
    NSString *wpcomUsername = [WordPressComApi sharedApi].username;
    NSString *wpcomPassword = [WordPressComApi sharedApi].password;
    if ((wpcomUsername != nil) && (wpcomPassword != nil)) {
        // Try with a known WordPress.com username first
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to Jetpack", @"") maskType:SVProgressHUDMaskTypeBlack];
        [self.blog validateJetpackUsername:wpcomUsername
                                  password:wpcomPassword
                                   success:^{ [self dismiss]; }
                                   failure:^(NSError *error) { [self showJetpackAuthentication]; }
         ];
    } else {
        [self showJetpackAuthentication];
    }
}

- (void)dismiss {
    [SVProgressHUD dismiss];
    if (IS_IPAD) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)showJetpackAuthentication {
    [SVProgressHUD dismiss];
    JetpackSettingsViewController *jetpackSettingsViewController = [[JetpackSettingsViewController alloc] initWithBlog:self.blog];
    jetpackSettingsViewController.canBeSkipped = YES;
    [jetpackSettingsViewController setCompletionBlock:^(BOOL didAuthenticate) {
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    }];
    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}

- (BOOL)canEditUsernameAndURL
{
    return YES;
}

@end

