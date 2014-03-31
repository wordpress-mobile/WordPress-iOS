//
//  NotificationsLikesDetailViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 11/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsFollowDetailViewController.h"
#import "ContextManager.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressComApi.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"
#import "NSURL+Util.h"
#import "NotificationsFollowTableViewCell.h"
#import "WPWebViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WPAccount.h"
#import "WPToast.h"
#import "Note.h"

NSString *const WPNotificationFollowRestorationKey = @"WPNotificationFollowRestorationKey";
NSString *const WPNotificationHeaderCellIdentifier = @"WPNotificationHeaderCellIdentifier";
NSString *const WPNotificationFollowCellIdentifier = @"WPNotificationFollowCellIdentifier";
NSString *const WPNotificationFooterCellIdentifier = @"WPNotificationFooterCellIdentifier";

typedef NS_ENUM(NSInteger, WPNotificationSections) {
	WPNotificationSectionsFollow	= 0,
	WPNotificationSectionsFooter	= 1,
	WPNotificationSectionsCount		= 2
};

CGFloat const WPNotificationsFollowPersonCellHeight = 100.0f;
CGFloat const WPNotificationsFollowBottomCellHeight = 60.0f;


@interface NotificationsFollowDetailViewController () <UITableViewDelegate, UITableViewDataSource, UIViewControllerRestoration>

@property NSMutableArray *noteData;
@property BOOL hasFooter;
@property (nonatomic, strong) Note *note;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *postTitleView;
@property (nonatomic, weak) IBOutlet UIImageView *postBlavatar;
@property (nonatomic, weak) IBOutlet UILabel *postTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *postTitleButton;

@end

@implementation NotificationsFollowDetailViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *noteID = [coder decodeObjectForKey:WPNotificationFollowRestorationKey];
    if (!noteID) {
        return nil;
	}
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:noteID]];
    if (!objectID) {
        return nil;
	}
    
    NSError *error = nil;
    Note *restoredNote = (Note *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredNote) {
        return nil;
    }
    
    return [[self alloc] initWithNote:restoredNote];
}

- (instancetype)initWithNote:(Note *)note
{
	NSAssert([note isKindOfClass:[Note class]], @"Invalid Note!");

	self = [super init];
    if (self) {
        _note = note;
        self.title = _note.subject;
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_note) {
        _noteData = [[[_note noteData] objectForKey:@"body"] objectForKey:@"items"];
    }
    
    _postTitleView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _postTitleView.layer.borderWidth = 1.0 / [[UIScreen mainScreen] scale];
    
    NSString *headerText = [[[_note noteData] objectForKey:@"body"] objectForKey:@"header_text"];
    if (headerText) {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 40.0f)];
        [headerLabel setBackgroundColor:[WPStyleGuide itsEverywhereGrey]];
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        [headerLabel setTextColor:[WPStyleGuide whisperGrey]];
        [headerLabel setFont:[WPStyleGuide subtitleFont]];
        [headerLabel setText: [headerText stringByDecodingXMLCharacters]];
        [self.tableView setTableHeaderView:headerLabel];
        [self.view bringSubviewToFront:_postTitleView];
        
        NSString *headerLink = [[[_note noteData] objectForKey:@"body"] objectForKey:@"header_link"];
        if (headerLink && [headerLink isKindOfClass:[NSString class]]) {
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
            NSString *postTitle = [[quotedText objectAtIndex:[quotedText count] - 2] stringByDecodingXMLCharacters];
            [_postTitleLabel setText:postTitle];
        }
    }
    
    
    NSString *footerText = [[[_note noteData] objectForKey:@"body"] objectForKey:@"footer_text"];
    if (footerText && ![footerText isEqualToString:@""]) {
        _hasFooter = YES;
    }
    
    [_tableView setDelegate:self];
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if (selectedIndexPath) {
		[self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
	}
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
	NSString *noteURL = [[self.note.objectID URIRepresentation] absoluteString];
    [coder encodeObject:noteURL forKey:WPNotificationFollowRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Hide the footer section if needed
	if (_note.bodyFooterText.length == 0) {
		return WPNotificationSectionsCount - 1;
	}
	
	return WPNotificationSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
        return [_noteData count];
    else
        return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WPNotificationSectionsFollow) {
        return WPNotificationsFollowPersonCellHeight;
    } else {
        return WPNotificationsFollowBottomCellHeight;
	}
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
                    cell.detailTextLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];
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
            NSString *imageURL = [[selectedNote objectForKey:@"icon"] stringByReplacingOccurrencesOfString:@"s=256" withString:@"s=160"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
            [request setHTTPShouldHandleCookies:NO];
            [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
            
            UIImageView *gravatarImageView = cell.imageView;
            [cell.imageView setImageWithURLRequest:request
                                  placeholderImage:[UIImage imageNamed:@"gravatar"]
                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                               gravatarImageView.image = image;
                                           }
                                           failure:nil];
        }
        return cell;
    } else {
        static NSString *CellIdentifier = @"FooterCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.backgroundColor = [WPStyleGuide itsEverywhereGrey];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];
            cell.textLabel.font = [WPStyleGuide regularTextFont];
        }
        NSString *footerText = [[[_note noteData] objectForKey:@"body"] objectForKey:@"footer_text"];
        cell.textLabel.text = footerText;
        return cell;
    }
    
    return nil;
}

