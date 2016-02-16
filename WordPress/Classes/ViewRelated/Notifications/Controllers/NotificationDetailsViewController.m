#import "NotificationDetailsViewController.h"

#import "WordPressAppDelegate.h"
#import <Simperium/Simperium.h>

#import "Blog.h"
#import "Notification.h"
#import <SVProgressHUD/SVProgressHUD.h>

#import "ContextManager.h"

#import "BlogService.h"
#import "CommentService.h"
#import "ReaderSiteService.h"

#import "WPWebViewController.h"
#import "WPImageViewController.h"

#import "ReaderCommentsViewController.h"
#import "StatsViewController.h"
#import "StatsViewAllTableViewController.h"
#import "EditCommentViewController.h"
#import "EditReplyViewController.h"

#import "SuggestionsTableView.h"
#import "SuggestionService.h"

#import "AppRatingUtility.h"

#import "WordPress-Swift.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"
#import "NSObject+Helpers.h"
#import "NSDate+StringFormatting.h"
#import "NSString+Helpers.h"

#import "WPAppAnalytics.h"



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static UIEdgeInsets NotificationTableInsetsPhone        = {0.0f,  0.0f, 20.0f, 0.0f};
static UIEdgeInsets NotificationTableInsetsPad          = {40.0f, 0.0f, 20.0f, 0.0f};

static NSTimeInterval NotificationFiveMinutes           = 60 * 5;
static NSInteger NotificationSectionCount               = 1;

static NSString *NotificationsSiteIdKey                 = @"NotificationsSiteIdKey";
static NSString *NotificationsPostIdKey                 = @"NotificationsPostIdKey";
static NSString *NotificationsCommentIdKey              = @"NotificationsCommentIdKey";


#pragma mark ==========================================================================================
#pragma mark Private
#pragma mark ==========================================================================================

@interface NotificationDetailsViewController () <ReplyTextViewDelegate, SuggestionsTableViewDelegate>

// Outlets
@property (nonatomic,   weak) IBOutlet UITableView          *tableView;
@property (nonatomic,   weak) IBOutlet UIGestureRecognizer  *tableGesturesRecognizer;
@property (nonatomic, strong) ReplyTextView                 *replyTextView;
@property (nonatomic, strong) SuggestionsTableView          *suggestionsTableView;

// Table Helpers
@property (nonatomic, strong) NSDictionary                  *layoutCellMap;
@property (nonatomic, strong) NSDictionary                  *reuseIdentifierMap;
@property (nonatomic, strong) NSArray                       *blockGroups;

// Media Helpers
@property (nonatomic, strong) NotificationMediaDownloader   *mediaDownloader;

// Model
@property (nonatomic, strong) Notification                  *note;
@end


#pragma mark ==========================================================================================
#pragma mark NotificationDetailsViewController
#pragma mark ==========================================================================================

@implementation NotificationDetailsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Failsafe: Manually nuke the tableView dataSource and delegate. Make sure not to force a loadView event!
    if (!self.isViewLoaded) {
        return;
    }
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.restorationClass = [self class];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupNavigationBar];
    [self setupMainView];
    [self setupTableView];
    [self setupMediaDownloader];
    [self setupNotificationListeners];
    
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.tableView deselectSelectedRowWithAnimation:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.replyTextView resignFirstResponder];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self adjustTableInsetsIfNeeded];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self.tableView reloadData];
}

- (void)reloadData
{
    // Hide the header, if needed
    NSMutableArray *blockGroups = [NSMutableArray array];
    
    if (_note.headerBlockGroup) {
        [blockGroups addObject:_note.headerBlockGroup];
    }
    
    if (_note.bodyBlockGroups) {
        [blockGroups addObjectsFromArray:_note.bodyBlockGroups];
    }
    
    self.blockGroups = blockGroups;
    
    // Reload UI
    self.title = self.note.title;
    [self.tableView reloadData];
    [self adjustTableInsetsIfNeeded];
}


#pragma mark - Public Helpers

- (void)setupWithNotification:(Notification *)notification
{
    self.note = notification;
    [self attachReplyViewIfNeeded];
    [self attachEditActionIfNeeded];
    [self reloadData];
}


#pragma mark - Setup Helpers

- (void)setupNavigationBar
{
    // Don't show the notification title in the next-view's back button
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString string]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (void)setupMainView
{
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
}

- (void)setupTableView
{
    // Register Cell Nibs
    NSArray *cellClassNames = @[
        NSStringFromClass([NoteBlockHeaderTableViewCell class]),
        NSStringFromClass([NoteBlockTextTableViewCell class]),
        NSStringFromClass([NoteBlockActionsTableViewCell class]),
        NSStringFromClass([NoteBlockCommentTableViewCell class]),
        NSStringFromClass([NoteBlockImageTableViewCell class]),
        NSStringFromClass([NoteBlockUserTableViewCell class])
    ];
    
    for (NSString *cellClassName in cellClassNames) {
        Class cellClass                     = NSClassFromString(cellClassName);
        NSString *className                 = [cellClass classNameWithoutNamespaces];
        UINib *tableViewCellNib             = [UINib nibWithNibName:className bundle:[NSBundle mainBundle]];
        
        [self.tableView registerNib:tableViewCellNib forCellReuseIdentifier:[cellClass reuseIdentifier]];
        [self.tableView registerNib:tableViewCellNib forCellReuseIdentifier:[cellClass layoutIdentifier]];
    }
    
    // TableView
    self.tableView.separatorStyle           = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor          = [WPStyleGuide greyLighten30];
    self.tableView.accessibilityIdentifier  = @"Notification Details Table";
    self.tableView.backgroundColor          = [WPStyleGuide itsEverywhereGrey];
    self.tableView.keyboardDismissMode      = UIScrollViewKeyboardDismissModeInteractive;
}

