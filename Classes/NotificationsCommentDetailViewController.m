//
//  NotificationsDetailViewController.m
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NotificationsCommentDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressAppDelegate.h"
#import "DTCoreText.h"
#import "WPWebViewController.h"
#import "NoteCommentCell.h"

#define APPROVE_BUTTON_TAG 1
#define TRASH_BUTTON_TAG 2
#define SPAM_BUTTON_TAG 3

@interface NotificationsCommentDetailViewController () <NoteCommentCellDelegate>

@property NSUInteger followBlogID;
@property BOOL canApprove, canTrash, canSpam;
@property NSArray *commentActions;
@property NSDictionary *followDetails;
@property NSDictionary *comment;
@property NSDictionary *post;
@property NSMutableArray *commentThread;
@property NSNumber *siteID;


@end

@implementation NotificationsCommentDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Notification", @"Title for notification detail view");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.approveBarButton = [self barButtonItemWithImageNamed:@"toolbar_approve"
                                                          andAction:@selector(moderateComment:)];
    self.trashBarButton = [self barButtonItemWithImageNamed:@"toolbar_delete"
                                                   andAction:@selector(moderateComment:)];
    self.spamBarButton = [self barButtonItemWithImageNamed:@"toolbar_flag"
                                                 andAction:@selector(moderateComment:)];
    self.replyBarButton = [self barButtonItemWithImageNamed:@"toolbar_reply"
                                                  andAction:@selector(replyToComment:)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbar.items = @[self.approveBarButton, spacer, self.trashBarButton, spacer, self.spamBarButton, spacer, self.replyBarButton];


    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        [self.tableView registerClass:[NoteCommentCell class] forCellReuseIdentifier:@"NoteCommentCell"];
    }
    [self displayNote];
    
}

- (void)displayNote {
    
    self.title = self.note.subject;
    
    self.postBanner.userInteractionEnabled = NO;
    
    // let's get the real comment off of the api
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    NSDictionary *action = [actions objectAtIndex:0];
    NSArray *items = [self.note.noteData valueForKeyPath:@"body.items"];
    NSDictionary *followAction = [[items lastObject] valueForKeyPath:@"action"];
    
    self.commentThread = [[NSMutableArray alloc] initWithCapacity:1];

    if (![followAction isEqual:@0]) {
        self.followButton = [FollowButton buttonFromAction:followAction withApi:self.user];
    }
    
    self.siteID = [action valueForKeyPath:@"params.blog_id"];
    [self.tableView beginUpdates];
    [self fetchComment:[action valueForKeyPath:@"params.comment_id"]];
    [self.tableView endUpdates];
    
    NSString *postPath = [NSString stringWithFormat:@"sites/%@/posts/%@", [action valueForKeyPath:@"params.blog_id"], [action valueForKeyPath:@"params.post_id"]];
    
    [self.user.restClient getPath:postPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.post = responseObject;
        self.postBanner.titleLabel.text = [self.post valueForKeyPath:@"title"];
        id authorAvatarURL = [self.post valueForKeyPath:@"author.avatar_URL"];
        if ([authorAvatarURL isKindOfClass:[NSString class]]) {
            [self.postBanner.avatarImageView setImageWithURL:[NSURL URLWithString:authorAvatarURL]];
        }
        
        self.postBanner.userInteractionEnabled = YES;
     
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
    
    self.canApprove = NO;
    self.canTrash = NO;
    self.canSpam = NO;
    [actions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *action = obj;
        NSLog(@"Type: %@", [action valueForKeyPath:@"type"]);
        NSString *type = [action valueForKeyPath:@"type"];
        if ([type isEqualToString:@"unapprove-comment"]) {
            self.canApprove = YES;
        } else if ([type isEqualToString:@"spam-comment"]){
            self.canSpam = YES;
        } else if ([type isEqualToString:@"trash-comment"]){
            self.canTrash = YES;
        }
    }];
    
    self.spamBarButton.enabled = self.canSpam;
    self.trashBarButton.enabled = self.canTrash;
    self.approveBarButton.enabled = self.canApprove;
        
    
}

- (UIBarButtonItem *)barButtonItemWithImageNamed:(NSString *)image andAction:(SEL)action {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:action];
    return item;
}


#pragma mark - IBAction

-(void)toggleApproval:(id)sender {
    NSDictionary *approveAction = [self getActionByType:@"approve-comment"];
    NSDictionary *unapproveAction = [self getActionByType:@"unapprove-comment"];
    if (approveAction != nil) {
        NSLog(@"Approve: %@", approveAction);
    } else if(unapproveAction != nil){
        NSLog(@"Unapprove: %@", unapproveAction);
    }
}

