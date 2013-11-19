/*
 * AddSiteViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

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
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, AddSiteLogoSize.width, AddSiteLogoSize.height);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = logoImage;

    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"Add button to add a site from Settings.") style:[WPStyleGuide barButtonStyleForDone] target:self action:@selector(save:)];
    self.navigationItem.rightBarButtonItem = self.saveButton;

    self.navigationItem.title = NSLocalizedString(@"Add Blog", @"");
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)validationSuccess:(NSString *)xmlrpc {
    DDLogInfo(@"hasSubsites: %@", self.subsites);

    if ([self.subsites count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install, 
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([self.subsites count] > 1) {
            if (self.blogId) {
                subsite = [[self.subsites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"blogid = %@", self.blogId]] lastObject];
            }
            if (!subsite) {
                subsite = [[self.subsites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlrpc]] lastObject];
            }
        }
        
        if (subsite == nil) {
            subsite = [self.subsites objectAtIndex:0];
        }

        if ([self.subsites count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            [self displayAddUsersBlogsForXmlRpc:xmlrpc];
        } else {
            if (self.isSiteDotCom) {
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
    self.saveButton.enabled = YES;
}

- (void)displayAddUsersBlogsForXmlRpc:(NSString *)xmlrpc
{
    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:self.username andPassword:self.password];

    AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithAccount:account];
    addUsersBlogsView.isWPcom = NO;
    addUsersBlogsView.usersBlogs = self.subsites;
    addUsersBlogsView.url = xmlrpc;
    addUsersBlogsView.geolocationEnabled = self.geolocationEnabled;
    [self.navigationController pushViewController:addUsersBlogsView animated:YES];
}

- (void)createBlogWithXmlRpc:(NSString *)xmlrpc andBlogDetails:(NSDictionary *)blogDetails
{
    NSAssert(blogDetails != nil, nil);

    WPAccount *account = [WPAccount createOrUpdateSelfHostedAccountWithXmlrpc:xmlrpc username:self.username andPassword:self.password];

    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogDetails];
    [newBlog setObject:xmlrpc forKey:@"xmlrpc"];
 
    self.blog = [account findOrCreateBlogFromDictionary:newBlog withContext:[WordPressAppDelegate sharedWordPressApplicationDelegate].managedObjectContext];
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
    NSString *wpcomUsername = [[WPAccount defaultWordPressComAccount] username];
    NSString *wpcomPassword = [[WPAccount defaultWordPressComAccount] password];
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
        [self dismissViewControllerAnimated:YES completion:nil];
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
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
    [self.navigationController pushViewController:jetpackSettingsViewController animated:YES];
}

- (BOOL)canEditUsernameAndURL
{
    return YES;
}

@end

