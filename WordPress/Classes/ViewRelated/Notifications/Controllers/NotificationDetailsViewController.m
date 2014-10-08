#import "NotificationDetailsViewController.h"

#import "WordPressAppDelegate.h"
#import <Simperium/Simperium.h>

#import "Blog.h"
#import "Notification.h"
#import "WPToast.h"

#import "ContextManager.h"

#import "BlogService.h"
#import "CommentService.h"
#import "ReaderSiteService.h"

#import "WPWebViewController.h"
#import "ReaderPostDetailViewController.h"
#import "StatsViewController.h"
#import "EditCommentViewController.h"
#import "EditReplyViewController.h"
#import "SuggestionsTableView.h"

#import "WordPress-Swift.h"

#import "NSURL+Util.h"
#import "NSScanner+Helpers.h"
#import "UIActionSheet+Helpers.h"
#import "UIAlertView+Blocks.h"
#import "NSObject+Helpers.h"
#import "NSDate+StringFormatting.h"



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static UIEdgeInsets NotificationTableInsetsPhone    = {0.0f,  0.0f, 20.0f, 0.0f};
static UIEdgeInsets NotificationTableInsetsPad      = {40.0f, 0.0f, 20.0f, 0.0f};

static NSString *NotificationReplyToastImage        = @"action-icon-replied";
static NSString *NotificationSuccessToastImage      = @"action-icon-success";

typedef NS_ENUM(NSInteger, NotificationSection) {
    NotificationSectionHeader,
    NotificationSectionBody,
    NotificationSectionCount
};

static NSInteger NotificationSectionHeaderRows  = 1;
static CGFloat NotificationSectionSeparator     = 10;


#pragma mark ==========================================================================================
#pragma mark Private
#pragma mark ==========================================================================================

@interface NotificationDetailsViewController () <UITextViewDelegate, SuggestionsDelegate>

// Outlets
@property (nonatomic,   weak) IBOutlet UITableView          *tableView;
@property (nonatomic,   weak) IBOutlet UIGestureRecognizer  *tableGesturesRecognizer;
@property (nonatomic, strong) ReplyTextView                 *replyTextView;
@property (nonatomic, strong) SuggestionsTableView          *suggestionsTableView;

// Table Helpers
@property (nonatomic, strong) NSDictionary                  *layoutCellMap;
@property (nonatomic, strong) NSDictionary                  *reuseIdentifierMap;
@property (nonatomic, assign) NSInteger                     sectionCount;
@property (nonatomic, assign) NSInteger                     headerSectionIndex;
@property (nonatomic, assign) NSInteger                     bodySectionIndex;

// Model
@property (nonatomic, strong) Notification                  *note;
@end


#pragma mark ==========================================================================================
#pragma mark NotificationDetailsViewController
#pragma mark ==========================================================================================

@implementation NotificationDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title                          = self.note.title;
    self.restorationClass               = [self class];
    self.view.backgroundColor           = [WPStyleGuide itsEverywhereGrey];
    
    // Don't show the notification title in the next-view's back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    self.tableView.separatorStyle       = self.note.isBadge ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor      = [WPStyleGuide itsEverywhereGrey];
    
    self.reuseIdentifierMap = @{
        @(NoteBlockGroupTypeHeader)    : NoteBlockHeaderTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeText)      : NoteBlockTextTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeComment)   : NoteBlockCommentTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeImage)     : NoteBlockImageTableViewCell.reuseIdentifier,
        @(NoteBlockGroupTypeUser)      : NoteBlockUserTableViewCell.reuseIdentifier
    };
    
    NSManagedObjectContext *context = self.note.managedObjectContext;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotificationChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];
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

- (void)reloadData
{
    // Hide the header, if needed
    self.sectionCount       = NotificationSectionCount;
    self.headerSectionIndex = NotificationSectionHeader;
    self.bodySectionIndex   = NotificationSectionBody;
    
    if (self.note.headerBlockGroup == nil) {
        self.sectionCount--;
        self.headerSectionIndex--;
        self.bodySectionIndex--;
    }
    
    [self.tableView reloadData];
    [self adjustTableInsetsIfNeeded];
}


#pragma mark - Public Helpers

- (void)setupWithNotification:(Notification *)notification
{
    self.note = notification;
    [self attachReplyViewIfNeeded];
    [self reloadData];
}


#pragma mark - Autolayout Helpers

