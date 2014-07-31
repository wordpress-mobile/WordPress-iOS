#import "NotificationsFollowDetailViewController.h"
#import "ContextManager.h"
#import "UIImageView+AFNetworking.h"
#import "WordPressComApi.h"
#import "NSString+XMLExtensions.h"
#import "NSString+Helpers.h"
#import "NSURL+Util.h"
#import "NotificationsFollowTableViewCell.h"
#import "WPTableHeaderViewCell.h"
#import "WPWebViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WPAccount.h"
#import "WPToast.h"
#import "Note.h"
#import "AccountService.h"
#import "NoteBodyItem.h"
#import "NoteAction.h"


NSString *const WPNotificationFollowRestorationKey = @"WPNotificationFollowRestorationKey";
NSString *const WPNotificationHeaderCellIdentifier = @"WPNotificationHeaderCellIdentifier";
NSString *const WPNotificationFollowCellIdentifier = @"WPNotificationFollowCellIdentifier";
NSString *const WPNotificationFooterCellIdentifier = @"WPNotificationFooterCellIdentifier";

typedef NS_ENUM(NSInteger, WPNotificationSections) {
	WPNotificationSectionsHeader	= 0,
	WPNotificationSectionsFollow	= 1,
	WPNotificationSectionsFooter	= 2,
	WPNotificationSectionsCount		= 3
};

CGFloat const WPNotificationsFollowPersonCellHeight = 80.0f;
CGFloat const WPNotificationsFollowBottomCellHeight = 60.0f;


@interface NotificationsFollowDetailViewController () <UITableViewDelegate, UITableViewDataSource, UIViewControllerRestoration>

@property (nonatomic, weak) IBOutlet UITableView	*tableView;
@property (nonatomic, strong) Note					*note;
@property (nonatomic, strong) NSArray				*filteredBodyItems;