- (void)setupMediaDownloader
{
    self.mediaDownloader = [NotificationMediaDownloader new];
}

- (void)setupNotificationListeners
{
    NSManagedObjectContext *context = self.note.managedObjectContext;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotificationChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];
}


#pragma mark - Autolayout Helpers

- (NSDictionary *)layoutCellMap
{
    if (_layoutCellMap) {
        return _layoutCellMap;
    }
    
    UITableView *tableView  = self.tableView;
    _layoutCellMap = @{
        @(NoteBlockGroupTypeHeader)    : [tableView dequeueReusableCellWithIdentifier:NoteBlockHeaderTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeFooter)    : [tableView dequeueReusableCellWithIdentifier:NoteBlockTextTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeText)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockTextTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeComment)   : [tableView dequeueReusableCellWithIdentifier:NoteBlockCommentTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeActions)   : [tableView dequeueReusableCellWithIdentifier:NoteBlockActionsTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeImage)     : [tableView dequeueReusableCellWithIdentifier:NoteBlockImageTableViewCell.layoutIdentifier],
        @(NoteBlockGroupTypeUser)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockUserTableViewCell.layoutIdentifier]
    };
    
    return _layoutCellMap;
}

- (NSDictionary *)reuseIdentifierMap
{
    return @{
        @(NoteBlockGroupTypeHeader)     : NoteBlockHeaderTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeFooter)     : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeText)       : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeComment)    : NoteBlockCommentTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeActions)    : NoteBlockActionsTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeImage)      : NoteBlockImageTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeUser)       : NoteBlockUserTableViewCell.reuseIdentifier
    };
}


#pragma mark - Reply View Helpers

- (void)attachReplyViewIfNeeded
{
    // iPad: We've got a different UI!
    if ([UIDevice isPad]) {
        return;
    }
    
    // Attach the Reply component only if the noficiation has a comment, and it can be replied-to
    NotificationBlockGroup *group   = [self.note blockGroupOfType:NoteBlockGroupTypeComment];
    NotificationBlock *block        = [group blockOfType:NoteBlockTypeComment];
    
    if (![block isActionOn:NoteActionReplyKey]) {
        return;
    }
    
    __typeof(self) __weak weakSelf          = self;
    
    ReplyTextView *replyTextView            = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.placeholder               = NSLocalizedString(@"Write a reply…", @"Placeholder text for inline compose view");
    replyTextView.replyText                 = [NSLocalizedString(@"Reply", @"") uppercaseString];
    replyTextView.accessibilityIdentifier   = @"Reply Text";
    replyTextView.onReply                   = ^(NSString *content) {
        [weakSelf sendReplyWithBlock:block content:content];
    };
    replyTextView.delegate                  = self;
    self.replyTextView                      = replyTextView;

    // Attach the ReplyTextView at the very bottom
    [self.view addSubview:self.replyTextView];
    [self.view pinSubviewAtBottom:self.replyTextView];
    [self.view pinSubview:self.tableView aboveSubview:self.replyTextView];

    // Attach suggestionsView
    [self attachSuggestionsViewIfNeeded];
}


#pragma mark - Suggestions View Helpers

- (void)attachSuggestionsViewIfNeeded
{
    if (![[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.note.metaSiteID]) {
        return;
    }
    
    self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:self.note.metaSiteID];
    self.suggestionsTableView.suggestionsDelegate = self;
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
    
    // Pin the suggestions view left and right edges to the super view edges
    NSDictionary *views = @{@"suggestionsview": self.suggestionsTableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[suggestionsview]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    // Pin the suggestions view top to the super view top
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[suggestionsview]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    // Pin the suggestions view bottom to the top of the reply box
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestionsTableView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.replyTextView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:0]];
}


#pragma mark - Edition Helpers

- (void)attachEditActionIfNeeded
{
    NotificationBlockGroup *group   = [self.note blockGroupOfType:NoteBlockGroupTypeComment];
    NotificationBlock *block        = [group blockOfType:NoteBlockTypeComment];
    
    UIBarButtonItem *editBarButton  = nil;
    
    if ([block isActionOn:NoteActionEditKey]) {
        editBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Verb, start editing")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(editButtonWasPressed)];
    }
    
    self.navigationItem.rightBarButtonItem = editBarButton;
}

- (IBAction)editButtonWasPressed
{
    NotificationBlockGroup *group   = [self.note blockGroupOfType:NoteBlockGroupTypeComment];
    NotificationBlock *block        = [group blockOfType:NoteBlockTypeComment];
    
    if ([block isActionOn:NoteActionEditKey]) {
        [self editCommentWithBlock:block];
    }
}


#pragma mark - Style Helpers