- (NSDictionary *)layoutCellMap
{
    if (_layoutCellMap) {
        return _layoutCellMap;
    }
    
    NSString *storyboardID  = NSStringFromClass([self class]);
    NotificationDetailsViewController *detailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:storyboardID];
    
    [detailsViewController loadView];
    
    UITableView *tableView  = detailsViewController.tableView;

    _layoutCellMap = @{
        @(NoteBlockGroupTypeHeader)    : [tableView dequeueReusableCellWithIdentifier:NoteBlockHeaderTableViewCell.reuseIdentifier],
        @(NoteBlockGroupTypeText)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockTextTableViewCell.reuseIdentifier],
        @(NoteBlockGroupTypeComment)   : [tableView dequeueReusableCellWithIdentifier:NoteBlockCommentTableViewCell.reuseIdentifier],
        @(NoteBlockGroupTypeImage)     : [tableView dequeueReusableCellWithIdentifier:NoteBlockImageTableViewCell.reuseIdentifier],
        @(NoteBlockGroupTypeUser)      : [tableView dequeueReusableCellWithIdentifier:NoteBlockUserTableViewCell.reuseIdentifier]
    };
    
    return _layoutCellMap;
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
    
    __typeof(self) __weak weakSelf  = self;
    
    ReplyTextView *replyTextView    = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.placeholder       = NSLocalizedString(@"Write a reply…", @"Placeholder text for inline compose view");
    replyTextView.replyText         = [NSLocalizedString(@"Reply", @"") uppercaseString];
    replyTextView.onReply           = ^(NSString *content) {
        [weakSelf sendReplyWithBlock:block content:content];
    };
    replyTextView.delegate          = self;
    self.replyTextView              = replyTextView;
    
    // Attach the ReplyTextView at the very bottom
    [self.view addSubview:self.replyTextView];
    [self.view pinSubviewAtBottom:self.replyTextView];
    [self.view pinSubview:self.tableView aboveSubview:self.replyTextView];
    
    // TODO don't hardcode site ID
    SuggestionsTableView *suggestionsTableView = [[SuggestionsTableView alloc] initWithWidth:CGRectGetWidth(self.view.frame)
                                                                                   andSiteID:@54117];
    // TODO add a mentions delegate to avoid collision with other tableviews callbacks
    // suggestionsTableView.delegate              = self;
    self.suggestionsTableView                  = suggestionsTableView;
    [self.view addSubview:self.suggestionsTableView];
    [self.view pinSubviewAtBottom:self.suggestionsTableView];
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
    return (indexPath.section == _headerSectionIndex) ? _note.headerBlockGroup : _note.bodyBlockGroups[indexPath.row];
}


#pragma mark - UITableViewDelegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    /**
        Note
        This is a workaround. iOS 7 + grouped cells result in an extra top spacing.
        Ref.: http://stackoverflow.com/questions/17699831/how-to-change-height-of-grouped-uitableview-header
     */

    return (section == _bodySectionIndex && _sectionCount > 1) ? NotificationSectionSeparator : CGFLOAT_MIN;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == _headerSectionIndex) ? NotificationSectionHeaderRows : self.note.bodyBlockGroups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NoteBlockTableViewCell *tableViewCell   = self.layoutCellMap[@(blockGroup.type)] ?: self.layoutCellMap[@(NoteBlockGroupTypeText)];
    
    [self setupCell:tableViewCell blockGroup:blockGroup];

    CGFloat height = [tableViewCell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *blockGroup      = [self blockGroupForIndexPath:indexPath];
    NSString *reuseIdentifier               = self.reuseIdentifierMap[@(blockGroup.type)] ?: self.reuseIdentifierMap[@(NoteBlockGroupTypeText)];
    NoteBlockTableViewCell *cell            = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self setupCell:cell blockGroup:blockGroup];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBlockGroup *group = [self blockGroupForIndexPath:indexPath];

    // User Blocks: Push the associated blog, if any
    if (group.type == NoteBlockGroupTypeUser) {
        
        NotificationBlock *block    = [group blockOfType:NoteBlockTypeUser];
        NSURL *homeURL              = [NSURL URLWithString:block.metaLinksHome];
        
        [self openURL:homeURL];
        
    // Header-Level: Push the resource associated with the note
    } else if (group.type == NoteBlockGroupTypeHeader) {

        [self displayReaderWithPostId:self.note.metaPostID siteID:self.note.metaSiteID];
    }
}


#pragma mark - NoteBlockTableViewCell Helpers

