//
//  NotificationsLikesDetailViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 11/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsLikesDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressComApi.h"

@interface NotificationsLikesDetailViewController ()

@property NSMutableArray *likeData;

- (void)followBlog:(id)sender;

@end

@implementation NotificationsLikesDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (_note && [_note isLike]) {
        _likeData = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"items"];
    }

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [likeButton setBackgroundColor:[UIColor lightGrayColor]];
        [likeButton.titleLabel setTextColor:[UIColor lightGrayColor]];
        [likeButton setFrame:CGRectMake(cell.frame.size.width - 70, 10, 60, 20)];
        [likeButton setTitle:@"Follow" forState:UIControlStateNormal];
        [likeButton.titleLabel setFont:[UIFont systemFontOfSize:13.0f]];
        [likeButton addTarget:self action:@selector(followBlog:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:likeButton];
        
        [cell.textLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        [cell setBackgroundView:imageView];
    }
    
    NSDictionary *like = [_likeData objectAtIndex:indexPath.row];
    NSDictionary *likeDetails = [[like objectForKey:@"action"] objectForKey:@"params"];
    if (likeDetails && [likeDetails objectForKey:@"blog_title"]) {
        cell.textLabel.text = [likeDetails objectForKey:@"blog_title"];
        NSString *imageURL = [[like objectForKey:@"icon"] stringByReplacingOccurrencesOfString:@"s=32" withString:@"w=200"];
        [cell.imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
    }
    
    
    UIButton *followButton = [cell.subviews objectAtIndex:2];
    if ([[likeDetails objectForKey:@"is_following"] intValue] == 0)
        [followButton setTitle:@"Follow" forState:UIControlStateNormal];
    else
        [followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
    [followButton setTag:indexPath.row];
    
    return cell;
}

- (void)followBlog:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger row = button.tag;
    
    NSMutableDictionary *like = [_likeData objectAtIndex:row];
    NSMutableDictionary *likeDetails = [[like objectForKey:@"action"] objectForKey:@"params"];
    
    BOOL isFollowing = [[likeDetails objectForKey:@"is_following"] boolValue];
    
    if (isFollowing)
        [button setTitle:@"Follow" forState:UIControlStateNormal];
    else
        [button setTitle:@"Unfollow" forState:UIControlStateNormal];
    
    NSUInteger blogID = [[likeDetails objectForKey:@"blog_id"] intValue];
    if (blogID) {
        [[WordPressComApi sharedApi] followBlog:blogID isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *followResponse = (NSDictionary *)responseObject;
            if (followResponse && [[followResponse objectForKey:@"success"] intValue] == 1) {
                if ([[followResponse objectForKey:@"is_following"] intValue] == 1) {
                    [button setTitle:@"Unfollow" forState:UIControlStateNormal];
                    [likeDetails setValue:[NSNumber numberWithInt:1] forKey:@"is_following"];
                }
                else {
                    [button setTitle:@"Follow" forState:UIControlStateNormal];
                    [likeDetails setValue:[NSNumber numberWithInt:0] forKey:@"is_following"];
                }
                
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (isFollowing)
                [button setTitle:@"Follow" forState:UIControlStateNormal];
            else
                [button setTitle:@"Unfollow" forState:UIControlStateNormal];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