- (void)adjustTableInsetsIfNeeded
{
    UIEdgeInsets contentInset = [UIDevice isPad] ? NotificationTableInsetsPad : NotificationTableInsetsPhone;
    
    // Badge Notifications should be centered, and display no cell separators
    if (self.note.isBadge) {
        // Center only if the container view is big enough!
        if (self.view.frame.size.height > self.tableView.contentSize.height) {
            CGFloat offsetY = (self.view.frame.size.height - self.tableView.contentSize.height) * 0.5f;
            contentInset    = UIEdgeInsetsMake(offsetY, 0, 0, 0);
        }
    }
    
    self.tableView.contentInset = contentInset;
}


#pragma mark - UIViewController Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSString *noteID = [coder decodeObjectForKey:NSStringFromClass([Notification class])];
    if (!noteID) {
        return nil;
    }
    
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:noteID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    Notification *restoredNotification = (Notification *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredNotification) {
        return nil;
    }
    
    UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
    if (!storyboard) {
        return nil;
    }
    
    NotificationDetailsViewController *vc   = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.restorationIdentifier                = [identifierComponents lastObject];
    vc.restorationClass                     = [NotificationDetailsViewController class];
    
    [vc setupWithNotification:restoredNotification];
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *noteIdKey = NSStringFromClass([Notification class]);
    [coder encodeObject:[self.note.objectID.URIRepresentation absoluteString] forKey:noteIdKey];
    [super encodeRestorableStateWithCoder:coder];
}


#pragma mark - Helpers

- (NotificationBlockGroup *)blockGroupForIndexPath:(NSIndexPath *)indexPath
{
    return self.blockGroups[indexPath.row];
}


#pragma mark - UITableViewDelegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    /**
        Note
        This is a workaround. iOS 7 + grouped cells result in an extra top spacing.
        Ref.: http://stackoverflow.com/questions/17699831/how-to-change-height-of-grouped-uitableview-header
     */

    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Make sure no SectionFooter is rendered
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Make sure no SectionHeader is rendered
    return nil;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Make sure no SectionFooter is rendered
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NotificationSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.blockGroups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NoteBlockTableViewCell *tableViewCell   = self.layoutCellMap[@(blockGroup.type)] ?: self.layoutCellMap[@(NoteBlockGroupTypeText)];

    [self downloadAndResizeMedia:indexPath blockGroup:blockGroup];
    [self setupCell:tableViewCell blockGroup:blockGroup];
    
    CGFloat height = [tableViewCell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];

    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NSString *reuseIdentifier               = self.reuseIdentifierMap[@(blockGroup.type)] ?: self.reuseIdentifierMap[@(NoteBlockGroupTypeText)];
    NoteBlockTableViewCell *cell            = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
 
    [self setupSeparators:cell indexPath:indexPath];
    [self setupCell:cell blockGroup:blockGroup];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *group = [self blockGroupForIndexPath:indexPath];

    // User Blocks: Push the associated blog, if any
    if (group.type == NoteBlockGroupTypeUser) {
        
        NotificationBlock *block    = [group blockOfType:NoteBlockTypeUser];
        NSURL *siteURL              = [NSURL URLWithString:block.metaLinksHome];
        [self openURL:siteURL];
        
    // Header-Level: Push the resource associated with the note
    } else if (group.type == NoteBlockGroupTypeHeader) {
        
        [self openNotificationHeader:group];

    // Footer-Level:
    } else if (group.type == NoteBlockGroupTypeFooter) {
        
        // Note:
        // By convention, the last range is the one that always contains the targetURL.
        //
        NotificationBlock *block    = [group blockOfType:NoteBlockTypeText];
        NotificationRange *range    = block.ranges.lastObject;
        
        [self openURL:range.url];
    }
}


#pragma mark - Media Download Helper

- (void)downloadAndResizeMedia:(NSIndexPath *)indexPath blockGroup:(NotificationBlockGroup *)blockGroup
{
    //  Notes:
    //  -   We'll *only* download Media for Text and Comment Blocks
    //  -   Plus, we'll also resize the downloaded media cache *if needed*. This is meant to adjust images to
    //      better fit onscreen, whenever the device orientation changes (and in turn, the maxMediaEmbedWidth changes too).
    //
    NSSet *richBlockTypes           = [NSSet setWithObjects:@(NoteBlockTypeText), @(NoteBlockTypeComment), nil];
    NSSet *imageUrls                = [blockGroup imageUrlsForBlocksOfTypes:richBlockTypes];
    __weak __typeof(self) weakSelf  = self;
    
    void (^completion)(void)        = ^{
        
        // Workaround:
        // Performing the reload call, multiple times, without the UIViewAnimationOptionBeginFromCurrentState might lead
        // to a state in which the cell remains not visible.
        //
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionBeginFromCurrentState animations:^{
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } completion:nil];
    };

    [self.mediaDownloader downloadMediaWithUrls:imageUrls maximumWidth:self.maxMediaEmbedWidth completion:completion];
    [self.mediaDownloader resizeMediaWithIncorrectSize:self.maxMediaEmbedWidth completion:completion];
}

- (CGFloat)maxMediaEmbedWidth
{
    UIEdgeInsets textPadding        = NoteBlockTextTableViewCell.defaultLabelPadding;
    CGFloat portraitWidth           = [UIDevice isPad] ? WPTableViewFixedWidth : CGRectGetWidth(self.view.bounds);
    CGFloat maxWidth                = portraitWidth - (textPadding.left + textPadding.right);
    
    return maxWidth;
}