- (void)setupCell:(NoteBlockTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    // Note: This is gonna look awesome in Swift
    if (blockGroup.type == NoteBlockGroupTypeHeader) {
        [self setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell blockGroup:blockGroup];
        
    } else if (blockGroup.type == NoteBlockGroupTypeUser) {
        [self setupUserCell:(NoteBlockUserTableViewCell *)cell blockGroup:blockGroup];
        
    } else if (blockGroup.type == NoteBlockGroupTypeComment){
        [self setupCommentCell:(NoteBlockCommentTableViewCell *)cell blockGroup:blockGroup];
        
    } else if (blockGroup.type == NoteBlockGroupTypeImage) {
        [self setupImageCell:(NoteBlockImageTableViewCell *)cell blockGroup:blockGroup];
        
    } else {
        [self setupTextCell:(NoteBlockTextTableViewCell *)cell blockGroup:blockGroup];
    }
}

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *gravatarBlock    = [blockGroup blockOfType:NoteBlockTypeImage];
    NotificationBlock *snippetBlock     = [blockGroup blockOfType:NoteBlockTypeText];
    NotificationMedia *media            = gravatarBlock.media.firstObject;
    
    cell.name                           = gravatarBlock.text;
    cell.snippet                        = snippetBlock.text;
    
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupUserCell:(NoteBlockUserTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *userBlock    = blockGroup.blocks.firstObject;
    NotificationMedia *media        = [userBlock.media firstObject];
    BOOL hasHomeURL                 = (userBlock.metaLinksHome != nil);
    
    NSAssert(userBlock, nil);
    
    __weak __typeof(self) weakSelf  = self;
    
    cell.accessoryType              = hasHomeURL ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.name                       = userBlock.text;
    cell.blogTitle                  = userBlock.metaTitlesHome;
    cell.isFollowEnabled            = [userBlock isActionEnabled:NoteActionFollowKey];
    cell.isFollowOn                 = [userBlock isActionOn:NoteActionFollowKey];
    cell.onFollowClick              = ^() {
        [weakSelf followSiteWithBlock:userBlock];
    };
    cell.onUnfollowClick            = ^() {
        [weakSelf unfollowSiteWithBlock:userBlock];
    };
    
    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *commentBlock = [blockGroup blockOfType:NoteBlockTypeComment];
    NotificationBlock *userBlock    = [blockGroup blockOfType:NoteBlockTypeUser];
    NotificationMedia *media        = userBlock.media.firstObject;
    
    NSAssert(commentBlock, nil);
    NSAssert(userBlock, nil);
    
    __weak __typeof(self) weakSelf  = self;
    
    cell.isReplyEnabled             = [UIDevice isPad] && [commentBlock isActionOn:NoteActionReplyKey];
    cell.isLikeEnabled              = [commentBlock isActionEnabled:NoteActionLikeKey];
    cell.isApproveEnabled           = [commentBlock isActionEnabled:NoteActionApproveKey];
    cell.isTrashEnabled             = [commentBlock isActionEnabled:NoteActionTrashKey];
    cell.isMoreEnabled              = [commentBlock isActionEnabled:NoteActionApproveKey];

    cell.isLikeOn                   = [commentBlock isActionOn:NoteActionLikeKey];
    cell.isApproveOn                = [commentBlock isActionOn:NoteActionApproveKey];
    
    cell.name                       = userBlock.text;
    cell.timestamp                  = [self.note.timestampAsDate shortString];
    cell.attributedCommentText      = commentBlock.regularAttributedTextOverride ?: commentBlock.regularAttributedText;

    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
    
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
    
    cell.onMoreClick                = ^(UIButton * sender){
        [weakSelf displayMoreActionsWithBlock:commentBlock sender:sender];
    };

    [cell downloadGravatarWithURL:media.mediaURL];
}

- (void)setupImageCell:(NoteBlockImageTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *imageBlock   = blockGroup.blocks.firstObject;
    NSAssert(imageBlock, nil);
    
    NotificationMedia *media        = imageBlock.media.firstObject;
    cell.isBadge                    = media.isBadge;
    
    [cell downloadImageWithURL:media.mediaURL];
}

- (void)setupTextCell:(NoteBlockTextTableViewCell *)cell blockGroup:(NotificationBlockGroup *)blockGroup
{
    NotificationBlock *textBlock    = blockGroup.blocks.firstObject;
    NSAssert(textBlock, nil);
    
    __weak __typeof(self) weakSelf  = self;
    
    cell.attributedText             = textBlock.regularAttributedText;
    cell.isBadge                    = self.note.isBadge;
    cell.onUrlClick                 = ^(NSURL *url){
        [weakSelf openURL:url];
    };
}


#pragma mark - Helpers

