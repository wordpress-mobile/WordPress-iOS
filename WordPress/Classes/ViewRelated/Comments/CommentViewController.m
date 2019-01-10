#import "CommentViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
#import "Comment.h"
#import "BasePost.h"
#import "SVProgressHUD+Dismiss.h"
#import "EditCommentViewController.h"
#import "PostService.h"
#import "BlogService.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"
#import <WordPressUI/WordPressUI.h>



#pragma mark ==========================================================================================
#pragma mark Constants
#pragma mark ==========================================================================================

static NSInteger const CommentsDetailsNumberOfSections  = 1;
static NSInteger const CommentsDetailsHiddenRowNumber   = -1;

typedef NS_ENUM(NSUInteger, CommentsDetailsRow) {
    CommentsDetailsRowHeader    = 0,
    CommentsDetailsRowText      = 1,
    CommentsDetailsRowActions   = 2,
    CommentsDetailsRowCount     = 3     // Should always be the last element
};


#pragma mark ==========================================================================================
#pragma mark CommentViewController
#pragma mark ==========================================================================================

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
    
    self.suggestionsTableView = [SuggestionsTableView new];
    self.suggestionsTableView.siteID = self.comment.blog.dotComID;
    self.suggestionsTableView.suggestionsDelegate = self;
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
}

- (void)attachReplyView
{
    __typeof(self) __weak weakSelf = self;

    ReplyTextView *replyTextView = [[ReplyTextView alloc] initWithWidth:CGRectGetWidth(self.view.frame)];
    replyTextView.placeholder = NSLocalizedString(@"Write a reply…", @"Placeholder text for inline compose view");
    replyTextView.replyText = [NSLocalizedString(@"Reply", @"") uppercaseString];
    replyTextView.onReply = ^(NSString *content) {
        [weakSelf sendReplyWithNewContent:content];
    };
    replyTextView.delegate = self;
    self.replyTextView = replyTextView;

    [self.view addSubview:self.replyTextView];
}

- (void)setupAutolayoutConstraints
{
    NSMutableDictionary *views = [@{@"tableView": self.tableView} mutableCopy];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    self.bottomLayoutConstraint = [self.view.bottomAnchor constraintEqualToAnchor:self.replyTextView.bottomAnchor];
    self.bottomLayoutConstraint.active = YES;

    [NSLayoutConstraint activateConstraints:@[
                                              [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [self.replyTextView.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
                                              [self.replyTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [self.replyTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              ]];

    if ([self shouldAttachSuggestionsTableView]) {
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
    [postService getPostWithID:self.comment.postID
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

        ReaderDetailViewController *vc = [ReaderDetailViewController controllerWithPostID:self.comment.postID siteID:self.comment.blog.dotComID isFeed:NO];
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
    cell.isApproved = [self.comment.status isEqualToString:CommentStatusApproved];
     __typeof(self) __weak weakSelf = self;
    cell.onTimeStampLongPress = ^(void) {
        NSURL *url = [NSURL URLWithString:weakSelf.comment.link];
        [UIAlertController presentAlertAndCopyCommentURLToClipboardWithUrl:url];
    };

    if ([self.comment avatarURLForDisplay]) {
        [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];
    } else {
        [cell downloadGravatarWithEmail:[self.comment gravatarEmailForDisplay]];
    }

    cell.onUrlClick = ^(NSURL *url){
        [weakSelf openWebViewWithURL:url];
    };

    cell.onUserClick = ^{
        NSURL *url = [NSURL URLWithString:self.comment.author_url];
        if (url) {
            [weakSelf openWebViewWithURL:url];
        }
    };
}

- (void)setupActionsCell:(NoteBlockActionsTableViewCell *)cell
{
    // Setup the Cell
    cell.isReplyEnabled = [UIDevice isPad];
    cell.isLikeEnabled = [self.comment.blog supports:BlogFeatureCommentLikes];
    cell.isApproveEnabled = YES;
    cell.isTrashEnabled = YES;
    cell.isSpamEnabled = YES;

    cell.isApproveOn = [self.comment.status isEqualToString:CommentStatusApproved];
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
}


#pragma mark - Actions

- (void)openWebViewWithURL:(NSURL *)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);

    if (![url isKindOfClass:[NSURL class]]) {
        DDLogError(@"CommentsViewController: Attempted to open an invalid URL [%@]", url);
        return;
    }

    if (self.comment.blog.jetpack) {
        url = [url appendingHideMasterbarParameters];
    }
    
    UIViewController *webViewController = [WebViewControllerFactory controllerAuthenticatedWithDefaultAccountWithUrl:url];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)toggleLikeForComment
{
    __typeof(self) __weak weakSelf = self;

    if (!self.comment.isLiked) {
        [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
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

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService approveComment:self.comment success:nil failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
    
    [self reloadData];
}

- (void)unapproveComment
{
    __typeof(self) __weak weakSelf = self;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService unapproveComment:self.comment success:nil failure:^(NSError *error) {
        [weakSelf reloadData];
    }];
    
    [self reloadData];
}

- (void)trashComment
{
    __typeof(self) __weak weakSelf = self;
    
    NSString *message = NSLocalizedString(@"Are you sure you want to delete this comment?",
                                          @"Message asking for confirmation on comment deletion");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action){}];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action){
                                                             NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                                                             CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
                                                             
                                                             NSError *error = nil;
                                                             Comment *reloadedComment = (Comment *)[context existingObjectWithID:weakSelf.comment.objectID error:&error];
                                                             
                                                             if (error) {
                                                                 DDLogError(@"Comment was deleted while awaiting for alertView confirmation");
                                                                 return;
                                                             }
                                                             
                                                             [commentService deleteComment:reloadedComment success:nil failure:nil];
                                                             
                                                             // Note: the parent class of CommentsViewController will pop this as a result of NSFetchedResultsChangeDelete
                                                         }];
    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];
    [self presentViewController:alertController animated:YES completion:nil];
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
                                                         handler:^(UIAlertAction *action){}];
    
    UIAlertAction *spamAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Spam", @"Spam")
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action){
                                                           NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                                                           CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
                                                           
                                                           NSError *error = nil;
                                                           Comment *reloadedComment = (Comment *)[context existingObjectWithID:weakSelf.comment.objectID error:&error];
                                                           
                                                           if (error) {
                                                               DDLogError(@"Comment was deleted while awaiting for alertView confirmation");
                                                               return;
                                                           }
                                                           
                                                           [commentService spamComment:reloadedComment success:nil failure:nil];
                                                       }];
    [alertController addAction:cancelAction];
    [alertController addAction:spamAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Editing comment

- (void)editComment
{
    EditCommentViewController *editViewController = [EditCommentViewController newEditViewController];
    editViewController.content = self.comment.content;

    __typeof(self) __weak weakSelf = self;
    editViewController.onCompletion = ^(BOOL hasNewContent, NSString *newContent) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (hasNewContent) {
                [weakSelf updateCommentForNewContent:newContent];
            }
        }];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;

    [self presentViewController:navController animated:true completion:nil];
}