- (NSDictionary *)getActionByType:(NSString *)type {
    NSArray *actions = [self.note.noteData valueForKeyPath:@"body.actions"];
    for (NSDictionary *action in actions) {
        if ([[action valueForKey:@"type"] isEqualToString:type]) {
            return action;
        }
    }
    return nil;
}

- (void)performNoteAction:(NSDictionary *)action success:(WordPressComApiRestSuccessFailureBlock)success failure:(WordPressComApiRestSuccessFailureBlock)failure {
    NSDictionary *params = [action objectForKey:@"params"];
    NSString *path = [NSString stringWithFormat:@"sites/%@/comments/%@", [params objectForKey:@"blog_id"], [params objectForKey:@"comment_id"]];
    [self.user.restClient postPath:path parameters:[params objectForKey:@"rest_body"] success:success failure:failure];
    
}

- (void)visitPostURL:(id)sender {
    [self pushToURL:[NSURL URLWithString:[self.post valueForKeyPath:@"URL"]]];
}

- (void)pushToURL:(NSURL *)url {
    WPWebViewController *webViewController = [[WPWebViewController alloc] initWithNibName:nil bundle:nil];
    [webViewController setUrl:url];
    [self.panelNavigationController pushViewController:webViewController animated:YES];
}

- (IBAction)moderateComment:(id)sender {
    
    if (self.commentActions == nil || [self.commentActions count] == 0)
        return;
    
    // Get blog_id and comment_id for api call
    NSDictionary *commentAction = [[self.commentActions objectAtIndex:0] objectForKey:@"params"];
    NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
    NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
    
    if (!blogID || !commentID)
        return;
    
    UIButton *button = (UIButton *)sender;
    NSString *commentStatus = @"approved";
    if (button.tag == APPROVE_BUTTON_TAG) {
        if (self.canApprove)
            commentStatus = @"approved";
        else
            commentStatus = @"unapproved";
    } else if (button.tag == SPAM_BUTTON_TAG) {
        if (self.canSpam)
            commentStatus = @"spam";
        else
            commentStatus = @"unspam";
    } else if (button.tag == TRASH_BUTTON_TAG) {
        if (self.canTrash)
            commentStatus = @"trash";
        else
            commentStatus = @"untrash";
    }
    
    [button setEnabled:NO];
    
    [[WordPressComApi sharedApi] moderateComment:blogID forCommentID:commentID withStatus:commentStatus success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Update note to have new status
        NSDictionary *response = (NSDictionary *)responseObject;
        if (response) {
            NSArray *noteArray = [NSArray arrayWithObject:_note];
            [[WordPressComApi sharedApi] refreshNotifications:noteArray success:^(AFHTTPRequestOperation *operation, id refreshResponseObject) {
                [self displayNote];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self displayNote];
            }];
        }
        [button setEnabled:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [button setEnabled:YES];
    }];
    
    
    
}

- (IBAction)replyToComment {
    NSString *replyText = _replyTextView.text;
    
    if ([replyText length] > 0) {
        
        // Get blog_id and comment_id for api call
        NSDictionary *commentAction = [[_commentActions objectAtIndex:0] objectForKey:@"params"];
        NSUInteger blogID = [[commentAction objectForKey:@"blog_id"] intValue];
        NSUInteger commentID = [[commentAction objectForKey:@"comment_id"] intValue];
        
        [self.sendReplyButton setEnabled:NO];
        [[WordPressComApi sharedApi] replyToComment:blogID forCommentID:commentID withReply:replyText success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.sendReplyButton setEnabled:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.sendReplyButton setEnabled:YES];
        }];
    }
    
}