typedef void (^NoteToggleFollowBlock)(BOOL success);
- (void)toggleFollowBlog:(NoteBodyItem *)item block:(NoteToggleFollowBlock)block;

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

		// Filter the first element in the body items: it's the same as the Subject Field!
		NSMutableArray *filtered = [_note.bodyItems mutableCopy];
		if (filtered.count) {
			NoteBodyItem *firstItem = filtered.firstObject;
			if (!firstItem.iconURL) {
				[filtered removeObjectAtIndex:0];
			}
		}
		self.filteredBodyItems = filtered;
						
		// Restoration Mechanism
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Details", @"NotificationFollow's ViewController Title");
	
	NSAssert(self.tableView, @"Null Outlet!");
	
	[self.tableView registerClass:[WPTableHeaderViewCell class] forCellReuseIdentifier:WPNotificationHeaderCellIdentifier];
	[self.tableView registerClass:[NotificationsFollowTableViewCell class] forCellReuseIdentifier:WPNotificationFollowCellIdentifier];
	[self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:WPNotificationFooterCellIdentifier];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.tableView setDelegate:self];

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
    if (section == WPNotificationSectionsFollow) {
        return self.filteredBodyItems.count;
    }

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WPNotificationSectionsHeader) {
		NSString *subject = [NSString decodeXMLCharactersIn:_note.subjectText];
		return [WPTableHeaderViewCell cellHeightForText:subject];
    } else if (indexPath.section == WPNotificationSectionsFollow) {
        return WPNotificationsFollowPersonCellHeight;
    }
    
    return WPNotificationsFollowBottomCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WPNotificationSectionsHeader) {

        UITableViewCell *cell			= [tableView dequeueReusableCellWithIdentifier:WPNotificationHeaderCellIdentifier];
        
        cell.textLabel.text				= [NSString decodeXMLCharactersIn:_note.subjectText];
        cell.textLabel.numberOfLines	= 0;
        cell.textLabel.textColor		= [UIColor blackColor];
		cell.textLabel.font				= [WPStyleGuide regularTextFont];
        cell.accessoryType				= UITableViewCellAccessoryDisclosureIndicator;

        // Note that we're using this cell as a section header. Since 'didPressCellAtIndex:' method isn't gonna get called,
        // let's use a GestureRecognizer!
        cell.gestureRecognizers			= @[ [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewPostTitle:)] ];
        
        return cell;
        
    } else if (indexPath.section == WPNotificationSectionsFollow) {
        
        NotificationsFollowTableViewCell *cell	= [tableView dequeueReusableCellWithIdentifier:WPNotificationFollowCellIdentifier];
        NoteBodyItem *noteItem					= self.filteredBodyItems[indexPath.row];
		__weak __typeof(self) weakSelf			= self;
		
        cell.textLabel.text			= @"";
        cell.detailTextLabel.text	= @"";
		cell.accessoryType			= UITableViewCellAccessoryNone;
		cell.onClick				= ^(NotificationsFollowTableViewCell* sender) {
			sender.following = !noteItem.action.following;
			[weakSelf toggleFollowBlog:noteItem block:^(BOOL success) {
				// On error: fallback to the previous state
				if (!success) {
					sender.following = noteItem.action.following;
				}
			}];
		};
		
		// Follow action: anyone?
		if ([noteItem.action.type isEqualToString:@"follow"]) {
			cell.actionButton.hidden	= NO;
			cell.following				= noteItem.action.following;
			
			if (noteItem.action.blogURL) {
				cell.detailTextLabel.text		= [noteItem.action.blogURL.host stringByReplacingOccurrencesOfString:@"http://" withString:@""];
				cell.detailTextLabel.textColor	= [WPStyleGuide newKidOnTheBlockBlue];
				cell.accessoryType				= UITableViewCellAccessoryDisclosureIndicator;
			}
		// No action available
		} else {
			cell.actionButton.hidden	= YES;
		}
        
        cell.textLabel.text       = noteItem.headerText;
        cell.detailTextLabel.text = [noteItem.headerLink stringByReplacingOccurrencesOfString:@"http://" withString:@""];;

		// Handle the Icon
		NSURL *iconURL = noteItem.iconURL;
        if (iconURL) {
			UIImage *placeholderImage		= [UIImage imageNamed:@"gravatar"];
			
            NSMutableURLRequest *request	= [NSMutableURLRequest requestWithURL:iconURL];
			request.HTTPShouldHandleCookies = NO;
            [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
            
            [cell.imageView setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
        }
		
        return cell;
    }

    UITableViewCell *cell			= [tableView dequeueReusableCellWithIdentifier:WPNotificationFooterCellIdentifier];

    cell.accessoryType				= UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor			= [WPStyleGuide itsEverywhereGrey];
    cell.textLabel.backgroundColor	= [UIColor clearColor];
    cell.textLabel.textColor		= [WPStyleGuide newKidOnTheBlockBlue];
    cell.textLabel.font				= [WPStyleGuide regularTextFont];
    cell.textLabel.text				= _note.bodyFooterText;
    
    return cell;
}

- (void)toggleFollowBlog:(NoteBodyItem *)item block:(NoteToggleFollowBlock)block
{
	NSNumber *blogID = item.action.siteID;
    if (!blogID) {
		return;
	}
	
    BOOL isFollowing = item.action.following;
	   
    [WPAnalytics track:WPAnalyticsStatNotificationPerformedAction];
    
	// Hit the Backend
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

	WordPressComApi *restApi = [defaultAccount restApi];
    
    // Instant-gratification toast message
    NSString *message	= isFollowing ? NSLocalizedString(@"Unfollowed", @"User unfollowed a blog") : NSLocalizedString(@"Followed", @"User followed a blog");
    NSString *imageName = [NSString stringWithFormat:@"action_icon_%@", (isFollowing) ? @"unfollowed" : @"followed"];
    [WPToast showToastWithMessage:message andImage:[UIImage imageNamed:imageName]];

	[restApi followBlog:blogID.integerValue isFollowing:isFollowing success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		NSDictionary *followResponse = (NSDictionary *)responseObject;
		BOOL success = ([followResponse[@"success"] intValue] == 1);
		if (success) {
            // Simperium will eventually update the Notification Object, thus, making this change permanent
			BOOL isFollowingNow = ([followResponse[@"is_following"] intValue] == 1);
			item.action.following = isFollowingNow;
		}
		
		block(success);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        item.action.following = !isFollowing;
		DDLogVerbose(@"[Rest API] ! %@", [error localizedDescription]);
		block(false);
	}];
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
    
	WPWebViewController *webViewController = [[WPWebViewController alloc] init];
	webViewController.url = [NSURL URLWithString:url];
	[self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WPNotificationSectionsFollow) {
		NoteBodyItem *item = self.filteredBodyItems[indexPath.row];
        NSURL *blogURL =  [[NSURL alloc]initWithString:item.headerLink];
        if (blogURL) {
            WPWebViewController *webViewController = [[WPWebViewController alloc] init];
            if ([blogURL isWordPressDotComUrl]) {
                NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

                [webViewController setUsername:[defaultAccount username]];
                [webViewController setPassword:[defaultAccount password]];
                [webViewController setUrl:[blogURL ensureSecureURL]];
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
