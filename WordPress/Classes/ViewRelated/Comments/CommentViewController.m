#import "CommentViewController.h"
#import "WPWebViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "UIAlertView+Blocks.h"
#import "WordPress-Swift.h"
#import "UIActionSheet+Helpers.h"
#import "Comment.h"
#import "BasePost.h"
#import "SVProgressHUD.h"
#import "EditCommentViewController.h"
#import "EditReplyViewController.h"
#import "ReaderPostDetailViewController.h"
#import "PostService.h"
#import "Post.h"
#import "BlogService.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"



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

@property (nonatomic, strong) UITableView           *tableView;
@property (nonatomic, strong) ReplyTextView         *replyTextView;
@property (nonatomic, strong) SuggestionsTableView  *suggestionsTableView;

@property (nonatomic, strong) NSDictionary          *layoutIdentifiersMap;
@property (nonatomic, strong) NSDictionary          *reuseIdentifiersMap;
@property (nonatomic, assign) NSUInteger            numberOfRows;
@property (nonatomic, assign) NSUInteger            rowNumberForHeader;
@property (nonatomic, assign) NSUInteger            rowNumberForComment;
@property (nonatomic, assign) NSUInteger            rowNumberForActions;

@end

@implementation CommentViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];

    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboardIfNeeded:)];
    tapRecognizer.cancelsTouchesInView = NO;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:self.tableView];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

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
        [self.tableView registerNib:tableViewCellNib forCellReuseIdentifier:[cellClass layoutIdentifier]];
    }

    
    [self attachSuggestionsTableViewIfNeeded];
    [self attachReplyViewIfNeeded];
    [self setupAutolayoutConstraints];
}

- (void)attachSuggestionsTableViewIfNeeded
{
    if (![self shouldAttachSuggestionsTableView]) {
        return;
    }
    
    self.suggestionsTableView = [[SuggestionsTableView alloc] initWithSiteID:self.comment.blog.blogID];
    self.suggestionsTableView.suggestionsDelegate = self;
    [self.suggestionsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.suggestionsTableView];
}

- (void)attachReplyViewIfNeeded
{
    if (![self shouldAttachReplyTextView]) {
        return;
    }

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

- (void)attachEditActionButton
{
    UIBarButtonItem *editBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Verb, start editing")
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(editComment)];
    
    self.navigationItem.rightBarButtonItem = editBarButton;
}

- (void)setupAutolayoutConstraints
{
    NSMutableDictionary *views = [@{@"tableView": self.tableView} mutableCopy];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    if ([self shouldAttachReplyTextView]) {
        views[@"replyTextView"] = self.replyTextView;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][replyTextView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[replyTextView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    }
    else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    }
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self attachEditActionButton];
    [self fetchPostIfNecessary];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.replyTextView resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == self.rowNumberForHeader) {
        if (![self.comment.blog supports:BlogFeatureWPComRESTAPI]) {
            [self openWebViewWithURL:[NSURL URLWithString:self.comment.post.permaLink]];
            return;
        }

        ReaderPostDetailViewController *vc = [ReaderPostDetailViewController detailControllerWithPostID:self.comment.postID siteID:self.comment.blog.dotComID];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *layoutIdentifier = self.layoutIdentifiersMap[@(indexPath.row)];
    NSAssert(layoutIdentifier, @"Missing Layout Identifier!");
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:layoutIdentifier];
    NSAssert(cell, @"Missing layout cell!");
    
    [self setupCell:cell];
    
    return [cell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
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
    cell.headerTitle = self.comment.post.author;
    cell.headerDetails = postTitle;
    
    // Setup the Separator
    NoteSeparatorsView *separatorsView = cell.separatorsView;
    separatorsView.bottomVisible = YES;
    
    // Setup the Gravatar if needed
    if (cell.isLayoutCell == NO && [self.comment.post respondsToSelector:@selector(authorAvatarURL)]) {
        [cell downloadGravatarWithURL:[NSURL URLWithString:self.comment.post.authorAvatarURL]];
    }
}

