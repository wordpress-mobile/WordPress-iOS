#import "CommentViewController.h"
#import "WPWebViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "UIAlertView+Blocks.h"
#import "WordPress-Swift.h"
#import "UIActionSheet+Helpers.h"
#import "Comment.h"
#import "BasePost.h"
#import "WPToast.h"
#import "EditCommentViewController.h"
#import "EditReplyViewController.h"
#import "ReaderPostDetailViewController.h"
#import "PostService.h"
#import "Post.h"
#import "BlogService.h"
#import "SuggestionsTableView.h"
#import "SuggestionService.h"

static NSString *const CVCReplyToastImage = @"action-icon-replied";
static NSString *const CVCSuccessToastImage = @"action-icon-success";
static NSString *const CVCHeaderCellIdentifier = @"CommentTableViewHeaderCell";
static NSString *const CVCCommentCellIdentifier = @"CommentTableViewCell";
static CGFloat const CVCFirstSectionHeaderHeight = 40;
static CGFloat const CVCSectionSeparatorHeight = 10;
static NSInteger const CVCHeaderSectionIndex = 0;
static NSInteger const CVCNumberOfRows = 1;
static NSInteger const CVCNumberOfSections = 2;

@interface CommentViewController () <UITableViewDataSource, UITableViewDelegate, ReplyTextViewDelegate, SuggestionsTableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NoteBlockHeaderTableViewCell *headerLayoutCell;
@property (nonatomic, strong) CommentTableViewCell *bodyLayoutCell;
@property (nonatomic, strong) ReplyTextView *replyTextView;
@property (nonatomic, strong) SuggestionsTableView *suggestionsTableView;

@end

@implementation CommentViewController

- (void)loadView
{
    [super loadView];

    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboardIfNeeded:)];
    tapRecognizer.cancelsTouchesInView = NO;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:self.tableView];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    UINib *headerCellNib = [UINib nibWithNibName:@"CommentTableViewHeaderCell" bundle:nil];
    UINib *bodyCellNib = [UINib nibWithNibName:@"CommentTableViewCell" bundle:nil];
    [self.tableView registerNib:headerCellNib forCellReuseIdentifier:CVCHeaderCellIdentifier];
    [self.tableView registerNib:bodyCellNib forCellReuseIdentifier:CVCCommentCellIdentifier];
    self.headerLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCHeaderCellIdentifier];
    self.bodyLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCCommentCellIdentifier];

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