#pragma mark - NoteBlockTableViewCell Helpers

- (void)setupCell:(NoteBlockTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    // Note: This is gonna look awesome in Swift
    if (blockGroup.type == NoteBlockGroupTypeHeader) {
        [self setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell blockGroup:blockGroup];

    } else if (blockGroup.type == NoteBlockGroupTypeFooter) {
        [self setupFooterCell:(NoteBlockTextTableViewCell *)cell blockGroup:blockGroup];
            
    } else if (blockGroup.type == NoteBlockGroupTypeUser) {
        [self setupUserCell:(NoteBlockUserTableViewCell *)cell blockGroup:blockGroup];
        
    } else if (blockGroup.type == NoteBlockGroupTypeComment){
        [self setupCommentCell:(NoteBlockCommentTableViewCell *)cell blockGroup:blockGroup];

    } else if (blockGroup.type == NoteBlockGroupTypeActions){
        [self setupActionsCell:(NoteBlockActionsTableViewCell *)cell blockGroup:blockGroup];
        
    } else if (blockGroup.type == NoteBlockGroupTypeImage) {
        [self setupImageCell:(NoteBlockImageTableViewCell *)cell blockGroup:blockGroup];
        
    } else {
        [self setupTextCell:(NoteBlockTextTableViewCell *)cell blockGroup:blockGroup];
    }
}

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
/**
    Note:
    We're using a UITableViewCell as a Header, instead of UITableViewHeaderFooterView, because:
    -   UITableViewCell automatically handles highlight / unhighlight for us
    -   UITableViewCell's taps don't require a Gestures Recognizer. No big deal, but less code!
 */
    
    NotificationBlock *gravatarBlock    = [blockGroup blockOfType:NoteBlockTypeImage];
    NotificationBlock *snippetBlock     = [blockGroup blockOfType:NoteBlockTypeText];
    
    cell.attributedHeaderTitle          = gravatarBlock.attributedHeaderTitleText;
    cell.headerDetails                  = snippetBlock.text;
    
    // Download the Gravatar (If Needed!)
    if (cell.isLayoutCell) {
        return;
    }

    NotificationMedia *media            = gravatarBlock.media.firstObject;
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupFooterCell:(NoteBlockTextTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *textBlock    = blockGroup.blocks.firstObject;
    NSAssert(textBlock, @"Missing Text Block for Notification %@", self.note.simperiumKey);
    
    // Setup the Cell
    cell.attributedText             = textBlock.attributedFooterText;
    cell.isTextViewSelectable       = false;
    cell.isTextViewClickable        = false;
}

