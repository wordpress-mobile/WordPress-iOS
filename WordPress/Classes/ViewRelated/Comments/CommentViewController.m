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
#import "PostService.h"
#import "Post.h"

static NSString *const CVCReplyToastImage = @"action-icon-replied";
static NSString *const CVCSuccessToastImage = @"action-icon-success";
static NSString *const CVCHeaderCellIdentifier = @"CommentTableViewHeaderCell";
static NSString *const CVCCommentCellIdentifier = @"CommentTableViewCell";
static CGFloat const CVCFirstSectionHeaderHeight = 40;
static NSInteger const CVCHeaderSectionIndex = 0;
static NSInteger const CVCNumberOfRows = 1;
static NSInteger const CVCNumberOfSections = 2;
static NSInteger const CVCSectionSeparatorHeight = 10;

@interface CommentViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NoteBlockHeaderTableViewCell *headerLayoutCell;
@property (nonatomic, strong) CommentTableViewCell *bodyLayoutCell;
@property (nonatomic, strong) ReplyTextView *replyTextView;
@property (nonatomic, strong) CommentService *commentService;

@end

@implementation CommentViewController

- (void)loadView
{
    [super loadView];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboardIfNeeded:)]];
    [self.view addSubview:self.tableView];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    UINib *headerCellNib = [UINib nibWithNibName:@"CommentTableViewHeaderCell" bundle:nil];
    UINib *bodyCellNib = [UINib nibWithNibName:@"CommentTableViewCell" bundle:nil];
    [self.tableView registerNib:headerCellNib forCellReuseIdentifier:CVCHeaderCellIdentifier];
    [self.tableView registerNib:bodyCellNib forCellReuseIdentifier:CVCCommentCellIdentifier];
    self.headerLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCHeaderCellIdentifier];
    self.bodyLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCCommentCellIdentifier];

    [self attachReplyViewIfNeeded];

    [self setupAutolayoutConstraints];
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // if the post for the comment is nil, fetch it
    if (!self.comment.post) {
        __weak __typeof(self) weakSelf = self;

        [self.comment fetchPostWithSuccess:^{
            [weakSelf.tableView reloadData];
        }];
    }
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

#pragma mark - Setup Cells

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell
{
    cell.name = self.comment.post.author;
    cell.snippet = self.comment.post.content;

    if ([self.comment.post respondsToSelector:@selector(authorAvatarURL)]) {
        [cell downloadGravatarWithURL:[NSURL URLWithString:[(Post *)self.comment.post authorAvatarURL]]];
    }
}

- (void)setupCommentCell:(CommentTableViewCell *)cell
{
    cell.isReplyEnabled = [UIDevice isPad];
    cell.isLikeEnabled = self.comment.blog.isWPcom;
    cell.isApproveEnabled = YES;
    cell.isTrashEnabled = YES;
    cell.isMoreEnabled = YES;

    cell.name = self.comment.author;
    cell.timestamp = [self.comment.dateCreated shortString];
    cell.isApproveOn = [self.comment.status isEqualToString:@"approve"];
    cell.commentText = self.comment.content;
    cell.isLikeOn = self.comment.isLiked;
    [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];

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

    cell.onMoreClick = ^(UIButton *sender){
        [weakSelf displayMoreActionsForSender:sender];
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

    [self.commentService toggleLikeStatusForComment:self.comment siteID:self.comment.blog.blogID success:nil failure:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

- (void)approveComment
{
    __typeof(self) __weak weakSelf = self;

    [self.commentService approveComment:self.comment success:nil failure:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

- (void)unapproveComment
{
    __typeof(self) __weak weakSelf = self;

    [self.commentService unapproveComment:self.comment success:nil failure:^(NSError *error) {
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

        [weakSelf.commentService deleteComment:weakSelf.comment success:nil failure:nil];

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

- (void)displayMoreActionsForSender:(UIButton *)sender
{
    NSString *editTitle = NSLocalizedString(@"Edit Comment", @"Edit a comment");
    NSString *spamTitle = NSLocalizedString(@"Mark as Spam", @"Mark a comment as spam");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);

    NSArray *otherButtonTitles = @[editTitle, spamTitle];

    // Render the actionSheet
    __typeof(self) __weak weakSelf = self;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                    cancelButtonTitle:cancelTitle
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:otherButtonTitles
                                                           completion:^(NSString *buttonTitle) {
                                                               if ([buttonTitle isEqualToString:editTitle]) {
                                                                   [weakSelf editComment];
                                                               } else if ([buttonTitle isEqualToString:spamTitle]) {
                                                                   [weakSelf spamComment];
                                                               }
                                                           }];

    if ([UIDevice isPad]) {
        [actionSheet showFromRect:sender.bounds inView:sender animated:true];
    } else {
        [actionSheet showInView:self.view.window];
    }
}

- (void)spamComment
{
    __typeof(self) __weak weakSelf = self;

    UIAlertViewCompletionBlock completion = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }

        [weakSelf.commentService spamComment:self.comment success:nil failure:nil];
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

- (void)updateCommentForNewContent:(NSString *)newContent
{
    __typeof(self) __weak weakSelf = self;

    [self.commentService updateCommentWithID:self.comment.commentID
                                      siteID:self.comment.blog.blogID
                                     content:newContent
                                     success:^{
                                         weakSelf.comment.content = newContent;
                                         [weakSelf.tableView reloadData];
                                         [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                     }
                                     failure:^(NSError *error) {
                                         [UIAlertView showWithTitle:nil
                                                            message:NSLocalizedString(@"There has been an unexpected error while updating your comment", nil)
                                                  cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
                                                  otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                                                           tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                               if (buttonIndex == alertView.cancelButtonIndex) {
                                                                   [weakSelf.tableView reloadData];
                                                               } else {
                                                                   [weakSelf updateCommentForNewContent:newContent];
                                                               }
                                                           }];
                                     }];
}

#pragma mark - Replying Comments for iPad

- (void)editReply
{
    __typeof(self) __weak weakSelf = self;

    EditReplyViewController *editViewController = [EditReplyViewController newEditViewController];

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

    [self.commentService replyToCommentWithID:self.comment.commentID siteID:self.comment.blog.blogID content:content success:^(){
        [WPToast showToastWithMessage:successMessage andImage:successImage];

    } failure:^(NSError *error) {
        [UIAlertView showWithTitle:nil
                           message:NSLocalizedString(@"There has been an unexpected error while sending your reply", nil)
                 cancelButtonTitle:NSLocalizedString(@"Give Up", nil)
                 otherButtonTitles:@[ NSLocalizedString(@"Try Again", nil) ]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex != alertView.cancelButtonIndex) {
                                  [weakSelf sendReplyWithNewContent:content];
                              }
                          }];
    }];

    [WPToast showToastWithMessage:sendingMessage andImage:sendingImage];
}

#pragma mark - Setter/Getters

- (CommentService *)commentService
{
    if (!_commentService) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        _commentService = [[CommentService alloc] initWithManagedObjectContext:context];
    }
    return _commentService;
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

// if the post is not set for the comment, we don't want to show an empty cell for the post details
- (BOOL)shouldShowHeaderForPostDetails
{
    return self.comment.post != nil;
}

@end
