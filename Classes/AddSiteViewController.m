//
//  AddSiteViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.

#import "AddSiteViewController.h"

@implementation AddSiteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wporg.png"]];
    logoView.frame = CGRectMake(0, 0, 320, 60);
    logoView.contentMode = UIViewContentModeCenter;
    logoView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableView.tableHeaderView = logoView;
    [logoView release];
	if (IS_IPAD)
		self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor clearColor];
    
    self.navigationItem.title = NSLocalizedString(@"Add Blog", @"");
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (void)validationSuccess:(NSString *)xmlrpc {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApp];
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
            [addUsersBlogsView release];
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
            [self.blog syncBlogWithSuccess:nil failure:nil];
            
            if (IS_IPAD) {
                [self dismissModalViewControllerAnimated:YES];
            }
			else
				[self.navigationController popToRootViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
        }
    }
	[self.navigationItem setHidesBackButton:NO animated:NO];
    saveButton.enabled = YES;            
}

@end