- (void)setupUserCell:(NoteBlockUserTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *userBlock    = blockGroup.blocks.firstObject;
    NSAssert(userBlock, @"Missing User Block for Notification %@", self.note.simperiumKey);
    
    BOOL hasHomeURL                 = (userBlock.metaLinksHome != nil);
    BOOL hasHomeTitle               = (userBlock.metaTitlesHome.length > 0);
    
    // Setup the Cell
    cell.accessoryType              = hasHomeURL ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.name                       = userBlock.text;
    cell.blogTitle                  = hasHomeTitle ? userBlock.metaTitlesHome : userBlock.metaLinksHome.hostname;
    cell.isFollowEnabled            = [userBlock isActionEnabled:NoteActionFollowKey];
    cell.isFollowOn                 = [userBlock isActionOn:NoteActionFollowKey];
    
    // Setup the Callbacks
    __weak __typeof(self) weakSelf  = self;
    cell.onFollowClick              = ^() {
        [weakSelf followSiteWithBlock:userBlock];
    };
    cell.onUnfollowClick            = ^() {
        [weakSelf unfollowSiteWithBlock:userBlock];
    };

    // Download the Gravatar (If Needed!)
    if (cell.isLayoutCell) {
        return;
    }

    NotificationMedia *media        = [userBlock.media firstObject];
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
/**
    Note:
    The main reason why it's a very good idea *not* to reuse NoteBlockHeaderTableViewCell, just to display the
    gravatar, is because we're implementing a custom behavior whenever the user approves/ disapproves the comment.
    
    -   Font colors are updated.
    -   A left separator is displayed.
 */
    
    NotificationBlock *commentBlock = [blockGroup blockOfType:NoteBlockTypeComment];
    NotificationBlock *userBlock    = [blockGroup blockOfType:NoteBlockTypeUser];
    NSAssert(commentBlock, @"Missing Comment Block for Notification %@", self.note.simperiumKey);
    NSAssert(userBlock,    @"Missing User Block for Notification %@",    self.note.simperiumKey);
    
    // Merge the Attachments with their ranges: [NSRange: UIImage]
    NSDictionary *mediaMap          = [self.mediaDownloader imagesForUrls:commentBlock.imageUrls];
    NSDictionary *mediaRanges       = [commentBlock buildRangesToImagesMap:mediaMap];
    NSAttributedString *text        = [commentBlock.attributedRichText stringByEmbeddingImageAttachments:mediaRanges];
    
    // Setup the cell
    cell.name                       = userBlock.text;
    cell.timestamp                  = [self.note.timestampAsDate shortString];
    cell.site                       = userBlock.metaTitlesHome ?: userBlock.metaLinksHome.hostname;
    cell.attributedCommentText      = [text trimTrailingNewlines];
    cell.isApproved                 = [commentBlock isCommentApproved];
    cell.hasReply                   = self.note.hasReply;
    
    // Setup the Callbacks
    __weak __typeof(self) weakSelf  = self;
    
    cell.onDetailsClick             = ^(UIButton * sender) {
        NSURL *url = [NSURL URLWithString:userBlock.metaLinksHome];
        if (url) {
            [weakSelf openURL:url];
        }
    };
    
    cell.onUrlClick                 = ^(NSURL *url) {
        [weakSelf openURL:url];
    };

    cell.onAttachmentClick          = ^(NSTextAttachment *attachment) {
        [weakSelf displayFullscreenImage:attachment.image];
    };
    
    // Download the Gravatar (If Needed!)
    if (cell.isLayoutCell) {
        return;
    }
    
    NotificationMedia *media        = userBlock.media.firstObject;
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupActionsCell:(NoteBlockActionsTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *commentBlock = [blockGroup blockOfType:NoteBlockTypeComment];
    NSAssert(commentBlock, @"Missing Comment Block for Notification %@", self.note.simperiumKey);
    
    // Setup the cell
    cell.isReplyEnabled             = [UIDevice isPad] && [commentBlock isActionOn:NoteActionReplyKey];
    cell.isLikeEnabled              = [commentBlock isActionEnabled:NoteActionLikeKey];
    cell.isApproveEnabled           = [commentBlock isActionEnabled:NoteActionApproveKey];
    cell.isTrashEnabled             = [commentBlock isActionEnabled:NoteActionTrashKey];
    cell.isSpamEnabled              = [commentBlock isActionEnabled:NoteActionSpamKey];

    cell.isLikeOn                   = [commentBlock isActionOn:NoteActionLikeKey];
    cell.isApproveOn                = [commentBlock isActionOn:NoteActionApproveKey];
    
    // Setup the Callbacks
    __weak __typeof(self) weakSelf  = self;
    
    cell.onReplyClick               = ^(UIButton * sender){
        [weakSelf editReplyWithBlock:commentBlock];
    };

    cell.onLikeClick                = ^(UIButton * sender){
        [weakSelf likeCommentWithBlock:commentBlock];
    };

    cell.onUnlikeClick              = ^(UIButton * sender){
        [weakSelf unlikeCommentWithBlock:commentBlock];
    };

    cell.onApproveClick             = ^(UIButton * sender){
        [weakSelf approveCommentWithBlock:commentBlock];
    };

    cell.onUnapproveClick           = ^(UIButton * sender){
        [weakSelf unapproveCommentWithBlock:commentBlock];
    };

    cell.onTrashClick               = ^(UIButton * sender){
        [weakSelf trashCommentWithBlock:commentBlock];
    };

    cell.onSpamClick                = ^(UIButton * sender){
        [weakSelf spamCommentWithBlock:commentBlock];
    };
}

- (void)setupImageCell:(NoteBlockImageTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    // Download the Image (If Needed!)
    if (cell.isLayoutCell) {
        return;
    }
    
    NotificationBlock *imageBlock   = blockGroup.blocks.firstObject;
    NSAssert(imageBlock, @"Missing Image Block for Notification %@", self.note.simperiumKey);
    
    NotificationMedia *media        = imageBlock.media.firstObject;
    [cell downloadImageWithURL:media.mediaURL];
}

- (void)setupTextCell:(NoteBlockTextTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *textBlock    = blockGroup.blocks.firstObject;
    NSAssert(textBlock, @"Missing Text Block for Notification %@", self.note.simperiumKey);
    
    // Merge the Attachments with their ranges: [NSRange: UIImage]
    NSDictionary *mediaMap          = [self.mediaDownloader imagesForUrls:textBlock.imageUrls];
    NSDictionary *mediaRanges       = [textBlock buildRangesToImagesMap:mediaMap];
    
    // Load the attributedText
    NSAttributedString *text        = self.note.isBadge ? textBlock.attributedBadgeText : textBlock.attributedRichText;
    
    // Setup the Cell
    cell.attributedText             = [text stringByEmbeddingImageAttachments:mediaRanges];
    
    // Setup the Callbacks
    __weak __typeof(self) weakSelf  = self;
    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
}


#pragma mark - Setup properties required by Cell Separator Logic

- (void)setupSeparators:(NoteBlockTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.isBadge                    = self.note.isBadge;
    cell.isLastRow                  = (indexPath.row >= self.blockGroups.count - 1);
}


#pragma mark - Associated Resources

- (void)openURL:(NSURL *)url
{
    //  NOTE:
    //  In this step, we attempt to match the URL tapped with any NotificationRange instance, contained in the note,
    //  and thus, recover the metadata!
    //
    NotificationRange *range    = [self.note notificationRangeWithUrl:url];
    BOOL success                = false;
    
    if (range.isPost) {
        success = [self displayReaderWithPostId:range.postID siteID:range.siteID];
    }
    
    if (range.isComment) {
        success = [self displayCommentsWithPostId:range.postID siteID:range.siteID];
    }
    
    if (!success && range.isStats) {
        success = [self displayStatsWithSiteID:range.siteID];
    }
    
    if (!success && range.isFollow) {
        success = [self displayFollowersWithSiteID:self.note.metaSiteID];
    }

    if (!success && range.isUser) {
        success = [self displayBrowseSite:range.siteID siteURL:range.url];
    }
    
    if (!success && url) {
        success = [self displayWebViewWithURL:url];
    }
    
    if (!success) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}

- (void)openNotificationHeader:(NotificationBlockGroup *)header
{
    NSParameterAssert(header);
    NSParameterAssert(header.type == NoteBlockGroupTypeHeader);
    
    BOOL success = false;
    
    if (!success && self.note.isFollow) {
        NSURL *resourceURL = [NSURL URLWithString:self.note.url];
        success = [self displayBrowseSite:self.note.metaSiteID siteURL:resourceURL];
    }
    
    if (!success && self.note.metaCommentID) {
        success = [self displayCommentsWithPostId:self.note.metaPostID siteID:self.note.metaSiteID];
    }
    
    if (!success) {
        success = [self displayReaderWithPostId:self.note.metaPostID siteID:self.note.metaSiteID];
    }
    
    if (!success) {
        NSURL *resourceURL = [NSURL URLWithString:self.note.url];
        success = [self displayWebViewWithURL:resourceURL];
    }
    
    if (!success) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}


#pragma mark - Helpers

- (BOOL)displayReaderWithPostId:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    BOOL success = postID && siteID;
    if (success) {
        NSDictionary *parameters = @{
            NotificationsSiteIdKey      : siteID,
            NotificationsPostIdKey      : postID
        };
        
        [self performSegueWithIdentifier:[ReaderDetailViewController classNameWithoutNamespaces] sender:parameters];
    }
    return success;
}