- (void)followBlog:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger row = button.tag;
    
    NSMutableDictionary *selectedNote = [_noteData objectAtIndex:row];
    NSMutableDictionary *noteAction = [selectedNote objectForKey:@"action"];
    NSMutableDictionary *noteDetails;
    if ([noteAction isKindOfClass:[NSDictionary class]])
        noteDetails = [noteAction objectForKey:@"params"];

    BOOL isFollowing = [[noteDetails objectForKey:@"is_following"] boolValue];
    
    if (isFollowing) {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailUnfollowBlog];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventNotificationsDetailFollowBlog];
    }
    
    NotificationsFollowTableViewCell *cell = (NotificationsFollowTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    [cell setFollowing: !isFollowing];

    
    NSUInteger blogID = [[noteDetails objectForKey:@"site_id"] intValue];
    if (blogID) {
        [[[WPAccount defaultWordPressComAccount] restApi] followBlog:blogID isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            } else {
                [cell setFollowing:isFollowing];
            }
            
            NSString *message = isFollowing ? NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") : NSLocalizedString(@"Followed", @"User followed a blog");
            NSString *imageName = [NSString stringWithFormat:@"action_icon_%@", (isFollowing) ? @"unfollowed" : @"followed"];
            [WPToast showToastWithMessage:message andImage:[UIImage imageNamed:imageName]];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [cell setFollowing: isFollowing];
            DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
        }];
    }   
}

- (IBAction)viewPostTitle:(id)sender
{
    [self loadWebViewWithURL:_note.bodyHeaderLink];

}

- (void)loadWebViewWithURL:(NSString*)url
{
    if (!url) {
        return;
	}
    
    NSURL *webViewURL = [NSURL URLWithString:url];
    if (webViewURL) {
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:webViewURL];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    
}

- (IBAction)highlightButton:(id)sender {
    [_postTitleButton setBackgroundColor:[UIColor UIColorFromHex:0xE3E3E3]];
}

- (IBAction)resetButton:(id)sender {
    [_postTitleButton setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WPNotificationSectionsFollow) {
		NoteBodyItem *item = self.filteredBodyItems[indexPath.row];
		NSURL *blogURL = item.action.blogURL;
        if (blogURL) {
            WPWebViewController *webViewController = [[WPWebViewController alloc] init];
            if ([blogURL isWordPressDotComUrl]) {
				WPAccount *account			= [WPAccount defaultWordPressComAccount];
				webViewController.username	= account.username;
				webViewController.password	= account.password;
				webViewController.url		= [blogURL ensureSecureURL];
            } else {
				webViewController.url = blogURL;
            }
            [self.navigationController pushViewController:webViewController animated:YES];
        } else {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    } else {
        [self loadWebViewWithURL:_note.bodyFooterLink];
    }
}

@end
