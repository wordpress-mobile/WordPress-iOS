#import "CommentViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
#import "BasePost.h"
#import "SVProgressHUD+Dismiss.h"
#import "EditCommentViewController.h"
#import "PostService.h"
#import "BlogService.h"
#import "SuggestionsTableView.h"
#import "WordPress-Swift.h"
#import <WordPressUI/WordPressUI.h>


#pragma mark - Constants

static NSInteger const CommentsDetailsNumberOfSections  = 1;
static NSInteger const CommentsDetailsHiddenRowNumber   = -1;

typedef NS_ENUM(NSUInteger, CommentsDetailsRow) {
    CommentsDetailsRowHeader    = 0,
    CommentsDetailsRowText      = 1,
    CommentsDetailsRowActions   = 2,
    CommentsDetailsRowCount     = 3     // Should always be the last element
};


#pragma mark - CommentViewController

@interface CommentViewController () <UITableViewDataSource, UITableViewDelegate, ReplyTextViewDelegate, SuggestionsTableViewDelegate>

@property (nonatomic, strong) UITableView               *tableView;
@property (nonatomic, strong) ReplyTextView             *replyTextView;
@property (nonatomic, strong) SuggestionsTableView      *suggestionsTableView;
@property (nonatomic, strong) NSLayoutConstraint        *bottomLayoutConstraint;
@property (nonatomic, strong) KeyboardDismissHelper     *keyboardManager;

@property (nonatomic, strong) NSDictionary              *reuseIdentifiersMap;
@property (nonatomic, assign) NSUInteger                numberOfRows;
@property (nonatomic, assign) NSUInteger                rowNumberForHeader;
@property (nonatomic, assign) NSUInteger                rowNumberForComment;
@property (nonatomic, assign) NSUInteger                rowNumberForActions;

@property (nonatomic, strong) NSCache                   *estimatedRowHeights;

@property (nonatomic) BOOL userCanLikeAndReply;
@property (nonatomic, strong) NoteBlockTableViewCell *commentCell;

@end

@implementation CommentViewController

- (void)loadView
{
    [super loadView];

    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboardIfNeeded:)];
    tapRecognizer.cancelsTouchesInView = NO;

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.cellLayoutMarginsFollowReadableWidth = YES;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:tableView];

    self.tableView = tableView;

    [WPStyleGuide configureColorsForView:self.view andTableView:tableView];

    // Register Cell Nibs
    NSArray *cellClassNames = @[
        NSStringFromClass([NoteBlockHeaderTableViewCell class]),
        NSStringFromClass([NoteBlockCommentTableViewCell class]),
        NSStringFromClass([NoteBlockActionsTableViewCell class])
    ];
    
    for (NSString *cellClassName in cellClassNames) {
        Class cellClass         = NSClassFromString(cellClassName);
        NSString *className     = [cellClass classNameWithoutNamespaces];
        UINib *tableViewCellNib = [UINib nibWithNibName:className bundle:[NSBundle mainBundle]];
        
        [self.tableView registerNib:tableViewCellNib forCellReuseIdentifier:[cellClass reuseIdentifier]];
    }

    self.userCanLikeAndReply = !self.comment.isReadOnly;
    [self attachSuggestionsTableViewIfNeeded];
    [self attachReplyView];
    [self setupAutolayoutConstraints];
    [self setupKeyboardManager];

    self.estimatedRowHeights = [[NSCache alloc] init];
}

- (void)attachSuggestionsTableViewIfNeeded
{
    if (![self shouldAttachSuggestionsTableView]) {
        return;
    }
    
    self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:self.comment.blog.dotComID suggestionType:SuggestionTypeMention delegate:self];
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
}

- (void)attachReplyView
{
    if (!self.userCanLikeAndReply) {
        return;
    }
    
    __typeof(self) __weak weakSelf = self;
    
    NSString *placeholderFormat = NSLocalizedString(@"Reply to %1$@", @"Placeholder text for replying to a comment. %1$@ is a placeholder for the comment author's name.");
    
    ReplyTextView *replyTextView = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.placeholder = [NSString stringWithFormat:placeholderFormat, [self.comment authorForDisplay]];
    replyTextView.onReply = ^(NSString *content) {
        [weakSelf sendReplyWithNewContent:content];
    };
    replyTextView.delegate = self;
    self.replyTextView = replyTextView;

    [self.view addSubview:self.replyTextView];
}