- (BOOL)displayCommentsWithPostId:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    BOOL success = postID && siteID;
    if (success) {
        NSDictionary *parameters = @{
            NotificationsSiteIdKey      : siteID,
            NotificationsPostIdKey      : postID,
        };
        
        [self performSegueWithIdentifier:NSStringFromClass([ReaderCommentsViewController class]) sender:parameters];
    }
    return success;
}

- (BOOL)displayStatsWithSiteID:(NSNumber *)siteID
{
    if (!siteID) {
        return false;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:siteID];
    BOOL success                    = [blog supports:BlogFeatureStats];

    if (success) {
        // TODO: Update StatsViewController to work with initWithCoder!
        StatsViewController *vc     = [[StatsViewController alloc] init];
        vc.blog = blog;
        [self.navigationController pushViewController:vc animated:YES];
    }
    return success;
}

- (BOOL)displayFollowersWithSiteID:(NSNumber *)siteID
{
    if (!siteID) {
        return false;
    }
    
    // Load the blog
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service            = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog                      = [service blogByBlogId:siteID];

    if (!blog || !blog.isHostedAtWPcom) {
        return NO;
    }

    // Push the Stats ViewController
    NSString *identifier            = NSStringFromClass([StatsViewAllTableViewController class]);
    
    NSBundle *statsBundle = [NSBundle bundleForClass:[WPStatsViewController class]];
    NSString *path = [statsBundle pathForResource:@"WordPressCom-Stats-iOS" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    UIStoryboard *statsStoryboard   = [UIStoryboard storyboardWithName:@"SiteStats" bundle:bundle];
    StatsViewAllTableViewController *vc = [statsStoryboard instantiateViewControllerWithIdentifier:identifier];
    NSAssert(vc, @"Couldn't instantiate StatsViewAllTableViewController");
    
    vc.selectedDate                = [NSDate date];
    vc.statsSection                = StatsSectionFollowers;
    vc.statsSubSection             = StatsSubSectionFollowersDotCom;
    vc.statsService                = [[WPStatsService alloc] initWithSiteId:blog.dotComID
                                                               siteTimeZone:[service timeZoneForBlog:blog]
                                                                oauth2Token:blog.authToken
                                                 andCacheExpirationInterval:NotificationFiveMinutes];
    
    [self.navigationController pushViewController:vc animated:YES];
    
    return YES;
}

- (BOOL)displayWebViewWithURL:(NSURL *)url
{
    BOOL success = [url isKindOfClass:[NSURL class]];
    if (!success) {
        return NO;
    }
    
    WPWebViewController *webViewController  = [WPWebViewController authenticatedWebViewController:url];
    UINavigationController *navController   = [[UINavigationController alloc] initWithRootViewController:webViewController];
    
    [self presentViewController:navController animated:YES completion:nil];
    
    return success;
}

- (BOOL)displayBrowseSite:(NSNumber *)siteID siteURL:(NSURL *)siteURL
{
    if (![siteID isKindOfClass:[NSNumber class]]) {
        return NO;
    }

    ReaderStreamViewController *browseViewController = [ReaderStreamViewController controllerWithSiteID:siteID isFeed:NO];
    [self.navigationController pushViewController:browseViewController animated:YES];
    
    return YES;
}

- (BOOL)displayFullscreenImage:(UIImage *)image
{
    if (!image) {
        return NO;
    }
    
    WPImageViewController *imageViewController = [[WPImageViewController alloc] initWithImage:image];
    imageViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    imageViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:imageViewController animated:YES completion:nil];
    
    return YES;
}


#pragma mark - Action Handlers

