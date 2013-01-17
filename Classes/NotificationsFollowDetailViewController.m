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
#import "NSString+Helpers.h"
#import "NotificationsFollowTableViewCell.h"
#import "WPWebViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface NotificationsFollowDetailViewController ()

@property NSMutableArray *noteData;
@property BOOL hasFooter;

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
    
    NSString *headerText = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"header_text"];
    if (headerText) {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 40.0f)];
        [headerLabel setBackgroundColor:[UIColor UIColorFromHex:0xDEDEDE]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[UIColor UIColorFromHex:0x5F5F5F]];
        [headerLabel setFont:[UIFont systemFontOfSize:13.0f]];
        [headerLabel setText: headerText];
        [self.tableView setTableHeaderView:headerLabel];
        [self.view bringSubviewToFront:_postTitleView];
        
        NSString *headerLink = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"header_link"];
        if (headerLink) {
            NSURL *postURL = [NSURL URLWithString:headerLink];
            if (postURL) {
                NSString *blavatarURL = [NSString stringWithFormat:@"http://gravatar.com/blavatar/%@?s=72&d=404", [[postURL host] md5]];
                [_postBlavatar setImageWithURL:[NSURL URLWithString:blavatarURL] placeholderImage:[UIImage imageNamed:@"blavatar-wpcom"]];
            }
        }
    }
    
    if (_note.subject) {
        // Silly way to get the post title until we get it from the API directly
        NSArray *quotedText = [_note.subject componentsSeparatedByString: @"\""];
        if ([quotedText count] >= 3) {
            NSString *postTitle = [quotedText objectAtIndex:[quotedText count] - 2];
            [_postTitleLabel setText:postTitle];
        }
    }
    
    
    NSString *footerText = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"footer_text"];
    if (footerText && ![footerText isEqualToString:@""]) {
        _hasFooter = YES;
    }
    
    [_tableView setDelegate: self];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
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
    if (_hasFooter)
        return 2;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
        return [_noteData count];
    else
        return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return 100.0f;
    else
        return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"FollowCell";
        NotificationsFollowTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[NotificationsFollowTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            [cell.actionButton addTarget:self action:@selector(followBlog:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        [cell.actionButton setHidden:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
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
                     NSString *blogTitle = [selectedNote objectForKey:@"header_text"];
                     if ([blogTitle length] == 0)
                         blogTitle = NSLocalizedString(@"(No Title)", @"Blog with no title");
                     [cell.actionButton setTitle:blogTitle forState:UIControlStateNormal];
                }
                [cell.actionButton setTag:indexPath.row];
                if ([noteActionDetails objectForKey:@"blog_url"]) {
                    cell.detailTextLabel.text = [[NSString decodeXMLCharactersIn:[noteActionDetails objectForKey:@"blog_url"]] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
            } else {
                [cell.actionButton setHidden:YES];
            }
        } else {
            // No action available for this user
            [cell.actionButton setHidden:YES];
            cell.textLabel.text = [selectedNote objectForKey:@"header_text"];
        }
        if ([selectedNote objectForKey:@"icon"]) {
            NSString *imageURL = [[selectedNote objectForKey:@"icon"] stringByReplacingOccurrencesOfString:@"s=32" withString:@"s=160"];
            [cell.imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"note_icon_placeholder"]];
        }
        return cell;
    } else {
        static NSString *CellIdentifier = @"FooterCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
            cell.backgroundView = imageView;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = [UIColor UIColorFromHex:0x0074A2];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        }
        NSString *footerText = [[[_note getNoteData] objectForKey:@"body"] objectForKey:@"footer_text"];
        cell.textLabel.text = footerText;
        return cell;
    }
    
    return nil;
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
    
    if (self.panelNavigationController)
        [self.panelNavigationController showToastWithMessage:(isFollowing) ?  NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") : NSLocalizedString(@"Followed", @"User followed a blog") andImage:[UIImage imageNamed:[NSString stringWithFormat:@"action_icon_%@", (isFollowing) ? @"unfollowed" : @"followed"]]];
    
    NSUInteger blogID = [[noteDetails objectForKey:@"blog_id"] intValue];
    if (blogID) {
        [[WordPressComApi sharedApi] followBlog:blogID isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *followResponse = (NSDictionary *)responseObject;
            if (followResponse && [[followResponse objectForKey:@"success"] intValue] == 1) {
                if ([[followResponse objectForKey:@"is_following"] intValue] == 1) {
                    [cell setFollowing: YES];
                    [noteDetails setValue:[NSNumber numberWithInt:1] forKey:@"is_following"];
                }
                else {
                    [cell setFollowing: NO];
                    [noteDetails setValue:[NSNumber numberWithInt:0] forKey:@"is_following"];
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [cell setFollowing: isFollowing];
        }];
    }   
}

- (IBAction)viewPostTitle:(id)sender {
    [self loadWebViewWithURL:[[[_note getNoteData] objectForKey:@"body"] objectForKey:@"header_link"]];
}

- (void)loadWebViewWithURL: (NSString*)url {
    if (!url)
        return;
    
    NSURL *webViewURL = [NSURL URLWithString:url];
    if (webViewURL) {
        WPWebViewController *webViewController = nil;
        if ( IS_IPAD ) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        
        [webViewController setUrl:webViewURL];
        [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
    }
    
}

- (IBAction)highlightButton:(id)sender {
    [_postTitleButton setBackgroundColor:[UIColor UIColorFromHex:0xEDEDED]];
}

- (IBAction)resetButton:(id)sender {
    [_postTitleButton setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
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
            [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    } else {
        [self loadWebViewWithURL:[[[_note getNoteData] objectForKey:@"body"] objectForKey:@"footer_link"]];
    }
    
}

@end