// if the post for the comment is nil, fetch it
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
                           [weakSelf.tableView reloadData];
                       }
                       failure:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self shouldShowHeaderForPostDetails] ? CVCNumberOfSections : CVCNumberOfSections - 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return CVCNumberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == CVCHeaderSectionIndex && [self shouldShowHeaderForPostDetails]) {
        NoteBlockHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CVCHeaderCellIdentifier];
        [self setupHeaderCell:cell];
        return cell;
    }
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CVCCommentCellIdentifier
                                                                 forIndexPath:indexPath];
    [self setupCommentCell:cell];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (!self.comment.blog.isWPcom) {
        [self openWebViewWithURL:[NSURL URLWithString:self.comment.post.permaLink]];
        return;
    }

    if (indexPath.section == CVCHeaderSectionIndex && [self shouldShowHeaderForPostDetails]) {
        ReaderPostDetailViewController *vc = [ReaderPostDetailViewController detailControllerWithPostID:self.comment.postID siteID:self.comment.blog.blogID];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat firstSectionHeaderHeight = [UIDevice isPad] ? CVCFirstSectionHeaderHeight : CGFLOAT_MIN;
    return (section == CVCHeaderSectionIndex) ? firstSectionHeaderHeight : CVCSectionSeparatorHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == CVCHeaderSectionIndex && [self shouldShowHeaderForPostDetails]) {
        [self setupHeaderCell:self.headerLayoutCell];
        cell = self.headerLayoutCell;
    }
    else {
        [self setupCommentCell:self.bodyLayoutCell];
        cell = self.bodyLayoutCell;
    }

    return [cell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

#pragma mark - Setup Cells

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell
{
    NSString *postTitle = [self.comment.post titleForDisplay];
    if (postTitle.length == 0) {
        postTitle = [self.comment.post contentPreviewForDisplay];
    }

    cell.header = self.comment.post.author;
    cell.snippet = postTitle;

    if (cell != self.headerLayoutCell && [self.comment.post respondsToSelector:@selector(authorAvatarURL)]) {
        [cell downloadGravatarWithURL:[NSURL URLWithString:self.comment.post.authorAvatarURL]];
    }
}

- (void)setupCommentCell:(CommentTableViewCell *)cell
{
    cell.isReplyEnabled = [UIDevice isPad];
    cell.isLikeEnabled = self.comment.blog.isWPcom;
    cell.isApproveEnabled = YES;
    cell.isTrashEnabled = YES;
    cell.isSpamEnabled = YES;

    cell.name = self.comment.author;
    cell.timestamp = [self.comment.dateCreated shortString];

    cell.timestamp = self.comment.hasAuthorUrl ?
                            [[self.comment.dateCreated shortString] stringByAppendingString:@" • "]
                            : [self.comment.dateCreated shortString];

    cell.isApproveOn = [self.comment.status isEqualToString:@"approve"];
    cell.commentText = [self.comment contentForDisplay];
    cell.isLikeOn = self.comment.isLiked;
    cell.site = self.comment.authorUrlForDisplay;

    if (cell != self.bodyLayoutCell) {
        if ([self.comment avatarURLForDisplay]) {
            [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];
        } else {
            [cell downloadGravatarWithGravatarEmail:[self.comment gravatarEmailForDisplay]];
        }
    }

    __weak __typeof(self) weakSelf = self;

    cell.onUrlClick = ^(NSURL *url){
        [weakSelf openWebViewWithURL:url];
    };

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

    cell.onSiteClick = ^(UIButton *sender){
        if (!self.comment.hasAuthorUrl) {
            return;
        }

        NSURL *url = [[NSURL alloc] initWithString:self.comment.author_url];
        if (url) {
            [weakSelf openWebViewWithURL:url];
        }
    };
}

#pragma mark - Actions

- (void)openWebViewWithURL:(NSURL *)url
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    webViewController.url = url;
    [self.navigationController pushViewController:webViewController animated:YES];
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
                                           [weakSelf.tableView reloadData];
                                       }];
}

- (void)approveComment
{
    __typeof(self) __weak weakSelf = self;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService approveComment:self.comment success:nil failure:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

- (void)unapproveComment
{
    __typeof(self) __weak weakSelf = self;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService unapproveComment:self.comment success:nil failure:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
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
    [self.tableView reloadData];
    // Hit the backend
    __typeof(self) __weak weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    [commentService uploadComment:self.comment
                          success:^{
                              // The comment might have changed its approval status!
                              [weakSelf.tableView reloadData];
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
                                                        [weakSelf.tableView reloadData];
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
    NSString *sendingMessage = NSLocalizedString(@"Sending...", @"The app is uploading a comment");
    UIImage *successImage = [UIImage imageNamed:CVCSuccessToastImage];
    UIImage *sendingImage = [UIImage imageNamed:CVCReplyToastImage];

    __typeof(self) __weak weakSelf = self;

    void (^successBlock)() = ^void() {
        [WPToast showToastWithMessage:successMessage andImage:successImage];
    };

    void (^failureBlock)(NSError *error) = ^void(NSError *error) {
        [UIAlertView showWithTitle:nil
                           message:NSLocalizedString(@"There has been an unexpected error while sending your reply", nil)
                 cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
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

    [WPToast showToastWithMessage:sendingMessage andImage:sendingImage];
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

#pragma mark - Helpers

- (BOOL)shouldAttachReplyTextView
{
    // iPad: We've got a different UI!
    return !([UIDevice isPad]);
}

- (BOOL)shouldAttachSuggestionsTableView
{
    return ([self shouldAttachReplyTextView] && [[SuggestionService sharedInstance] shouldShowSuggestionsForSiteID:self.comment.blog.blogID]);
}

// if the post is not set for the comment, we don't want to show an empty cell for the post details
- (BOOL)shouldShowHeaderForPostDetails
{
    return self.comment.post != nil;
}

@end