- (void)setupAutolayoutConstraints
{
    BOOL showingReplyView = self.replyTextView != nil;
    
    NSMutableDictionary *views = [@{@"tableView": self.tableView} mutableCopy];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    if (showingReplyView) {
        self.bottomLayoutConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.replyTextView.bottomAnchor];
        self.bottomLayoutConstraint.active = YES;
    }

    if (showingReplyView) {
        [NSLayoutConstraint activateConstraints:@[
            [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [self.replyTextView.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
            [self.replyTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.replyTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
    }

    if ([self shouldAttachSuggestionsTableView] && showingReplyView) {
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
}

- (void)setupKeyboardManager
{
    self.keyboardManager = [[KeyboardDismissHelper alloc] initWithParentView:self.view
                                                                  scrollView:self.tableView
                                                          dismissableControl:self.replyTextView
                                                      bottomLayoutConstraint:self.bottomLayoutConstraint];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self fetchPostIfNecessary];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.keyboardManager startListeningToKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.keyboardManager stopListeningToKeyboardNotifications];
    [self dismissNotice];
}

#pragma mark - Fetching Post

- (void)fetchPostIfNecessary
{
    // if the post is already set for the comment, no need to do anything else
    if (self.comment.post) {
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];

    __weak __typeof(self) weakSelf = self;

    // when the post is updated, all it's comment will be associated to it, reloading tableView is enough
    [postService getPostWithID:[NSNumber numberWithInt:self.comment.postID]
                       forBlog:self.comment.blog
                       success:^(AbstractPost *post) {
                           [weakSelf reloadData];
                       }
                       failure:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return CommentsDetailsNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = self.reuseIdentifiersMap[@(indexPath.row)];
    NSAssert(reuseIdentifier, @"Missing Layout Identifier!");
    
    NoteBlockTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    NSAssert([cell isKindOfClass:[NoteBlockTableViewCell class]], @"Missing cell!");
    
    [self setupCell:cell];
    [self setupSeparators:cell indexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.estimatedRowHeights setObject:@(cell.frame.size.height) forKey:indexPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == self.rowNumberForHeader) {
        if (![self.comment.blog supports:BlogFeatureWPComRESTAPI]) {
            [self openWebViewWithURL:[NSURL URLWithString:self.comment.post.permaLink]];
            return;
        }
        
        ReaderDetailViewController *vc = [ReaderDetailViewController
                                          controllerWithPostID:[NSNumber numberWithInt:self.comment.postID]
                                          siteID:self.comment.blog.dotComID
                                          isFeed:NO];

        [self.navigationController pushFullscreenViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *cachedHeight = [self.estimatedRowHeights objectForKey:indexPath];
    if (cachedHeight.doubleValue) {
        return cachedHeight.doubleValue;
    }
    return WPTableViewDefaultRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - Setup Cells

- (void)setupCell:(UITableViewCell *)cell
{
    NSParameterAssert(cell);

    // This is gonna look way better in Swift!
    if ([cell isKindOfClass:[NoteBlockHeaderTableViewCell class]]) {
        [self setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell];
    } else if ([cell isKindOfClass:[NoteBlockCommentTableViewCell class]]) {
        [self setupCommentCell:(NoteBlockCommentTableViewCell *)cell];
    } else if ([cell isKindOfClass:[NoteBlockActionsTableViewCell class]]) {
        [self setupActionsCell:(NoteBlockActionsTableViewCell *)cell];
    }
}

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell
{
    NSString *postTitle = [self.comment.post titleForDisplay];
    if (postTitle.length == 0) {
        postTitle = [self.comment.post contentPreviewForDisplay];
    }

    // Setup the cell
    cell.headerTitle = self.comment.post.authorForDisplay;
    cell.headerDetails = postTitle;
    
    // Setup the Separator
    SeparatorsView *separatorsView = cell.separatorsView;
    separatorsView.bottomVisible = YES;
    
    // Setup the Gravatar if needed
    if ([self.comment.post respondsToSelector:@selector(authorAvatarURL)]) {
        [cell downloadAuthorAvatarWithURL:[NSURL URLWithString:self.comment.post.authorAvatarURL]];
    }
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell
{
    // Setup the Cell
    cell.isTextViewSelectable = YES;
    cell.dataDetectors = UIDataDetectorTypeAll;

    // Setup the Fields
    cell.name = self.comment.authorForDisplay;
    cell.timestamp = [self.comment.dateCreated mediumString];
    cell.site = self.comment.authorUrlForDisplay;
    cell.commentText = [self.comment contentForDisplay];
    cell.isApproved = [self.comment.status isEqualToString:[Comment descriptionFor:CommentStatusTypeApproved]];

    __typeof(self) __weak weakSelf = self;
    NSURL *commentURL = [weakSelf.comment commentURL];
    if (commentURL) {
        cell.onTimeStampLongPress = ^(void) {
            [UIAlertController presentAlertAndCopyCommentURLToClipboardWithUrl:commentURL];
        };
    }

    if ([self.comment avatarURLForDisplay]) {
        [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];
    } else {
        [cell downloadGravatarWithEmail:[self.comment gravatarEmailForDisplay]];
    }

    cell.onUrlClick = ^(NSURL *url){
        [weakSelf openWebViewWithURL:url];
    };

    cell.onUserClick = ^{
        NSURL *url = [self.comment authorURL];
        if (url) {
            [weakSelf openWebViewWithURL:url];
        }
    };
    
    self.commentCell = cell;
}

- (void)setupActionsCell:(NoteBlockActionsTableViewCell *)cell
{
    // Setup the Cell
    if (self.comment.blog.isHostedAtWPcom || self.comment.blog.isAtomic) {
        cell.isReplyEnabled = [UIDevice isPad] && self.userCanLikeAndReply;
        cell.isLikeEnabled = [self.comment.blog supports:BlogFeatureCommentLikes] && self.userCanLikeAndReply;
        cell.isApproveEnabled = self.comment.canModerate;
        cell.isTrashEnabled = self.comment.canModerate;
        cell.isSpamEnabled = self.comment.canModerate;
        cell.isEditEnabled = self.comment.canModerate;
    } else {
        cell.isReplyEnabled = [UIDevice isPad];
        cell.isLikeEnabled = [self.comment.blog supports:BlogFeatureCommentLikes];
        cell.isApproveEnabled = YES;
        cell.isTrashEnabled = YES;
        cell.isSpamEnabled = YES;
        cell.isEditEnabled = YES;
    }

    if (cell.allActionsDisabled) {
        [cell setHidden:YES];
        if (self.commentCell) {
            self.commentCell.separatorsView.bottomInsets = UIEdgeInsetsZero;
        }
        return;
    }

    cell.isApproveOn = [self.comment.status isEqualToString:[Comment descriptionFor:CommentStatusTypeApproved]];
    cell.isLikeOn = self.comment.isLiked;

    // Setup the Callbacks
    __weak __typeof(self) weakSelf = self;

    cell.onReplyClick = ^(UIButton *sender) {
        [weakSelf focusOnReplyTextView];
    };

    cell.onLikeClick = ^(UIButton *sender){
        [weakSelf toggleLikeForComment];
    };

    cell.onUnlikeClick = ^(UIButton *sender){
        [weakSelf toggleLikeForComment];
    };

    cell.onApproveClick = ^(UIButton *sender){
        [weakSelf approveComment];
    };

    cell.onUnapproveClick = ^(UIButton *sender){
        [weakSelf unapproveComment];
    };

    cell.onTrashClick = ^(UIButton *sender){
        [weakSelf trashComment];
    };

    cell.onSpamClick = ^(UIButton *sender){
        [weakSelf spamComment];
    };

    cell.onEditClick = ^(UIButton *sender) {
        [weakSelf editComment];
    };
}


#pragma mark - Setup properties required by Cell Separator Logic

- (void)setupSeparators:(NoteBlockTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.isLastRow = (indexPath.row >= self.numberOfRows - 1);
    [cell refreshSeparators];
}


#pragma mark - Actions

- (void)openWebViewWithURL:(NSURL *)url
{
    if (![url isKindOfClass:[NSURL class]]) {
        DDLogError(@"CommentsViewController: Attempted to open an invalid URL [%@]", url);
        return;
    }

    UIViewController *webViewController = [WebViewControllerFactory controllerAuthenticatedWithDefaultAccountWithUrl:url source:@"comments"];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)toggleLikeForComment
{
    __typeof(self) __weak weakSelf = self;

    if (self.comment.isLiked) {
        [CommentAnalytics trackCommentUnLikedWithComment:[self comment]];
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    } else {
        [CommentAnalytics trackCommentLikedWithComment:[self comment]];
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService toggleLikeStatusForComment:self.comment
                                        siteID:self.comment.blog.dotComID
                                       success:nil
                                       failure:^(NSError *error) {
                                           [weakSelf reloadData];
                                       }];

}

- (void)approveComment
{
    __typeof(self) __weak weakSelf = self;

    [CommentAnalytics trackCommentApprovedWithComment:[self comment]];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    [commentService approveComment:self.comment success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf displayNoticeWithTitle:NSLocalizedString(@"Error approving comment", @"Message shown when approving a Comment fails.") message:nil];
            DDLogError(@"Error approving comment: %@", error.localizedDescription);
            [weakSelf reloadData];
        });
    }];
}

- (void)unapproveComment
{
    __typeof(self) __weak weakSelf = self;

    [CommentAnalytics trackCommentUnApprovedWithComment:[self comment]];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [commentService unapproveComment:self.comment success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf displayNoticeWithTitle:NSLocalizedString(@"Error unapproving comment", @"Message shown when unapproving a Comment fails.") message:nil];
            DDLogError(@"Error unapproving comment: %@", error.localizedDescription);
            [weakSelf reloadData];
        });
    }];
}