- (void)followSiteWithBlock:(NotificationBlock *)block
{
    
    [WPAppAnalytics track:WPAnalyticsStatNotificationsSiteFollowAction withBlogID:block.metaSiteID];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderSiteService *service      = [[ReaderSiteService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service followSiteWithID:block.metaSiteID.integerValue success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionFollowKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionFollowKey];
}

- (void)unfollowSiteWithBlock:(NotificationBlock *)block
{
    [WPAppAnalytics track:WPAnalyticsStatNotificationsSiteUnfollowAction withBlogID:block.metaSiteID];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderSiteService *service      = [[ReaderSiteService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unfollowSiteWithID:block.metaSiteID.integerValue success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionFollowKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionFollowKey];
}

- (void)likeCommentWithBlock:(NotificationBlock *)block
{

    [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentLiked withBlogID:block.metaSiteID];
    
    // If the associated comment is *not* approved, let's attempt to auto-approve it, automatically
    if (!block.isCommentApproved) {
        [self approveCommentWithBlock:block];
    }

    // Proceed toggling the Like field
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service likeCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionLikeKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionLikeKey];
}

- (void)unlikeCommentWithBlock:(NotificationBlock *)block
{
    [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentUnliked withBlogID:block.metaSiteID];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unlikeCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionLikeKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionLikeKey];
}

- (void)approveCommentWithBlock:(NotificationBlock *)block
{
    [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentApproved withBlogID:block.metaSiteID];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service approveCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf reloadData];
    }];

    [block setActionOverrideValue:@(true) forKey:NoteActionApproveKey];
    [self.tableView reloadData];
}

- (void)unapproveCommentWithBlock:(NotificationBlock *)block
{
    [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentUnapproved withBlogID:block.metaSiteID];
  
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unapproveCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionApproveKey];
    [self.tableView reloadData];
}

- (void)spamCommentWithBlock:(NotificationBlock *)block
{
    NSParameterAssert(block);
    NSParameterAssert(self.onDeletionRequestCallback);
    
    // Spam Action
    NotificationDeletionActionBlock spamAction = ^(NotificationDeletionCompletionBlock onCompletion) {
        NSParameterAssert(onCompletion);
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service spamCommentWithID:block.metaCommentID siteID:block.metaSiteID success:^{
            onCompletion(YES);
        } failure:^(NSError *error){
            onCompletion(NO);
        }];
        
        [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentFlaggedAsSpam withBlogID:block.metaSiteID];
    };
    
    // Hit the DeletionRequest Callback
    self.onDeletionRequestCallback(spamAction);    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)trashCommentWithBlock:(NotificationBlock *)block
{
    NSParameterAssert(block);
    NSParameterAssert(self.onDeletionRequestCallback);
    
    // Trash Action
    NotificationDeletionActionBlock deletionAction =  ^(NotificationDeletionCompletionBlock onCompletion) {
        NSParameterAssert(onCompletion);
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service deleteCommentWithID:block.metaCommentID siteID:block.metaSiteID success:^{
            onCompletion(YES);
        } failure:^(NSError *error) {
            onCompletion(NO);
        }];
        
        [WPAppAnalytics track:WPAnalyticsStatNotificationsCommentTrashed withBlogID:block.metaSiteID];
    };
    
    // Hit the DeletionRequest Callback
    self.onDeletionRequestCallback(deletionAction);
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Replying Comments

- (void)editReplyWithBlock:(NotificationBlock *)block
{
    EditReplyViewController *editViewController     = [EditReplyViewController newReplyViewControllerForSiteID:self.note.metaSiteID];
    
    editViewController.onCompletion                 = ^(BOOL hasNewContent, NSString *newContent) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (hasNewContent) {
                [self sendReplyWithBlock:block content:newContent];
            }
        }];
    };
    
    UINavigationController *navController           = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navController.modalPresentationStyle            = UIModalPresentationFormSheet;
    navController.modalTransitionStyle              = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent         = NO;
    
    [self presentViewController:navController animated:true completion:nil];
}

- (void)sendReplyWithBlock:(NotificationBlock *)block content:(NSString *)content
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [service replyToCommentWithID:block.metaCommentID
                           siteID:block.metaSiteID
                          content:content
                          success:^{
                              NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
                              [SVProgressHUD showSuccessWithStatus:successMessage];
                          }
                          failure:^(NSError *error) {
                              [self handleReplyErrorWithBlock:block content:content];
                          }];
}

- (void)handleReplyErrorWithBlock:(NotificationBlock *)block content:(NSString *)content
{
    NSString *message = NSLocalizedString(@"There has been an unexpected error while sending your reply", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Try Again", nil) handler:^(UIAlertAction *action) {
        [self sendReplyWithBlock:block content:content];
    }];
    
    // Note: This viewController might not be visible anymore
    [alertController presentFromRootViewController];
}


#pragma mark - Editing Comments

- (void)editCommentWithBlock:(NotificationBlock *)block
{
    EditCommentViewController *editViewController   = [EditCommentViewController newEditViewController];
    
    editViewController.content                      = block.text;
    editViewController.onCompletion                 = ^(BOOL hasNewContent, NSString *newContent) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (hasNewContent) {
                [self updateCommentWithBlock:block content:newContent];
            }
        }];
    };
    
    UINavigationController *navController           = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navController.modalPresentationStyle            = UIModalPresentationFormSheet;
    navController.modalTransitionStyle              = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent         = NO;
    
    [self presentViewController:navController animated:true completion:nil];

}

