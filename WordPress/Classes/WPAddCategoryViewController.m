#import "WPAddCategoryViewController.h"
#import "EditSiteViewController.h"
#import "WordPressAppDelegate.h"
#import "WPSegmentedSelectionTableViewController.h"
#import "Category.h"
#import "Blog.h"
#import "Constants.h"

static void *const kParentCategoriesContext = ((void *)999);

NSString *const NewCategoryCreatedAndUpdatedInBlogNotification = @"NewCategoryCreatedAndUpdatedInBlogNotification";

@interface WPAddCategoryViewController ()

@property (nonatomic, strong) Category *parentCategory;
@property (nonatomic, strong) Blog *blog;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *createCatNameField;
@property (nonatomic, weak) IBOutlet UITextField *parentCatNameField;
@property (nonatomic, weak) IBOutlet UILabel *parentCatNameLabel;
@property (nonatomic, weak) IBOutlet UITableViewCell *createCatNameCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *parentCatNameCell;
@property (nonatomic, strong) UIBarButtonItem *saveButtonItem;
@property (nonatomic, strong) UIBarButtonItem *cancelButtonItem;

@end

@implementation WPAddCategoryViewController

- (id)initWithBlog:(Blog *)blog {
    self = [super init];
    if (self) {
        _blog = blog;
    }
    return self;
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super viewDidLoad];
    self.tableView.sectionFooterHeight = 0.0;

    self.saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save button label (saving content, ex: Post, Page, Comment, Category).") style:[WPStyleGuide barButtonStyleForDone] target:self action:@selector(saveAddCategory:)];
    self.navigationItem.rightBarButtonItem = self.saveButtonItem;

    self.createCatNameField.font = [UIFont fontWithName:@"OpenSans" size:17];
    self.parentCatNameLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
    self.parentCatNameLabel.textColor = [WPStyleGuide whisperGrey];
    self.parentCatNameField.font = [WPStyleGuide tableviewTextFont];
    self.parentCatNameField.textColor = [WPStyleGuide whisperGrey];
    self.parentCatNameLabel.text = NSLocalizedString(@"Parent Category", @"Placeholder to set a parent category for a new category.");
    self.parentCatNameField.placeholder = NSLocalizedString(@"Optional", @"Placeholder to indicate that filling out the field is optional.");
    self.createCatNameField.placeholder = NSLocalizedString(@"Title", @"Title of the new Category being created.");
    
    self.cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:[WPStyleGuide barButtonStyleForDone] target:self action:@selector(cancelAddCategory:)];

    self.parentCategory = nil;
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = NSLocalizedString(@"Add Category", @"Button to add category.");
	// only show "cancel" button if we're presented in a modal view controller
	// that is, if we are the root item of a UINavigationController
	if ([self.parentViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController *parent = (UINavigationController *)self.parentViewController;
		if ([[parent viewControllers] objectAtIndex:0] == self) {
			self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
        } else {
            if (IS_IPAD) {
                if ([[parent viewControllers] objectAtIndex:1] == self)
                    self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
            } else {
                if ([[parent viewControllers] objectAtIndex:0] == self) {
                    self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
                }
            }

        }
	}
    
}

- (void)didReceiveMemoryWarning {
    DDLogWarn(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


#pragma mark -
#pragma mark Instance Methods

- (void)clearUI {
    self.createCatNameField.text = @"";
    self.parentCatNameField.text = @"";
}

- (void)addProgressIndicator {
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
	activityButtonItem.title = @"foobar!";
    [aiv startAnimating];
    
    self.navigationItem.rightBarButtonItem = activityButtonItem;
}

- (void)removeProgressIndicator {
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;
}

- (void)dismiss {
    DDLogMethod();
    if (IS_IPAD) {
        [(WPSelectionTableViewController *)self.parentViewController popViewControllerAnimated:YES];
    } else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)cancelAddCategory:(id)sender {
    [self clearUI];
    [self dismiss];
}

- (void)saveAddCategory:(id)sender {
    NSString *catName = self.createCatNameField.text;
    
    if (!catName ||[catName length] == 0) {
        NSString *title = NSLocalizedString(@"Category title missing.", @"Error popup title to indicate that there was no category title filled in.");
        NSString *message = NSLocalizedString(@"Title for a category is mandatory.", @"Error popup message to indicate that there was no category title filled in.");
        [WPError showAlertWithTitle:title message:message withSupportButton:NO];

        return;
    }
    
    if ([Category existsName:catName forBlog:self.blog withParentId:self.parentCategory.categoryID]) {
        NSString *title = NSLocalizedString(@"Category name already exists.", @"Error popup title to show that a category already exists.");
        NSString *message = NSLocalizedString(@"There is another category with that name.", @"Error popup message to show that a category already exists.");
        [WPError showAlertWithTitle:title message:message withSupportButton:NO];
        return;
    }
    
    [self addProgressIndicator];
    
    [Category createCategory:catName parent:self.parentCategory forBlog:self.blog success:^(Category *category) {
        //re-syncs categories this is necessary because the server can change the name of the category!!!
		[self.blog syncCategoriesWithSuccess:nil failure:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NewCategoryCreatedAndUpdatedInBlogNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:category forKey:@"category"]];
        [self clearUI];
        [self removeProgressIndicator];
        [self dismiss];
    } failure:^(NSError *error) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self removeProgressIndicator];
		
		if ([error code] == 403) {
            [WPError showAlertWithTitle:NSLocalizedString(@"Couldn't Connect", @"") message:NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"") withSupportButton:NO];
			
			// bad login/pass combination
			EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.blog];
			[self.navigationController pushViewController:editSiteViewController animated:YES];
			
		} else {
			[WPError showXMLRPCErrorAlert:error];
		}
    }];
}


#pragma mark - functional methods

- (void)selectionTableViewController:(WPSelectionTableViewController *)selctionController completedSelectionsWithContext:(void *)selContext selectedObjects:(NSArray *)selectedObjects haveChanges:(BOOL)isChanged {
    if (!isChanged) {
        [selctionController clean];
        return;
    }

    if (selContext == kParentCategoriesContext) {
        Category *curCat = [selectedObjects lastObject];

        if (self.parentCategory) {
            self.parentCategory = nil;
        }

        if (curCat) {
            self.parentCategory = curCat;
            self.parentCatNameField.text = curCat.categoryName;
            [self.tableView reloadData];
        }

    }

    [selctionController clean];
}


- (void)populateSelectionsControllerWithCategories {
    WPSegmentedSelectionTableViewController *selectionTableViewController = [[WPSegmentedSelectionTableViewController alloc] init];

    NSArray *selObjs = ((self.parentCategory == nil) ? [NSArray array] : [NSArray arrayWithObject:self.parentCategory]);
    
	NSArray *cats = [self.blog sortedCategories];
	
	[selectionTableViewController populateDataSource:cats
     havingContext:kParentCategoriesContext
     selectedObjects:selObjs
     selectionType:kRadio
     andDelegate:self];

    selectionTableViewController.title = NSLocalizedString(@"Parent Category", @"");

    [self.navigationController pushViewController:selectionTableViewController animated:YES];
}

#pragma mark - tableviewDelegates/datasources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return self.createCatNameCell;
    } else {
        return self.parentCatNameCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];

    if (indexPath.section == 1) {
        [self populateSelectionsControllerWithCategories];
    }
}

#pragma mark textfied deletage

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
