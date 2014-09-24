#import "ACommentViewController.h"
#import "WPWebViewController.h"
#import "CommentService.h"
#import "ContextManager.h"
#import "UIAlertView+Blocks.h"
#import "WordPress-Swift.h"
#import "Comment.h"
#import "BasePost.h"

static NSString *const CVCHeaderCellIdentifier = @"CommentTableViewHeaderCell";
static NSString *const CVCCommentCellIdentifier = @"CommentTableViewCell";
static NSInteger const CVCHeaderSectionIndex = 0;
static NSInteger const CVCSectionSeparatorHeight = 10;

@interface ACommentViewController ()

@property (nonatomic, strong) NoteBlockHeaderTableViewCell *headerLayoutCell;
@property (nonatomic, strong) CommentTableViewCell *bodyLayoutCell;

@property (nonatomic, strong) CommentService *commentService;

@end

@implementation ACommentViewController

- (void)loadView
{
    [super loadView];

    UINib *headerCellNib = [UINib nibWithNibName:@"CommentTableViewHeaderCell" bundle:nil];
    UINib *bodyCellNib = [UINib nibWithNibName:@"CommentTableViewCell" bundle:nil];
    [self.tableView registerNib:headerCellNib forCellReuseIdentifier:CVCHeaderCellIdentifier];
    [self.tableView registerNib:bodyCellNib forCellReuseIdentifier:CVCCommentCellIdentifier];
    self.headerLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCHeaderCellIdentifier];
    self.bodyLayoutCell = [self.tableView dequeueReusableCellWithIdentifier:CVCCommentCellIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == CVCHeaderSectionIndex) {
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
    return (section == CVCHeaderSectionIndex) ? CGFLOAT_MIN : CVCSectionSeparatorHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == CVCHeaderSectionIndex) {
        [self setupHeaderCell:self.headerLayoutCell];
        cell = self.headerLayoutCell;
    }
    else {
        [self setupCommentCell:self.bodyLayoutCell];
        cell = self.bodyLayoutCell;
    }

    CGFloat height = [cell layoutHeightWithWidth:CGRectGetWidth(self.tableView.bounds)];

    return height;
}

#pragma mark - Setup Cells

- (void)setupHeaderCell:(NoteBlockHeaderTableViewCell *)cell
{
    // TODO: figure out why self.comment.post is nil and how we can get that information
//    cell.name = self.comment.post.author;
//    cell.snippet = self.comment.post.content;
//
//    if ([self.comment.post respondsToSelector:@selector(authorAvatarURL)]) {
//        [cell downloadGravatarWithURL:[self.comment.post performSelector:@selector(authorAvatarURL)]];
//    }
}

- (void)setupCommentCell:(CommentTableViewCell *)cell
{
    cell.name = self.comment.author;
    cell.timestamp = [self.comment.dateCreated shortString];
    cell.isApproveOn = [self.comment.status isEqualToString:@"approve"];
    cell.commentText = self.comment.content;
    [cell downloadGravatarWithURL:self.comment.avatarURLForDisplay];

    __weak __typeof(self) weakSelf = self;

    cell.onUrlClick = ^(NSURL *url){
        [weakSelf openWebViewWithURL:url];
    };

    cell.onLikeClick = ^(){
        [weakSelf likeComment];
    };

    cell.onUnlikeClick = ^(){
        [weakSelf unlikeComment];
    };

    cell.onApproveClick = ^(){
        [weakSelf approveComment];
    };

    cell.onUnapproveClick = ^(){
        [weakSelf unapproveComment];
    };

    cell.onTrashClick = ^(){
        [weakSelf trashComment];
    };

    cell.onMoreClick = ^(){
        [weakSelf displayMoreActions];
    };
}

#pragma mark - Actions

- (void)openWebViewWithURL:(NSURL *)url
{
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    webViewController.url = url;
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)likeComment
{
    __typeof(self) __weak weakSelf = self;

    [self.commentService likeCommentWithID:self.comment.commentID siteID:self.comment.blog.blogID success:nil failure:^(NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

- (void)unlikeComment
{
    __typeof(self) __weak weakSelf = self;

    [self.commentService unlikeCommentWithID:self.comment.commentID siteID:self.comment.blog.blogID success:nil failure:^(NSError *error) {
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

        CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
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

- (void)displayMoreActions
{

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

@end