- (void)updateCommentWithBlock:(NotificationBlock *)block content:(NSString *)content
{
    // Local Override: Temporary hack until Simperium reflects the REST op
    block.textOverride = content;
    [self reloadData];
    
    // Hit the backend
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [service updateCommentWithID:block.metaCommentID siteID:block.metaSiteID content:content success:nil failure:^(NSError *error) {
        [self handleCommentUpdateErrorWithBlock:block content:content];
    }];
}

- (void)handleCommentUpdateErrorWithBlock:(NotificationBlock *)block content:(NSString *)content
{
    NSString *message = NSLocalizedString(@"There has been an unexpected error while updating your comment", nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addCancelActionWithTitle:NSLocalizedString(@"Give Up", nil) handler:^(UIAlertAction *action) {
        block.textOverride = nil;
        [self reloadData];
    }];
    
    [alertController addDefaultActionWithTitle:NSLocalizedString(@"Try Again", nil) handler:^(UIAlertAction *action) {
        [self updateCommentWithBlock:block content:content];
    }];
    
    // Note: This viewController might not be visible anymore
    [alertController presentFromRootViewController];
}


#pragma mark - Storyboard Helpers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:NSStringFromClass([StatsViewController class])]) {
        NSParameterAssert([sender isKindOfClass:[Blog class]]);
        
        StatsViewController *statsViewController        = segue.destinationViewController;
        statsViewController.blog                        = (Blog *)sender;
        
    } else if([segue.identifier isEqualToString:NSStringFromClass([ReaderCommentsViewController class])]) {
        NSParameterAssert([sender isKindOfClass:[NSDictionary class]]);
        
        NSDictionary *parameters                        = (NSDictionary *)sender;
        NSNumber *siteID                                = parameters[NotificationsSiteIdKey];
        NSNumber *postID                                = parameters[NotificationsPostIdKey];
        
        ReaderCommentsViewController *commentsViewController = segue.destinationViewController;
        [commentsViewController setAllowsPushingPostDetails:YES];
        [commentsViewController setupWithPostID:postID siteID:siteID];        
        
    } else if([segue.identifier isEqualToString:[ReaderDetailViewController classNameWithoutNamespaces]]) {
        NSParameterAssert([sender isKindOfClass:[NSDictionary class]]);
        
        NSDictionary *parameters                        = (NSDictionary *)sender;
        NSNumber *siteID                                = parameters[NotificationsSiteIdKey];
        NSNumber *postID                                = parameters[NotificationsPostIdKey];
        
        ReaderDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:postID siteID:siteID];
    }
}


#pragma mark - Notification Helpers

- (void)handleNotificationChange:(NSNotification *)notification
{
    NSSet *updated      = notification.userInfo[NSUpdatedObjectsKey];
    NSSet *refreshed    = notification.userInfo[NSRefreshedObjectsKey];
    NSSet *deleted      = notification.userInfo[NSDeletedObjectsKey];
    
    // Reload the table, if *our* notification got updated
    if ([updated containsObject:self.note] || [refreshed containsObject:self.note]) {
        [self reloadData];
    }
    
    // Dismiss this ViewController if *our* notification... just got deleted
    if ([deleted containsObject:self.note]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)handleKeyboardWillShow:(NSNotification *)notification
{
    NSDictionary* userInfo = notification.userInfo;
    
    // Convert the rect to view coordinates: enforce the current orientation!
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];
    
    // Bottom Inset: Consider the tab bar!
    CGRect viewFrame = self.view.frame;
    CGFloat bottomInset = CGRectGetHeight(kbRect) - (CGRectGetMaxY(kbRect) - CGRectGetHeight(viewFrame));
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [self.view updateConstraintWithFirstItem:self.view
                                  secondItem:self.replyTextView
                          firstItemAttribute:NSLayoutAttributeBottom
                         secondItemAttribute:NSLayoutAttributeBottom
                                    constant:bottomInset];
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
    NSDictionary* userInfo = notification.userInfo;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    [self.view updateConstraintWithFirstItem:self.view
                                  secondItem:self.replyTextView
                          firstItemAttribute:NSLayoutAttributeBottom
                         secondItemAttribute:NSLayoutAttributeBottom
                                    constant:0];
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
}


#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.tableGesturesRecognizer.enabled = true;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.tableGesturesRecognizer.enabled = false;
}

- (void)textView:(UITextView *)textView didTypeWord:(NSString *)word
{
    [self.suggestionsTableView showSuggestionsForWord:word];
}


#pragma mark - SuggestionsTableViewDelegate

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    [self.replyTextView replaceTextAtCaret:text withText:suggestion];
    [suggestionsTableView showSuggestionsForWord:@""];
}


#pragma mark - Gestures Recognizer Delegate

- (IBAction)dismissKeyboardIfNeeded:(id)sender
{
    // Dismiss the reply field when tapping on the tableView
    [self.view endEditing:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)oth
{
    // Note: the tableViewGestureRecognizer may compete with another GestureRecognizer. Make sure it doesn't get cancelled
    return YES;
}

@end