- (void)openURL:(NSURL *)url
{
    //  NOTE:
    //
    //  DTAttributedLabel doesn't allow us to use *any* object as a DTLinkAttribute instance.
    //  So, we lose the range metadata: is it a post? stats? comment?.
    //  In this step, we attempt to match the URL with any NotificationRange instance, contained in the note,
    //  and thus, recover the metadata!
    //
    NotificationRange *range    = [self.note notificationRangeWithUrl:url];
    BOOL success                = false;
    
    if (range.isPost || range.isComment) {
        success = [self displayReaderWithPostId:range.postID siteID:range.siteID];
    }
    
    if (!success && range.isStats) {
        success = [self displayStatsWithSiteID:range.siteID];
    }
    
    if (!success && url) {
        success = [self displayWebViewWithURL:url];
    }
    
    if (!success) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}

- (BOOL)displayReaderWithPostId:(NSNumber *)postID siteID:(NSNumber *)siteID
{
    BOOL success = postID && siteID;
    if (success) {
        NSArray *parameters = @[ siteID, postID ];
        [self performSegueWithIdentifier:NSStringFromClass([ReaderPostDetailViewController class]) sender:parameters];
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
    BOOL success                    = blog.isWPcom;
    
    if (success) {
        // TODO: Update StatsViewController to work with initWithCoder!
        StatsViewController *vc     = [[StatsViewController alloc] init];
        vc.blog = blog;
        [self.navigationController pushViewController:vc animated:YES];
    }
    return success;
}

- (BOOL)displayWebViewWithURL:(NSURL *)url
{
    BOOL success = url != nil;
    if (success) {
        [self performSegueWithIdentifier:NSStringFromClass([WPWebViewController class]) sender:url];
    }
    return success;
}

- (void)displayMoreActionsWithBlock:(NotificationBlock *)block sender:(UIButton *)sender
{
    NSString *editTitle     = NSLocalizedString(@"Edit Comment", @"Edit a comment");
    NSString *spamTitle     = NSLocalizedString(@"Mark as Spam", @"Mark a comment as spam");
    NSString *cancelTitle   = NSLocalizedString(@"Cancel", nil);
    
    // Prepare the More Menu
    NSMutableArray *otherButtonTitles  = [NSMutableArray array];
    
    if ([block isActionEnabled:NoteActionEditKey]) {
        [otherButtonTitles addObject:editTitle];
    }
    
    if ([block isActionEnabled:NoteActionSpamKey]) {
        [otherButtonTitles addObject:spamTitle];
    }
    
    // Render the actionSheet
    __typeof(self) __weak weakSelf = self;
    UIActionSheet *actionSheet  = [[UIActionSheet alloc] initWithTitle:nil
                                                     cancelButtonTitle:cancelTitle
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:otherButtonTitles
                                                            completion:^(NSString *buttonTitle) {
                                                                if ([buttonTitle isEqualToString:editTitle]) {
                                                                    [weakSelf editCommentWithBlock:block];
                                                                } else if ([buttonTitle isEqualToString:spamTitle]) {
                                                                    [weakSelf spamCommentWithBlock:block];
                                                                }
                                                            }];
    
    if ([UIDevice isPad]) {
        [actionSheet showFromRect:sender.bounds inView:sender animated:true];
    } else {
        [actionSheet showInView:self.view.window];
    }
}


#pragma mark - Action Handlers

- (void)followSiteWithBlock:(NotificationBlock *)block
{
    [WPAnalytics track:WPAnalyticsStatNotificationFollowAction];
    
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
    [WPAnalytics track:WPAnalyticsStatNotificationUnfollowAction];
    
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
    [WPAnalytics track:WPAnalyticsStatNotificationLiked];
    
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
    [WPAnalytics track:WPAnalyticsStatNotificationUnliked];
    
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
    [WPAnalytics track:WPAnalyticsStatNotificationApproved];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service approveCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(true) forKey:NoteActionApproveKey];
}

- (void)unapproveCommentWithBlock:(NotificationBlock *)block
{
    [WPAnalytics track:WPAnalyticsStatNotificationUnapproved];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    __typeof(self) __weak weakSelf  = self;
    
    [service unapproveCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:^(NSError *error) {
        [block removeActionOverrideForKey:NoteActionApproveKey];
        [weakSelf reloadData];
    }];
    
    [block setActionOverrideValue:@(false) forKey:NoteActionApproveKey];
}

