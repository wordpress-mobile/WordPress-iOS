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

@property NSMutableArray *noteData;

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

    if (_note) {
        _noteData = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"items"];
    }
    
    [_postTitleView.layer setMasksToBounds:NO];
    [_postTitleView.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [_postTitleView.layer setShadowOffset:CGSizeMake(0.0, 2.0)];
    [_postTitleView.layer setShadowRadius:2.0f];
    [_postTitleView.layer setShadowOpacity:0.3f];
    
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 40.0f)];
    [headerLabel setBackgroundColor:[UIColor UIColorFromHex:0xDEDEDE]];
    [headerLabel setTextAlignment:NSTextAlignmentCenter];
    [headerLabel setTextColor:[UIColor UIColorFromHex:0x5F5F5F]];
    [headerLabel setFont:[UIFont systemFontOfSize:13.0f]];
    [headerLabel setText: [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"header"]];
    [self.tableView setTableHeaderView:headerLabel];
    [self.view bringSubviewToFront:_postTitleView];
    
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
    return [_noteData count];
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
        [cell.actionButton addTarget:self action:@selector(followBlog:) forControlEvents:UIControlEventTouchUpInside];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *selectedNote = [_noteData objectAtIndex:indexPath.row];
    NSDictionary *noteAction = [selectedNote objectForKey:@"action"];
    NSDictionary *noteActionDetails;
    if ([noteAction isKindOfClass:[NSDictionary class]])
        noteActionDetails = [noteAction objectForKey:@"params"];
    if (noteActionDetails) {
        if ([[noteAction objectForKey:@"type"] isEqualToString:@"follow"]) {
             if (![[noteActionDetails objectForKey:@"blog_title"] isEqualToString:@""]) {
                 [cell.actionButton setTitle:[NSString decodeXMLCharactersIn: [noteActionDetails objectForKey:@"blog_title"]] forState:UIControlStateNormal];
                 if ([[noteActionDetails objectForKey:@"is_following"] intValue] == 1) {
                     [cell setFollowing: YES];
                 } else {
                     [cell setFollowing: NO];
                 }
            } else {
                 NSString *blogTitle = [selectedNote objectForKey:@"header"];
                 if (blogTitle && [blogTitle length] > 0)
                 blogTitle = [blogTitle stringByReplacingOccurrencesOfString:@"<.+?>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, blogTitle.length)];
                 else
                 blogTitle = NSLocalizedString(@"(No Title)", @"Blog with no title");
                 [cell.actionButton setTitle:blogTitle forState:UIControlStateNormal];
            }
            [cell.actionButton setTag:indexPath.row];
            if ([noteActionDetails objectForKey:@"blog_url"])
                cell.textLabel.text = [[NSString decodeXMLCharactersIn:[noteActionDetails objectForKey:@"blog_url"]] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        } else {
            [cell.actionButton setHidden:YES];
        }
    }
    if ([selectedNote objectForKey:@"icon"]) {
        NSString *imageURL = [[selectedNote objectForKey:@"icon"] stringByReplacingOccurrencesOfString:@"s=32" withString:@"w=160"];
        [cell.imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
    }
    
    return cell;
}

- (void)followBlog:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger row = button.tag;
    
    NSMutableDictionary *selectedNote = [_noteData objectAtIndex:row];
    NSDictionary *noteAction = [selectedNote objectForKey:@"action"];
    NSDictionary *noteDetails;
    if ([noteAction isKindOfClass:[NSDictionary class]])
        noteDetails = [noteAction objectForKey:@"params"];

    BOOL isFollowing = [[noteDetails objectForKey:@"is_following"] boolValue];
    
    NotificationsFollowTableViewCell *cell = (NotificationsFollowTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    [cell setFollowing: !isFollowing];
    
    NSUInteger blogID = [[noteDetails objectForKey:@"blog_id"] intValue];
    if (blogID) {
        [[WordPressComApi sharedApi] followBlog:blogID isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *followResponse = (NSDictionary *)responseObject;
            if (followResponse && [[followResponse objectForKey:@"success"] intValue] == 1) {
                if ([[followResponse objectForKey:@"is_following"] intValue] == 1) {
                    [cell setFollowing: YES];
                    [noteDetails setValue:[NSNumber numberWithInt:1] forKey:@"is_following"];
                    if (self.panelNavigationController)
                        [self.panelNavigationController showToastWithMessage:NSLocalizedString(@"Followed", @"User followed a blog") andImage:[UIImage imageNamed:@"action_icon_followed"]];
                }
                else {
                    [cell setFollowing: NO];
                    [noteDetails setValue:[NSNumber numberWithInt:0] forKey:@"is_following"];
                    if (self.panelNavigationController)
                        [self.panelNavigationController showToastWithMessage:NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") andImage:[UIImage imageNamed:@"action_icon_unfollowed"]];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [cell setFollowing: isFollowing];
        }];
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *noteAction = [[_noteData objectAtIndex:indexPath.row] objectForKey:@"action"];
    NSDictionary *likeDetails;
    if ([noteAction isKindOfClass:[NSDictionary class]])
        likeDetails = [noteAction objectForKey:@"params"];
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
