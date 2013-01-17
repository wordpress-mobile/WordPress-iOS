//
//  NotificationsLikesDetailViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 11/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsFollowDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressComApi.h"
#import "NSString+XMLExtensions.h"
#import "NotificationsFollowTableViewCell.h"
#import "WPWebViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface NotificationsFollowDetailViewController ()

@property NSMutableArray *likeData;

- (void)followBlog:(id)sender;

@end

@implementation NotificationsFollowDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
    }
    return self;
}

- (void)setNote:(Note *)note {
    if (note != _note) {
        _note = note;
    }
    self.title = note.subject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    if (_note) {
        _likeData = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"items"];
    }
    
    if ([_likeData count] > 1)
        _headerLabel.text = NSLocalizedString(@"These people liked your post so far:", @"Header for following detail view, plural");
    else
        _headerLabel.text = NSLocalizedString(@"This person liked your post so far:", @"Header for following detail view, singular");
    
    [_postTitleView.layer setMasksToBounds:NO];
    [_postTitleView.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [_postTitleView.layer setShadowOffset:CGSizeMake(0.0, 2.0)];
    [_postTitleView.layer setShadowRadius:2.0f];
    [_postTitleView.layer setShadowOpacity:0.3f];
    
    /*[_tableView.layer setMasksToBounds:NO];
    [_tableView.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [_tableView.layer setShadowOffset:CGSizeMake(0.0, -1.0)];
    [_tableView.layer setShadowRadius:1.0f];
    [_tableView.layer setShadowOpacity:0.3f];*/
    
    [_tableView setDelegate: self];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_likeData count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FollowCell";
    NotificationsFollowTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[NotificationsFollowTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell.followButton addTarget:self action:@selector(followBlog:) forControlEvents:UIControlEventTouchUpInside];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *like = [_likeData objectAtIndex:indexPath.row];
    NSDictionary *likeActions = [like objectForKey:@"action"];
    NSDictionary *likeDetails;
    if ([likeActions isKindOfClass:[NSDictionary class]])
        likeDetails = [likeActions objectForKey:@"params"];
    UIButton *followButton = [cell.subviews objectAtIndex:2];
    if (likeDetails) {
        if (![[likeDetails objectForKey:@"blog_title"] isEqualToString:@""]) {
            [cell.followButton setTitle:[NSString decodeXMLCharactersIn: [likeDetails objectForKey:@"blog_title"]] forState:UIControlStateNormal];
            if ([[likeDetails objectForKey:@"is_following"] intValue] == 1) {
                [cell setFollowing: YES];
            } else {
                [cell setFollowing: NO];
            }
                
            [cell.followButton setTag:indexPath.row];
        } else {
            NSString *blogTitle = [like objectForKey:@"header"];
            if (blogTitle && [blogTitle length] > 0)
                blogTitle = [blogTitle stringByReplacingOccurrencesOfString:@"<.+?>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, blogTitle.length)];
            else
                blogTitle = NSLocalizedString(@"(No Title)", @"Blog with no title");
            [cell.followButton setTitle:blogTitle forState:UIControlStateNormal];
        }
        cell.textLabel.text = [[NSString decodeXMLCharactersIn:[likeDetails objectForKey:@"blog_url"]] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    } else {
        NSString *blogTitle = [NSString decodeXMLCharactersIn:[like objectForKey:@"header"]];
        cell.textLabel.text = [blogTitle stringByReplacingOccurrencesOfString:@"<.+?>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, blogTitle.length)];
        [followButton setHidden:YES];
    }
    NSString *imageURL = [[like objectForKey:@"icon"] stringByReplacingOccurrencesOfString:@"s=32" withString:@"w=160"];
    [cell.imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
    
    return cell;
}

- (void)followBlog:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger row = button.tag;
    
    NSMutableDictionary *like = [_likeData objectAtIndex:row];
    NSMutableDictionary *likeDetails = [[like objectForKey:@"action"] objectForKey:@"params"];
    
    BOOL isFollowing = [[likeDetails objectForKey:@"is_following"] boolValue];
    
    NotificationsFollowTableViewCell *cell = (NotificationsFollowTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    [cell setFollowing: !isFollowing];
    
    NSUInteger blogID = [[likeDetails objectForKey:@"blog_id"] intValue];
    if (blogID) {
        [[WordPressComApi sharedApi] followBlog:blogID isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *followResponse = (NSDictionary *)responseObject;
            if (followResponse && [[followResponse objectForKey:@"success"] intValue] == 1) {
                if ([[followResponse objectForKey:@"is_following"] intValue] == 1) {
                    [cell setFollowing: YES];
                    [likeDetails setValue:[NSNumber numberWithInt:1] forKey:@"is_following"];
                }
                else {
                    [cell setFollowing: NO];
                    [likeDetails setValue:[NSNumber numberWithInt:0] forKey:@"is_following"];
                }
                
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [cell setFollowing: isFollowing];
        }];
    }
    
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *likeDetails = [[[_likeData objectAtIndex:indexPath.row] objectForKey:@"action"] objectForKey:@"params"];
    if (likeDetails) {
        NSString *blogURLString = [likeDetails objectForKey:@"blog_url"];
        NSURL *blogURL = [NSURL URLWithString:blogURLString];
        if (!blogURL)
            return;
        WPWebViewController *webViewController = nil;
        if ( IS_IPAD ) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }

        [webViewController setUrl:blogURL];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    
}

@end