- (void)spamCommentWithBlock:(NotificationBlock *)block
{
    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
        
        [WPAnalytics track:WPAnalyticsStatNotificationFlaggedAsSpam];
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service spamCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    };
    
    NSString *message = NSLocalizedString(@"Are you sure you want to mark this comment as Spam?",
                                          @"Message asking for confirmation before marking a comment as spam");
    
    [UIAlertView showWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                       message:message
             cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
             otherButtonTitles:@[NSLocalizedString(@"Spam", @"Spam")]
                      tapBlock:completion];
}

- (void)trashCommentWithBlock:(NotificationBlock *)block
{
    // Callback Block
    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
        
        [WPAnalytics track:WPAnalyticsStatNotificationTrashed];
        
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
        
        [service deleteCommentWithID:block.metaCommentID siteID:block.metaSiteID success:nil failure:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    };
 
    // Show the alertView
    NSString *message = NSLocalizedString(@"Are you sure you want to delete this comment?",
                                          @"Message asking for confirmation on comment deletion");
    
    [UIAlertView showWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                       message:message
             cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
             otherButtonTitles:@[NSLocalizedString(@"Delete", @"Delete")]
                      tapBlock:completion];
}


#pragma mark - Replying Comments

- (void)editReplyWithBlock:(NotificationBlock *)block
{
    EditReplyViewController *editViewController     = [EditReplyViewController newEditViewController];
    
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
    NSString *successMessage        = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
    NSString *sendingMessage        = NSLocalizedString(@"Sending...", @"The app is uploading a comment");
    UIImage *successImage           = [UIImage imageNamed:NotificationSuccessToastImage];
    UIImage *sendingImage           = [UIImage imageNamed:NotificationReplyToastImage];
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *service         = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [service replyToCommentWithID:block.metaCommentID siteID:block.metaSiteID content:content success:^(){
        [WPToast showToastWithMessage:successMessage andImage:successImage];
        
    } failure:^(NSError *error) {
        [self handleReplyErrorWithBlock:block content:content];
    }];
    
    [WPToast showToastWithMessage:sendingMessage andImage:sendingImage];
}

- (void)handleReplyErrorWithBlock:(NotificationBlock *)block content:(NSString *)content
{
    [UIAlertView showWithTitle:nil
                       message:NSLocalizedString(@"There has been an unexpected error while sending your reply", nil)
             cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
             otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex != alertView.cancelButtonIndex) {
                              [self sendReplyWithBlock:block content:content];
                          }
                      }];
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
    [UIAlertView showWithTitle:nil
                       message:NSLocalizedString(@"There has been an unexpected error while updating your comment", nil)
             cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
             otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == alertView.cancelButtonIndex) {
                              block.textOverride = nil;
                              [self reloadData];
                          } else {
                              [self updateCommentWithBlock:block content:content];
                          }
                      }];
}


#pragma mark - Storyboard Helpers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:NSStringFromClass([WPWebViewController class])]) {
        WPWebViewController *webViewController          = segue.destinationViewController;
        webViewController.url                           = (NSURL *)sender;
        
    } else if([segue.identifier isEqualToString:NSStringFromClass([StatsViewController class])]) {
        StatsViewController *statsViewController        = segue.destinationViewController;
        statsViewController.blog                        = (Blog *)sender;
        
    } else if([segue.identifier isEqualToString:NSStringFromClass([ReaderPostDetailViewController class])]) {
        NSArray *parameters                             = (NSArray *)sender;
        NSNumber *siteID                                = parameters.firstObject;
        NSNumber *postID                                = parameters.lastObject;
        
        ReaderPostDetailViewController *readerViewController = segue.destinationViewController;
        [readerViewController setupWithPostID:postID siteID:siteID];
    }
}


#pragma mark - Notification Helpers

- (void)handleNotificationChange:(NSNotification *)notification
{
    NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
    NSSet *refreshed = notification.userInfo[NSRefreshedObjectsKey];
    
    // Reload the table, if *our* notification got updated
    if ([updated containsObject:self.note] || [refreshed containsObject:self.note]) {
        [self reloadData];
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

#pragma mark - SuggestionsDelegate

- (void)didTypeInWord:(NSString *)word
{
    [self.suggestionsTableView showSuggestionsForWord:word];
}

- (void)didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    [self.replyTextView replaceRecentlyTypedWord:text withSuggestion:suggestion];
}

#pragma mark - Gestures Recognizer Delegate

- (IBAction)dismissKeyboardIfNeeded:(id)sender
{
    // Dismiss the reply field when tapping on the tableView
    self.replyTextView.text = [NSString string];
    [self.view endEditing:YES];
}

@end
