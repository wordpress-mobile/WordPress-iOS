#import "WPAddPostCategoryViewController.h"
#import "Blog.h"
#import "Post.h"
#import "PostCategory.h"
#import "PostCategoriesViewController.h"
#import "Constants.h"
#import "EditSiteViewController.h"
#import "WordPressAppDelegate.h"
#import "PostCategoryService.h"
#import "ContextManager.h"
#import "BlogService.h"

@interface WPAddPostCategoryViewController ()<PostCategoriesViewControllerDelegate>

@property (nonatomic, strong) PostCategory *parentCategory;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) UITextField *createCatNameField;
@property (nonatomic, strong) UITextField *parentCatNameField;
@property (nonatomic, strong) UIBarButtonItem *saveButtonItem;

@end

@implementation WPAddPostCategoryViewController

- (instancetype)initWithPost:(Post *)post
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.post = post;
    }
    return self;
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Add Category", @"The title on the add category screen");
    self.tableView.sectionFooterHeight = 0.0f;

    self.saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).")
                                                           style:[WPStyleGuide barButtonStyleForDone]
                                                          target:self
                                                          action:@selector(saveAddCategory:)];
    self.navigationItem.rightBarButtonItem = self.saveButtonItem;

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

#pragma mark -
#pragma mark Instance Methods

- (void)clearUI
{
    self.createCatNameField.text = @"";
    self.parentCatNameField.text = @"";
}

- (void)addProgressIndicator
{
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    [activityView startAnimating];

    self.navigationItem.rightBarButtonItem = activityButtonItem;
}

- (void)removeProgressIndicator
{
    self.navigationItem.rightBarButtonItem = self.saveButtonItem;
}

- (void)dismiss
{
    DDLogMethod();
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveAddCategory:(id)sender
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:context];
    NSString *catName = [self.createCatNameField.text trim];

    if (!catName ||[catName length] == 0) {
        NSString *title = NSLocalizedString(@"Category title missing.", @"Error popup title to indicate that there was no category title filled in.");
        NSString *message = NSLocalizedString(@"Title for a category is mandatory.", @"Error popup message to indicate that there was no category title filled in.");
        [WPError showAlertWithTitle:title message:message withSupportButton:NO];
        self.createCatNameField.text = @""; // To clear whitespace that was trimed.

        return;
    }

    PostCategory *category = [categoryService findWithBlogObjectID:self.post.blog.objectID parentID:self.parentCategory.categoryID andName:catName];
    if (category) {
        // If there's an existing category with that name and parent, let's use that
        [self dismissWithCategory:category];
        return;
    }

    [self addProgressIndicator];

    [categoryService createCategoryWithName:catName
                     parentCategoryObjectID:self.parentCategory.objectID
                            forBlogObjectID:self.post.blog.objectID
                                    success:^(PostCategory *category) {
                                        [self removeProgressIndicator];
                                        [self dismissWithCategory:category];
                                    } failure:^(NSError *error) {
                                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                        [self removeProgressIndicator];

                                        if ([error code] == 403) {
                                            [WPError showAlertWithTitle:NSLocalizedString(@"Couldn't Connect", @"") message:NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"") withSupportButton:NO];

                                            // bad login/pass combination
                                            EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.post.blog];
                                            [self.navigationController pushViewController:editSiteViewController animated:YES];

                                        } else {
                                            [WPError showXMLRPCErrorAlert:error];
                                        }
                                    }];
}

- (void)dismissWithCategory:(PostCategory *)category
{
    // Add the newly created category to the post
    [self.post.categories addObject:category];
    [self.post save];

    // Cleanup and dismiss
    [self clearUI];
    [self dismiss];
}

#pragma mark - functional methods

- (void)showParentCategorySelector
{
    PostCategoriesViewController *controller = [[PostCategoriesViewController alloc] initWithPost:self.post selectionMode:CategoriesSelectionModeParent];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - tableviewDelegates/datasources

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
    WPTableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [self cellForNewCategory];
    } else {
        cell = [self cellForParentCategory];
    }
    return cell;
}

- (WPTableViewCell *)cellForNewCategory
{
    WPTableViewCell *cell;

    static NSString *newCategoryCellIdentifier = @"newCategoryCellIdentifier";
    cell = (WPTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:newCategoryCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newCategoryCellIdentifier];
        self.createCatNameField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.createCatNameField.borderStyle = UITextBorderStyleNone;
        self.createCatNameField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.createCatNameField.font = [WPStyleGuide regularTextFont];
        self.createCatNameField.placeholder = NSLocalizedString(@"Title", @"Title of the new Category being created.");
    }

    CGRect frame = self.createCatNameField.frame;
    frame.origin.x = 15.0f;
    frame.size.width = cell.contentView.frame.size.width - 30.0f;
    frame.size.height = cell.contentView.frame.size.height;
    self.createCatNameField.frame = frame;
    [cell.contentView addSubview:self.createCatNameField];

    return cell;
}

- (WPTableViewCell *)cellForParentCategory
{
    WPTableViewCell *cell;
    static NSString *parentCategoryCellIdentifier = @"parentCategoryCellIdentifier";
    cell = (WPTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:parentCategoryCellIdentifier];
    if (!cell) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:parentCategoryCellIdentifier];
        cell.textLabel.font = [WPStyleGuide tableviewTextFont];
        cell.textLabel.textColor = [WPStyleGuide whisperGrey];
        cell.textLabel.text = NSLocalizedString(@"Parent Category", @"Placeholder to set a parent category for a new category.");

        cell.detailTextLabel.font = [WPStyleGuide tableviewTextFont];
    }
    NSString *parentCategoryName;
    if (self.parentCategory == nil ) {
        parentCategoryName = NSLocalizedString(@"Optional", @"Placeholder to indicate that filling out the field is optional.");
        cell.detailTextLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
    } else {
        parentCategoryName = self.parentCategory.categoryName;
        cell.detailTextLabel.textColor = [WPStyleGuide whisperGrey];
    }
    cell.detailTextLabel.text = parentCategoryName;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (indexPath.section == 1) {
        [self showParentCategorySelector];
    }
}

#pragma mark textfied deletage

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - PostCategoriesViewControllerDelegate methods

- (void)postCategoriesViewController:(PostCategoriesViewController *)controller didSelectCategory:(PostCategory *)category
{
    self.parentCategory = category;
    [self.tableView reloadData];
}

@end
