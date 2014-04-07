#import "ReaderUsersBlogsViewController.h"
#import "AddUsersBlogCell.h"
#import "WordPressAppDelegate.h"
#import "WPNUXUtility.h"
#import "WPAccount.h"
#import "Blog.h"
#import "ContextManager.h"
#import "AccountService.h"

@interface ReaderUsersBlogsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *blogs;
@property (nonatomic, strong) NSNumber *primaryBlogId;

- (void)handleCloseButtonTapped:(id)sender;

@end

@implementation ReaderUsersBlogsViewController

#pragma mark - Lifecycle Methods

- (id)init {
	self = [super init];
	if (self) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

		_blogs = [defaultAccount visibleBlogs];
		_primaryBlogId = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_users_prefered_blog_id"];
	}
	return self;
}

- (void)viewDidLoad {
    self.title = NSLocalizedString(@"My Sites", @"Title of the list of the user's blogs as shown in the reader.");

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui-texture"]];
    self.view.backgroundColor = [WPNUXUtility backgroundColor];
	
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
	
	if (self.navigationItem.leftBarButtonItem == nil) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
																		style:[WPStyleGuide barButtonStyleForBordered]
																	   target:self
																	   action:@selector(handleCloseButtonTapped:)];
	}
	
	[_tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma mark - Instance Methods

- (NSString *)cellTitleForBlog:(Blog *)blog {
    if ([[blog.blogName trim] length] == 0) {
        return blog.hostURL;
	} else {
        return blog.blogName;
	}
}


- (void)handleCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_blogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    AddUsersBlogCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AddUsersBlogCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		[cell hideCheckmark:YES];
		UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		backgroundView.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green:192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
		cell.selectedBackgroundView = backgroundView;
		cell.isWPCom = YES;
    }

    Blog *blog = _blogs[indexPath.row];
    cell.showTopSeparator = ( indexPath.row == 0 ) ? YES : NO;
    cell.title = [self cellTitleForBlog:blog];
    cell.blavatarUrl = [blog blavatarUrl];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Blog *blog = _blogs[indexPath.row];
    return [AddUsersBlogCell rowHeightWithText:[self cellTitleForBlog:blog]];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Blog *blog = _blogs[indexPath.row];
	[self.delegate userDidSelectBlog:blog];
	
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