- (void)trashComment
{
    // If the comment was optimistically deleted, and the user has managed to
    // trigger this action again before the controller was dismissed, ignore
    // the action.
    if (![[self comment] managedObjectContext]) {
        return;
    }

    __typeof(self) __weak weakSelf = self;
    BOOL willBePermanentlyDeleted = [self.comment deleteWillBePermanent];
    
    NSString *trashMessage = NSLocalizedString(@"Are you sure you want to mark this comment as Trash?",
                                               @"Message asking for confirmation before marking a comment as trash");
    NSString *deleteMessage = NSLocalizedString(@"Are you sure you want to permanently delete this comment?",
                                                @"Message asking for confirmation on comment deletion");
    NSString *trashTitle = NSLocalizedString(@"Trash", @"Trash button title");
    NSString *deleteTitle = NSLocalizedString(@"Delete", @"Delete button title");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                                                                             message:willBePermanentlyDeleted ? deleteMessage : trashMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:willBePermanentlyDeleted ? deleteTitle : trashTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                            [weakSelf deleteAction];
                                                            // Note: the parent class of CommentsViewController will pop this as a result of NSFetchedResultsChangeDelete
                                                        }];
    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteAction
{
    UINavigationController *navController = self.navigationController;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [CommentAnalytics trackCommentTrashedWithComment:[self comment]];
    
    [commentService deleteComment:self.comment success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [navController popViewControllerAnimated:YES];
        });
    } failure:^(NSError *error) {
        // The comment was optimistically deleted from core data. Even tho the
        // request failed, still pop the view controller to avoid presenting the
        // user with a broken UI or risk oddness due to the faulted managed object.
        // Dispatch the notice from the nav controller after a delay for the pop
        // animation so it remains in view.
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogError(@"Error deleting comment: %@", error.localizedDescription);
            [navController popViewControllerAnimated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [navController displayNoticeWithTitle:NSLocalizedString(@"Error deleting comment", @"Message shown when deleting a Comment fails.") message:nil];
            });
        });
    }];
}

