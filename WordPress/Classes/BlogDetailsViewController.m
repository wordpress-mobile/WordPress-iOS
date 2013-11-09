//
//  BlogDetailsViewController.m
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BlogDetailsViewController.h"
#import "Blog+Jetpack.h"
#import "EditSiteViewController.h"
#import "PostViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "StatsWebViewController.h"
#import "WPWebViewController.h"

typedef enum {
    BlogDetailsRowPosts = 0,
    BlogDetailsRowPages,
    BlogDetailsRowComments,
    BlogDetailsRowStats,
    BlogDetailsRowViewSite,
    BlogDetailsRowViewAdmin,
    BlogDetailsRowEdit,
    BlogDetailsRowCount
} BlogDetailsRow;


@interface BlogDetailsViewController ()

@end

@implementation BlogDetailsViewController
@synthesize blog = _blog;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setBlog:(Blog *)blog {
    _blog = blog;
    self.title = blog.blogName;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return BlogDetailsRowCount;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == BlogDetailsRowPosts) {
        cell.textLabel.text = NSLocalizedString(@"Posts", nil);
    } else if (indexPath.row == BlogDetailsRowPages) {
        cell.textLabel.text = NSLocalizedString(@"Pages", nil);
    } else if (indexPath.row == BlogDetailsRowComments) {
        cell.textLabel.text = NSLocalizedString(@"Comments", nil);
    } else if (indexPath.row == BlogDetailsRowStats) {
        cell.textLabel.text = NSLocalizedString(@"Stats", nil);
    } else if (indexPath.row == BlogDetailsRowViewSite) {
        cell.textLabel.text = NSLocalizedString(@"View Site", nil);
    } else if (indexPath.row == BlogDetailsRowViewAdmin) {
        cell.textLabel.text = NSLocalizedString(@"View Admin", nil);
    } else if (indexPath.row == BlogDetailsRowEdit) {
        cell.textLabel.text = NSLocalizedString(@"Edit Blog", nil);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"BlogDetailsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    [WPStyleGuide configureTableViewCell:cell];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == BlogDetailsRowEdit) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedEditBlog];
        
        EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] init];
        editSiteViewController.blog = self.blog;
        [self.navigationController pushViewController:editSiteViewController animated:YES];
    }
    
    Class controllerClass;
    if (indexPath.row == BlogDetailsRowPosts) {
        [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedPosts forEvent:StatsEventAppClosed];
        controllerClass = [PostsViewController class];
    } else if (indexPath.row == BlogDetailsRowPages) {
        [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedPages forEvent:StatsEventAppClosed];
        controllerClass = [PagesViewController class];
    } else if (indexPath.row == BlogDetailsRowComments) {
        [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedComments forEvent:StatsEventAppClosed];
        controllerClass = [CommentsViewController class];
    } else if (indexPath.row == BlogDetailsRowStats) {
        [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedStats forEvent:StatsEventAppClosed];
        controllerClass =  [StatsWebViewController class];
    } else if (indexPath.row == BlogDetailsRowViewSite) {
        [self showViewSiteForBlog:self.blog];
    } else if (indexPath.row == BlogDetailsRowViewAdmin) {
        [self showViewAdminForBlog:self.blog];
    }
        
    // Check if the controller is already on the screen
    if ([self.navigationController.visibleViewController isMemberOfClass:controllerClass]) {
        if ([self.navigationController.visibleViewController respondsToSelector:@selector(setBlog:)]) {
            [self.navigationController.visibleViewController performSelector:@selector(setBlog:) withObject:self.blog];
        }
        [self.navigationController popToRootViewControllerAnimated:NO];
    
        return;
    }

    UIViewController *viewController = (UIViewController *)[[controllerClass alloc] init];
    if ([viewController respondsToSelector:@selector(setBlog:)]) {
        [viewController performSelector:@selector(setBlog:) withObject:self.blog];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    
}

#pragma mark - Private methods
- (void)showViewSiteForBlog:(Blog *)blog {
    [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedViewSite forEvent:StatsEventAppClosed];
    
    NSString *blogURL = blog.homeURL;
    if (![blogURL hasPrefix:@"http"]) {
        blogURL = [NSString stringWithFormat:@"http://%@", blogURL];
    } else if ([blog isWPcom] && [blog.url rangeOfString:@"wordpress.com"].location == NSNotFound) {
        blogURL = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@""];
    }
    
    // Check if the same site already loaded
    if ([self.navigationController.visibleViewController isMemberOfClass:[WPWebViewController class]] &&
        [((WPWebViewController*)self.navigationController.visibleViewController).url.absoluteString isEqual:blogURL]) {
        // Do nothing
    } else {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[NSURL URLWithString:blogURL]];
        if ([blog isPrivate]) {
            [webViewController setUsername:blog.username];
            [webViewController setPassword:blog.password];
            [webViewController setWpLoginURL:[NSURL URLWithString:blog.loginUrl]];
        }
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    return;
}

- (void)showViewAdminForBlog:(Blog *)blog
{
    [WPMobileStats incrementProperty:StatsPropertySidebarSiteClickedViewAdmin forEvent:StatsEventAppClosed];
    
    NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl]];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end
