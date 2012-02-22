//
//  BlogViewController.m
//  WordPress
//
//  Created by Josh Bassett on 8/07/09.
//

#import "BlogViewController.h"
#import "WPWebViewController.h"
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "StatsTableViewController.h"
#import "UIImageView+Gravatar.h"

@implementation BlogViewController

@synthesize blog;
@synthesize blavatarImageView, blogTitleLabel, blogUrlLabel;
@synthesize tableView;

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    if (blog != nil) {
        if ([blog valueForKey:@"blogName"] != nil)
            self.title = [blog valueForKey:@"blogName"];
        else
            self.title = NSLocalizedString(@"Blog", @"");
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBlog)];
        
        self.blogTitleLabel.text = self.title;
        
        self.blavatarImageView.layer.cornerRadius = 4.0f;        
        self.blavatarImageView.layer.masksToBounds = YES;
        
        [self.blavatarImageView setImageWithBlavatarUrl:blog.blavatarUrl];

        self.blogUrlLabel.text = self.blog.hostURL;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];	
}

- (void)viewDidUnload {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.blavatarImageView = nil;
    self.blogTitleLabel = nil;
    self.blogUrlLabel = nil;
    self.tableView = nil;
    
	[super viewDidUnload];
}

- (void) viewWillDisappear:(BOOL)animated{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[super viewWillDisappear:animated];
}

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    self.blavatarImageView = nil;
    self.blogTitleLabel = nil;
    self.blogUrlLabel = nil;
    self.tableView = nil;

    self.blog = nil;
	
    [super dealloc];
}

#pragma mark - TODO - refresh blog all at once
- (void)refreshBlog {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    WPFLog(@"Start blog sync");
    [self.blog syncBlogWithSuccess:^{
        WPFLog(@"End blog sync");
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } failure:^(NSError *error) {
        WPFLog(@"Blog sync failed: %@", [error localizedDescription]);
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"BlogTableViewCell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BlogTableViewCell"] autorelease];
    }

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Posts", @"");
            cell.detailTextLabel.text = @"X posts";
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Pages", @"");
            cell.detailTextLabel.text = @"X pages";
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"Comments", @"");
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d comments", @""), self.blog.comments.count];
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"Stats", @"");
            cell.detailTextLabel.text = @"X visits today";
            break;
        case 4:
            cell.textLabel.text = NSLocalizedString(@"Advanced", @"");
            cell.detailTextLabel.text = @"Visit your site's dashboard";
            break;
            
        default:
            break;
    }
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"BlogViewController selected %d, %d", indexPath.section, indexPath.row);
    UIViewController *nextViewController = nil;
    switch (indexPath.row) {
        case 0:
        {
            PostsViewController *postsViewController = [[PostsViewController alloc] init];
            postsViewController.blog = self.blog;
            nextViewController = postsViewController;
            break;
        }
        case 1:
        {
            PagesViewController *pagesViewController = [[PagesViewController alloc] init];
            pagesViewController.blog = self.blog;
            nextViewController = pagesViewController;
            break;
        }
        case 2:
        {
            CommentsViewController *commentsViewController = [[CommentsViewController alloc] init];
            commentsViewController.blog = self.blog;
            nextViewController = commentsViewController;
            break;
        }
        case 3:
        {
            StatsTableViewController *statsViewController = [[StatsTableViewController alloc] init];
            statsViewController.blog = self.blog;
            nextViewController = statsViewController;
            break;
        }
        case 4:
        {
            WPWebViewController *webViewController = [[WPWebViewController alloc] init];
            NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
            NSError *error = nil;
            [webViewController setUrl:[NSURL URLWithString:dashboardUrl]];
            [webViewController setUsername:blog.username];
            [webViewController setPassword:[SFHFKeychainUtils getPasswordForUsername:blog.username andServiceName:blog.hostURL error:&error]];
            NSString *wpLoginURL = [self.blog blogLoginURL];
            [webViewController setWpLoginURL:[NSURL URLWithString:wpLoginURL]];
            nextViewController = webViewController;
            break;
        }
        default:
            break;
    }
    if (nextViewController != nil) {
        [self.navigationController pushViewController:nextViewController animated:YES];
        [nextViewController release];
    } else {
        [FileLogger log:@"%@ %@ | nextViewController is nil!", self, NSStringFromSelector(_cmd)];
    }

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