- (void)updateCommentForNewContent:(NSString *)content
{
    // Set the new Content Data
    self.comment.content = content;
    [self reloadData];
    
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
                              
                              UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                                       message:message
                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                              
                              UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Verb, Cancel an action")
                                                                                     style:UIAlertActionStyleCancel
                                                                                   handler:^(UIAlertAction *action){
                                                                                       [weakSelf.comment.managedObjectContext refreshObject:weakSelf.comment mergeChanges:false];
                                                                                       [weakSelf reloadData];
                                                                                   }];
                              
                              UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", @"Retry an action that failed")
                                                                                    style:UIAlertActionStyleDestructive
                                                                                  handler:^(UIAlertAction *action){
                                                                                      [weakSelf updateCommentForNewContent:content];
                                                                                  }];
                              [alertController addAction:cancelAction];
                              [alertController addAction:retryAction];
                              [weakSelf presentViewController:alertController animated:YES completion:nil];
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
    NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");
    
    __typeof(self) __weak weakSelf = self;
    
    void (^successBlock)(void) = ^void() {
        [SVProgressHUD showDismissibleSuccessWithStatus:successMessage];
    };
    
    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        NSUInteger lastIndex = content.length == 0 ? 0 : content.length - 1;
        NSUInteger composedCharacterIndex = NSMaxRange([content rangeOfComposedCharacterSequenceAtIndex:MIN(lastIndex, 140)]);
        // 140 is a somewhat arbitraily chosen number (old tweet length) — should be enough to let people know what
        // comment failed to show, but not too long to display.

        NSString *replyExcerpt = [content substringToIndex:composedCharacterIndex];

        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"There has been an unexpected error while sending your reply: \n\"%@\"", nil), replyExcerpt];
        if (composedCharacterIndex < lastIndex) {
            NSMutableString *mutString = message.mutableCopy;
            [mutString insertString:@"…" atIndex:(message.length - 2)];

            message = mutString.copy;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Verb, Cancel an action")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action){}];
        
        UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Try Again", @"Retry an action that failed")
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction *action){
                                                                [weakSelf sendReplyWithNewContent:content];
                                                            }];
        [alertController addAction:cancelAction];
        [alertController addAction:retryAction];
        [weakSelf presentViewController:alertController animated:YES completion:nil];
    };
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    Comment *reply = [commentService createReplyForComment:self.comment];
    reply.content = content;
    [commentService uploadComment:reply success:successBlock failure:failureBlock];
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
    return [[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.comment.blog.dotComID];
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