- (void)spamComment
{
    __typeof(self) __weak weakSelf = self;
    
    NSString *message = NSLocalizedString(@"Are you sure you want to mark this comment as Spam?",
                                          @"Message asking for confirmation before marking a comment as spam");
    
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *spamAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Spam", @"Spam")
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
                                                            [weakSelf spamAction];
                                                       }];
    [alertController addAction:cancelAction];
    [alertController addAction:spamAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)spamAction
{
    __typeof(self) __weak weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    
    [CommentAnalytics trackCommentSpammedWithComment:[self comment]];
    
    [commentService spamComment:self.comment success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf displayNoticeWithTitle:NSLocalizedString(@"Error marking comment as spam", @"Message shown when marking a Comment as spam fails.") message:nil];
            DDLogError(@"Error marking comment as spam: %@", error.localizedDescription);
            [weakSelf reloadData];
        });
    }];
}

#pragma mark - Editing comment

- (void)editComment
{
    EditCommentTableViewController *editViewController = [[EditCommentTableViewController alloc] initWithComment:self.comment];
    __typeof(self) __weak weakSelf = self;
    editViewController.completion = ^(Comment *comment, BOOL commentChanged) {
        if (commentChanged) {
            weakSelf.comment = comment;
            [weakSelf updateComment];
        }
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;

    [self presentViewController:navController animated:true completion:nil];

    [CommentAnalytics trackCommentEditorOpenedWithComment:[self comment]];
}

- (void)updateComment
{
    [self reloadData];

    // Regardless of success or failure track the user's intent to save a change.
    [CommentAnalytics trackCommentEditedWithComment:[self comment]];
    
    // Hit the backend
    __typeof(self) __weak weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService uploadComment:self.comment
                          success:^{
                              // The comment might have changed its approval status!
                              [weakSelf reloadData];
                          } failure:^(NSError *error) {
                              NSString *message = NSLocalizedString(@"There has been an unexpected error while editing your comment",
                                                                    @"Error displayed if a comment fails to get updated");
                              
                              [weakSelf displayNoticeWithTitle:message message:nil];
                          }];
}


