#import "BlogSelectorViewController.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"
#import "BlogDetailsViewController.h"
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"

static NSString *const BlogCellIdentifier = @"BlogCell";

@interface BlogSelectorViewController ()

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL sectionDeletedByController;

@property (nonatomic, strong) NSManagedObjectID *selectedObjectID;
@property (nonatomic, copy) void (^selectedCompletionHandler)(NSManagedObjectID *selectedObjectID);
@property (nonatomic, copy) void (^cancelCompletionHandler)(void);

@end

@implementation BlogSelectorViewController

- (id)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                selectedCompletion:(void (^)(NSManagedObjectID *))selected
                  cancelCompletion:(void (^)())cancel
{
    self = [super initWithStyle:UITableViewStyleGrouped];

    if (self) {
        _selectedObjectID = objectID;
        _selectedCompletionHandler = selected;
        _cancelCompletionHandler = cancel;
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPressComAccountChanged:)
                                                 name:WPAccountDefaultWordPressComAccountChangedNotification
                                               object:nil];

    if (IS_IPHONE) {
        // Remove one-pixel gap resulting from a top-aligned grouped table view
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;

        // Cancel button
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelButtonTapped:)];

        self.navigationItem.leftBarButtonItem = cancelButtonItem;
    }

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    [self.tableView reloadData];

    // Scroll the currently selected object into view.
    NSManagedObject *obj = [self.resultsController.managedObjectContext objectWithID:self.selectedObjectID];
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:obj];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.resultsController.delegate = nil;
}

- (NSUInteger)numSites
{
    return [[self.resultsController fetchedObjects] count];
}

- (BOOL)hasDotComAndSelfHosted
{
    return ([[self.resultsController sections] count] > 1);
}

#pragma mark - Notifications

- (void)wordPressComAccountChanged:(NSNotification *)note
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Actions

- (IBAction)cancelButtonTapped:(id)sender
{
    if (self.cancelCompletionHandler) {
        self.cancelCompletionHandler();
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.resultsController sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo;
    NSInteger numberOfRows = 0;
    if ([self.resultsController sections].count > section) {
        sectionInfo = [[self.resultsController sections] objectAtIndex:section];
        numberOfRows = sectionInfo.numberOfObjects;
    }

    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:BlogCellIdentifier];

    [WPStyleGuide configureTableViewSmallSubtitleCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;

    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    if ([blog.blogName length] != 0) {
        cell.textLabel.text = blog.blogName;
        cell.detailTextLabel.text = blog.url;
    } else {
        cell.textLabel.text = blog.url;
    }

    [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl];

    cell.accessoryType = blog.objectID == self.selectedObjectID ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSIndexPath *previousIndexPath;
    if (self.selectedObjectID) {
        for (Blog *blog in self.resultsController.fetchedObjects) {
            if (blog.objectID == self.selectedObjectID) {
                previousIndexPath = [self.resultsController indexPathForObject:blog];
                break;
            }
        }

        if ([previousIndexPath compare:indexPath] == NSOrderedSame) {
            // User tapped the already selected item. Treat this as a cancel event
            // so the picker can be dismissed without changes.
            [self cancelButtonTapped:nil];
            return;
        }
    }

    Blog *selectedBlog = [self.resultsController objectAtIndexPath:indexPath];
    self.selectedObjectID = selectedBlog.objectID;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    if (previousIndexPath) {
        [tableView reloadRowsAtIndexPaths:@[previousIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

    // Fire off the selection after a short delay to let animations complete for selection/deselection
    if (self.selectedCompletionHandler) {
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.selectedCompletionHandler(self.selectedObjectID);
        });
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController
{
    if (_resultsController) {
        return _resultsController;
    }

    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"account.isWpcom" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    [fetchRequest setPredicate:[self fetchRequestPredicate]];

    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:nil
                          cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    return _resultsController;
}

- (NSPredicate *)fetchRequestPredicate
{
    return [NSPredicate predicateWithFormat:@"visible = YES"];
}

@end