- (void)setupCommentCell:(NoteBlockCommentTableViewCell *)cell
{
    // Setup the Cell
    cell.isTextViewSelectable = YES;
    cell.dataDetectors = UIDataDetectorTypeAll;

    // Setup the Fields
    cell.name = self.comment.author;
    cell.timestamp = [self.comment.dateCreated shortString];
    cell.site = self.comment.authorUrlForDisplay;
    cell.commentText = [self.comment contentForDisplay];
    cell.isApproved = [self.comment.status isEqualToString:@"approve"];
    
    if (cell.isLayoutCell == NO) {
        if ([self.comment avatarURLForDisplay]) {
            [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];
        } else {
            [cell downloadGravatarWithGravatarEmail:[self.comment gravatarEmailForDisplay]];
        }
    }

    // Setup the Callbacks
    __weak __typeof(self) weakSelf = self;

    cell.onUrlClick = ^(NSURL *url){
        [weakSelf openWebViewWithURL:url];
    };

    cell.onDetailsClick = ^(UIButton *sender){
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

    cell.isApproveOn = [self.comment.status isEqualToString:@"approve"];
    cell.isLikeOn = self.comment.isLiked;

    // Setup the Callbacks
    __weak __typeof(self) weakSelf = self;

    cell.onReplyClick = ^(UIButton *sender) {
        [weakSelf editReply];
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
}


#pragma mark - Setup properties required by Cell Separator Logic

- (void)setupSeparators:(NoteBlockTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.isLastRow = (indexPath.row >= self.numberOfRows - 1);
}


#pragma mark - Actions

- (void)openWebViewWithURL:(NSURL *)url
{
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:url];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)toggleLikeForComment
{
    __typeof(self) __weak weakSelf = self;


    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService toggleLikeStatusForComment:self.comment
                                        siteID:self.comment.blog.blogID
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

    // Callback Block
    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }

        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
        [commentService deleteComment:weakSelf.comment success:nil failure:nil];

        // Note: the parent class of CommentsViewController will pop this as a result of NSFetchedResultsChangeDelete
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

- (void)spamComment
{
    __typeof(self) __weak weakSelf = self;

    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }

        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
        [commentService spamComment:weakSelf.comment success:nil failure:nil];
    };

    NSString *message = NSLocalizedString(@"Are you sure you want to mark this comment as Spam?",
                                          @"Message asking for confirmation before marking a comment as spam");

    [UIAlertView showWithTitle:NSLocalizedString(@"Confirm", @"Confirm")
                       message:message
             cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
             otherButtonTitles:@[NSLocalizedString(@"Spam", @"Spam")]
                      tapBlock:completion];
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
                              [UIAlertView showWithTitle:nil
                                                 message:message
                                       cancelButtonTitle:NSLocalizedString(@"Cancel", @"Verb, Cancel an action")
                                       otherButtonTitles:@[ NSLocalizedString(@"Try Again", @"Retry an action that failed") ]
                                                tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                    if (buttonIndex == alertView.cancelButtonIndex) {
                                                        [weakSelf.comment.managedObjectContext refreshObject:weakSelf.comment mergeChanges:false];
                                                        [weakSelf reloadData];
                                                    } else {
                                                        [weakSelf updateCommentForNewContent:content];
                                                    }
                                                }
                               ];
                          }];
}


#pragma mark - Replying Comments for iPad

- (void)editReply
{
    __typeof(self) __weak weakSelf = self;
    
    EditReplyViewController *editViewController = [EditReplyViewController newReplyViewControllerForSiteID:self.comment.blog.blogID];

    editViewController.onCompletion = ^(BOOL hasNewContent, NSString *newContent) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (hasNewContent) {
                [weakSelf sendReplyWithNewContent:newContent];
            }
        }];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.navigationBar.translucent = NO;
    [self presentViewController:navController animated:true completion:nil];
}

- (void)sendReplyWithNewContent:(NSString *)content
{
    NSString *successMessage = NSLocalizedString(@"Reply Sent!", @"The app successfully sent a comment");

    __typeof(self) __weak weakSelf = self;

    void (^successBlock)() = ^void() {
        [SVProgressHUD showSuccessWithStatus:successMessage];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [UIAlertView showWithTitle:nil
                           message:NSLocalizedString(@"There has been an unexpected error while sending your reply", nil)
                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                 otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  [weakSelf sendReplyWithNewContent:content];
                              }
                          }];
    };

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    Comment *reply = [commentService createReplyForComment:self.comment];
    reply.content = content;
    [commentService uploadComment:reply success:successBlock failure:failureBlock];
}


#pragma mark - Keyboard Management

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

- (BOOL)shouldAttachReplyTextView
{
    // iPad: We've got a different UI!
    return ![UIDevice isPad];
}

- (BOOL)shouldAttachSuggestionsTableView
{
    BOOL shouldShowSuggestions = [[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.comment.blog.blogID];
    return self.shouldAttachReplyTextView && shouldShowSuggestions;
}

- (void)reloadData
{
    // If we don't have the associated post, let's hide the Header
    BOOL shouldShowHeader       = self.comment.post != nil;;

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
    
    self.layoutIdentifiersMap = @{
        @(self.rowNumberForHeader)    : NoteBlockHeaderTableViewCell.layoutIdentifier,
        @(self.rowNumberForComment)   : NoteBlockCommentTableViewCell.layoutIdentifier,
        @(self.rowNumberForActions)   : NoteBlockActionsTableViewCell.layoutIdentifier,
    };
    
    // Reload the table, at last!
    [self.tableView reloadData];
}

@end
