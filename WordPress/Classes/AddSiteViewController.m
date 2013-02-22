//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"
#import "AddUsersBlogsViewController.h"
#import "WordPressComApi.h"
#import "JetpackAuthViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface EditSiteViewController (PrivateMethods)
- (void)validationDidFail:(id)wrong;
@end

@implementation AddSiteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg"]];
    logoImage.frame = CGRectMake(0.0f, 0.0f, 320.0f, 70.0f);
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
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    NSLog(@"hasSubsites: %@", subsites);

    if ([subsites count] > 0) {
        // If the user has entered the URL of a site they own on a MultiSite install, 
        // assume they want to add that specific site.
        NSDictionary *subsite = nil;
        if ([subsites count] > 1)
            subsite = [[subsites filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@", xmlrpc]] lastObject];

        if ([subsites count] > 1 && [[subsite objectForKey:@"blogid"] isEqualToString:@"1"]) {
            AddUsersBlogsViewController *addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
            addUsersBlogsView.isWPcom = NO;
            addUsersBlogsView.usersBlogs = subsites;
            addUsersBlogsView.url = xmlrpc;
            addUsersBlogsView.username = self.username;
            addUsersBlogsView.password = self.password;
			addUsersBlogsView.geolocationEnabled = self.geolocationEnabled;
            [self.navigationController pushViewController:addUsersBlogsView animated:YES];
        } else {
            NSMutableDictionary *newBlog;
            if(subsite)
                newBlog = [NSMutableDictionary dictionaryWithDictionary:subsite];
            else
                newBlog = [NSMutableDictionary dictionaryWithDictionary:[subsites objectAtIndex:0]];
            [newBlog setObject:self.username forKey:@"username"];
            [newBlog setObject:self.password forKey:@"password"];
            [newBlog setObject:xmlrpc forKey:@"xmlrpc"];
            
            self.blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
			self.blog.geolocationEnabled = self.geolocationEnabled;
			[self.blog dataSave];
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Reading blog options", @"") maskType:SVProgressHUDMaskTypeBlack];
            [self.blog syncBlogWithSuccess:^{
                [[WordPressComApi sharedApi] syncPushNotificationInfo];
                if ([self.blog hasJetpack]) {
                    NSString *wpcomUsername = [[WordPressComApi sharedApi] username];
                    NSString *wpcomPassword = [[WordPressComApi sharedApi] password];
                    if (wpcomPassword && wpcomPassword) {
                        // Try with a known WordPress.com username first
                        [SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting to Jetpack", @"") maskType:SVProgressHUDMaskTypeBlack];
                        [self.blog validateJetpackUsername:wpcomUsername
                                                  password:wpcomPassword
                                                   success:^{
                                                       [self dismiss];
                                                   } failure:^(NSError *error) {
                                                       [self showJetpackAuthentication];
                                                   }];
                    } else {
                        [self showJetpackAuthentication];
                    }
                } else {
                    [self dismiss];
                }
            } failure:^(NSError *error) {
                [SVProgressHUD dismiss];
            }];
        }
    } else {
        NSError *error = [NSError errorWithDomain:@"WordPress" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Sorry, you credentials were good but you don't seem to have access to any blogs", @"")}];
        [self validationDidFail:error];
    }
	[self.navigationItem setHidesBackButton:NO animated:NO];
    saveButton.enabled = YES;            
}

- (void)dismiss {
    [SVProgressHUD dismiss];
    if (IS_IPAD) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)showJetpackAuthentication {
    [SVProgressHUD dismiss];
    JetpackAuthViewController *jetpackAuthViewController = [[JetpackAuthViewController alloc] initWithBlog:self.blog];
    [self.navigationController pushViewController:jetpackAuthViewController animated:YES];
}

@end