#pragma mark - Replying Comments for iPad

- (void)focusOnReplyTextView
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [self.replyTextView becomeFirstResponder];
#pragma clang diagnostic pop
}

- (void)sendReplyWithNewContent:(NSString *)content
{
    __typeof(self) __weak weakSelf = self;
    
    void (^successBlock)(void) = ^void() {
        NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
        [weakSelf displayNoticeWithTitle:successMessage message:nil];
    };
    
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        NSString *message = error.localizedDescription ?: NSLocalizedString(@"There has been an unexpected error while sending your reply", @"Reply Failure Message");
        [weakSelf displayNoticeWithTitle:message message:nil];
    };
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    Comment *reply = [commentService createReplyForComment:self.comment];
    reply.content = content;
    [commentService uploadComment:reply success:successBlock failure:failureBlock];
    [CommentAnalytics trackCommentRepliedToComment:[self comment]];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.keyboardManager scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.keyboardManager scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self.keyboardManager scrollViewWillEndDragging:scrollView withVelocity:velocity];
}


#pragma mark - ReplyTextViewDelegate

- (void)textView:(UITextView *)textView didTypeWord:(NSString *)word
{
    [self.suggestionsTableView showSuggestionsForWord:word];
}

- (void)replyTextView:(ReplyTextView *)replyTextView willEnterFullScreen:(FullScreenCommentReplyViewController *)controller
{
    [self.suggestionsTableView hideSuggestions];

    [controller enableSuggestionsWith:self.comment.blog.dotComID];
}

#pragma mark - SuggestionsTableViewDelegate

- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text
{
    [self.replyTextView replaceTextAtCaret:text withText:suggestion];
    [suggestionsTableView showSuggestionsForWord:@""];
}


#pragma mark - Gestures Recognizer Delegate

- (void)dismissKeyboardIfNeeded:(id)sender
{
    // Dismiss the reply field when tapping on the tableView
    [self.view endEditing:YES];
}


#pragma mark - Setters

- (void)setComment:(Comment *)comment
{
    _comment = comment;
    [self reloadData];
}


#pragma mark - Helpers

- (BOOL)shouldAttachSuggestionsTableView
{
    return [self shouldShowSuggestionsFor:self.comment.blog.dotComID];
}

- (void)reloadData
{
    // If we don't have the associated post, let's hide the Header
    BOOL shouldShowHeader       = self.comment.post != nil;

    // Number of Rows:
    // NOTE: If the post wasn't retrieved yet, we'll need to hide the Header.
    // For that reason, the Row Count is decreased, and rowNumberForHeader is set with a different index.
    self.numberOfRows           = shouldShowHeader ? CommentsDetailsRowCount  : CommentsDetailsRowCount - 1;
    self.rowNumberForHeader     = shouldShowHeader ? CommentsDetailsRowHeader : CommentsDetailsHiddenRowNumber;
    self.rowNumberForComment    = self.rowNumberForHeader + 1;
    self.rowNumberForActions    = self.rowNumberForComment + 1;
    
    // Arrange the Reuse + Layout Identifier Map(s)
    self.reuseIdentifiersMap = @{
        @(self.rowNumberForHeader)    : NoteBlockHeaderTableViewCell.reuseIdentifier,
        @(self.rowNumberForComment)   : NoteBlockCommentTableViewCell.reuseIdentifier,
        @(self.rowNumberForActions)   : NoteBlockActionsTableViewCell.reuseIdentifier,
    };

    // Reload the table, at last!
    [self.tableView reloadData];
}

@end