- (void)fetchComment:(NSNumber *)commentID {
    [self.commentThread insertObject:commentID atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    if ([self.commentThread count] > 1) {
        UIImage *image = [[UIImage imageNamed:@"note_comment_table_threaded"] resizableImageWithCapInsets:UIEdgeInsetsMake(200.f, 0.f, 200.f, 0.f)];
        UIImageView *tableBackgroundImage = [[UIImageView alloc] initWithImage:image];
        self.tableView.backgroundView = tableBackgroundImage;
    }
    NSString *commentPath = [NSString stringWithFormat:@"sites/%@/comments/%@", self.siteID, commentID];
    [self.user.restClient getPath:commentPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.comment = responseObject;
        
        
        NSUInteger index = [self.commentThread indexOfObject:commentID];
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        CGFloat initialHeight = [self tableView:self.tableView heightForRowAtIndexPath:path];
        [self.commentThread replaceObjectAtIndex:index withObject:responseObject];
        CGFloat newHeight = [self tableView:self.tableView heightForRowAtIndexPath:path];

        CGPoint offset = self.tableView.contentOffset;
        offset.y += newHeight - initialHeight;
        [self.tableView reloadData];
        if([self.commentThread count] > 1)
            [self.tableView setContentOffset:offset animated:NO];
        
        
        id parent = [responseObject objectForKey:@"parent"];
        if (![parent isEqual:@0] && [self.commentThread count] < 2) {
            [self fetchComment:[parent valueForKeyPath:@"ID"]];
        }

        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed");
    }];

}

#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.commentThread count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"NoteCommentCell";
    NoteCommentCell *cell = (NoteCommentCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil){
        cell = [[NoteCommentCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    NSLog(@"asking for index path: %@ total: %d", indexPath, [self.commentThread count]);
    id comment = [self.commentThread objectAtIndex:indexPath.row];
    if (indexPath.row == [self.commentThread count]-1) {
        // it's the main comment
        cell.imageView.hidden = NO;
        cell.avatarURL = [NSURL URLWithString:self.note.icon];
        cell.followButton = self.followButton;
        // we can also add the follow button
        NSLog(@"Set cell image view: %@", cell.imageView);
        if (![comment isKindOfClass:[NSDictionary class]]) {
            return cell;
        }
        
    } else {
        // it's a parent comment
        NSLog(@"Not the main comment");
        [cell displayAsParentComment];
        if (![comment isKindOfClass:[NSDictionary class]]) {
            cell.imageView.hidden = YES;
            NSLog(@"Showing loading on : %@", indexPath);
            [cell showLoadingIndicator];
            return cell;
        } else {
            cell.imageView.hidden = NO;
            cell.avatarURL = [NSURL URLWithString:[comment valueForKeyPath:@"author.avatar_URL"]];
        }
        
        // set the content
    }
    
    
    // otherwise let's set the contents here
    cell.textLabel.text = [comment valueForKeyPath:@"author.name"];
    cell.detailTextLabel.text = [comment valueForKeyPath:@"author.ID"];
    NSString *authorURL = [comment valueForKeyPath:@"author.URL"];
    cell.profileURL = [NSURL URLWithString:authorURL];
    NSAttributedString *content = [self convertHTMLToAttributedString:[comment valueForKeyPath:@"content"]];
    
    cell.textContentView.attributedString = content;
    
    return cell;
}

#pragma mark UITableViewDelegate

// the height of the comments
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id comment = [self.commentThread objectAtIndex:indexPath.row];
    if (indexPath.row == [self.commentThread count]-1) {
        // it's the main comment
        CGFloat minHeight = tableView.bounds.size.height;
        if (![comment isKindOfClass:[NSDictionary class]]) {
            // it's loading, so enough height for the footer to show
            return minHeight;
        } else {
            NSAttributedString *content = [self convertHTMLToAttributedString:[comment valueForKeyPath:@"content"]];
            CGFloat width = self.tableView.bounds.size.width;
            CGFloat heightWithText = [NoteCommentCell heightForCellWithTextContent:content
                                                                 constrainedToWidth:width];
            return MAX(heightWithText, minHeight);
        }
    } else {
        // it's a parent comment
        if (![comment isKindOfClass:[NSDictionary class]]) {
            // it's loading, we have no content for it
            return 44.f;
        } else {
            NSAttributedString *content = [self convertHTMLToAttributedString:[comment valueForKeyPath:@"content"]];
            return [NoteCommentCell heightForCellWithTextContent:content constrainedToWidth:self.tableView.bounds.size.width];
        }
    }
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

#pragma mark - NoteCommentCellDelegate

- (void)commentCell:(NoteCommentCell *)cell didTapURL:(NSURL *)url {
    [self pushToURL:url];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Text Formatting

- (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html {
    
    NSLog(@"Converting HTML: %@", html);
    NSDictionary *options = @{
    DTDefaultFontFamily : @"Helvetica",
    NSTextSizeMultiplierDocumentOption : [NSNumber numberWithFloat:1.3]
    };
    
    NSAttributedString *content = [[NSAttributedString alloc] initWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
    return content;
}

@end
